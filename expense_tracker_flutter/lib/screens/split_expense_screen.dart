import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../utils/theme.dart';

class SplitExpenseScreen extends StatefulWidget {
  const SplitExpenseScreen({super.key});

  @override
  State<SplitExpenseScreen> createState() => _SplitExpenseScreenState();
}

class _SplitExpenseScreenState extends State<SplitExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickContact() async {
    final status = await FlutterContacts.permissions.request(PermissionType.read);
    if (status == PermissionStatus.granted) {
      String? contactId = await FlutterContacts.native.showPicker();
      if (contactId != null) {
        Contact? contact = await FlutterContacts.get(contactId, properties: {ContactProperty.phone});
        if (contact != null && contact.phones.isNotEmpty) {
          String phoneString = contact.phones.first.number;
          setState(() {
            _phoneController.text = phoneString.replaceAll(RegExp(r'[^\d+]'), '');
          });
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contacts permission denied')),
        );
      }
    }
  }

  Future<void> _sendSplitRequest() async {
    if (_formKey.currentState!.validate()) {
      final amount = _amountController.text;
      final description = _descriptionController.text;
      final phone = _phoneController.text.trim();

      final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');

      // Query Firestore for user matching this phone number
      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('phone_number', isEqualTo: cleanPhone)
            .limit(1)
            .get();

        if (querySnapshot.docs.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User not found. They need to update their phone number in their Profile.')),
            );
          }
          return;
        }

        final targetUid = querySnapshot.docs.first.id;
        final currentUser = FirebaseAuth.instance.currentUser;
        
        if (currentUser == null) return;
        
        if (targetUid == currentUser.uid) {
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You cannot split with yourself.')));
           }
           return;
        }

        await FirebaseFirestore.instance.collection('split_requests').add({
          'from_uid': currentUser.uid,
          'to_uid': targetUid,
          'amount': double.parse(amount),
          'description': description,
          'status': 'pending',
          'created_at': FieldValue.serverTimestamp(),
        });

        // Trigger Flask backend for FCM push notification
        // Use 90s timeout because Render free tier cold-starts in ~30-60s
        try {
          setState(() => _isSending = true);
          
          final url = Uri.parse('${AppConstants.flaskBackendUrl}/api/send_push');
          final response = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'targetUid': targetUid,
              'amount': amount,
              'description': description,
              'senderName': currentUser.displayName ?? 'A friend',
            }),
          ).timeout(const Duration(seconds: 90));
          
          if (response.statusCode == 200) {
             debugPrint("✅ Push notification sent successfully to $targetUid");
          } else if (mounted) {
             debugPrint("❌ Push failed (${response.statusCode}): ${response.body}");
             final errorBody = json.decode(response.body);
             final errorMsg = errorBody['error'] ?? 'Unknown error';
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Push failed: $errorMsg')));
             // Still continue — the Firestore split_request was already created,
             // so the in-app listener will still pick it up.
          }
        } catch (e) {
          debugPrint("Failed to ping Flask backend: $e");
          // Don't return — the split request is already saved in Firestore.
          // The in-app listener will still show the dialog to the friend.
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Push notification failed, but split request was sent in-app.')),
             );
          }
        } finally {
          if (mounted) setState(() => _isSending = false);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Split request sent successfully!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Split Expense'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Split an expense with a friend!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Amount field
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 24),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹ ',
                  prefixStyle: TextStyle(color: AppTheme.textPrimary, fontSize: 24),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Description field
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Description (e.g. Dinner, Movie)',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Phone Number field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Friend\'s Phone Number',
                  hintText: '+1234567890',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.contacts, color: AppTheme.textSecondary),
                    onPressed: _pickContact,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter friend\'s phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // Submit Button
              ElevatedButton(
                onPressed: _isSending ? null : _sendSplitRequest,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSending
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                        SizedBox(width: 12),
                        Text('Sending...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    )
                  : const Text(
                      'Send Split Request in App',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
