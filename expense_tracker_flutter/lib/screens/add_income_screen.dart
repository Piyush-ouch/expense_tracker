import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/income_model.dart';
import '../utils/theme.dart';

class AddIncomeScreen extends StatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  
  String? _selectedSource;
  String _currentAmount = '0';
  String _note = '';
  DateTime _selectedDate = DateTime.now();
  
  final List<Map<String, dynamic>> _incomeSources = [
    {'name': 'Salary', 'icon': Icons.work},
    {'name': 'Freelance', 'icon': Icons.laptop_mac},
    {'name': 'Investment', 'icon': Icons.trending_up},
    {'name': 'Gift', 'icon': Icons.card_giftcard},
    {'name': 'Other', 'icon': Icons.attach_money},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildSourceGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF333333))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          const Text(
            'Add Income',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _resetForm,
          ),
        ],
      ),
    );
  }

  Widget _buildSourceGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 0.85,
      ),
      itemCount: _incomeSources.length,
      itemBuilder: (context, index) {
        final source = _incomeSources[index];
        return _buildSourceItem(source['name'], source['icon']);
      },
    );
  }

  Widget _buildSourceItem(String name, IconData icon) {
    final isSelected = _selectedSource == name;
    
    return GestureDetector(
      onTap: () => _selectSource(name),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFfdd835) : const Color(0xFF3a3a3a),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.black : Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFcccccc),
              fontSize: 11,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _selectSource(String source) {
    setState(() {
      _selectedSource = source;
    });
    _showKeypadModal();
  }

  void _showKeypadModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildKeypadModal(),
    );
  }

  Widget _buildKeypadModal() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1a1a1a),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Amount display
              Container(
                padding: const EdgeInsets.all(20),
                alignment: Alignment.centerRight,
                child: Text(
                  _currentAmount,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              // Note input
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFF333333)),
                    bottom: BorderSide(color: Color(0xFF333333)),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Note :',
                      style: TextStyle(color: Color(0xFF666666)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Enter a note...',
                          hintStyle: TextStyle(color: Color(0xFF666666)),
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          _note = value;
                        },
                      ),
                    ),
                    const Icon(Icons.camera_alt, color: Color(0xFF999999)),
                  ],
                ),
              ),

              // Calculator keypad
              Container(
                color: const Color(0xFF0a0a0a),
                padding: const EdgeInsets.all(2),
                child: Column(
                  children: [
                    _buildKeypadRow([
                      _buildKey('7', setModalState),
                      _buildKey('8', setModalState),
                      _buildKey('9', setModalState),
                      _buildTodayKey(setModalState),
                    ]),
                    _buildKeypadRow([
                      _buildKey('4', setModalState),
                      _buildKey('5', setModalState),
                      _buildKey('6', setModalState),
                      _buildKey('+', setModalState),
                    ]),
                    _buildKeypadRow([
                      _buildKey('1', setModalState),
                      _buildKey('2', setModalState),
                      _buildKey('3', setModalState),
                      _buildKey('-', setModalState),
                    ]),
                    _buildKeypadRow([
                      _buildKey('.', setModalState),
                      _buildKey('0', setModalState),
                      _buildBackspaceKey(setModalState),
                      _buildConfirmKey(),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKeypadRow(List<Widget> keys) {
    return Row(
      children: keys.map((key) => Expanded(child: key)).toList(),
    );
  }

  Widget _buildKey(String label, StateSetter setModalState) {
    return GestureDetector(
      onTap: () {
        setModalState(() {
          setState(() {
            if (label == '+' || label == '-') {
              _currentAmount += label;
            } else if (_currentAmount == '0') {
              _currentAmount = label;
            } else {
              _currentAmount += label;
            }
          });
        });
      },
      child: Container(
        height: 60,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2a2a2a), Color(0xFF1f1f1f)],
          ),
          border: Border.all(color: const Color(0xFF333333)),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodayKey(StateSetter setModalState) {
    return GestureDetector(
      onTap: () {
        setModalState(() {
          setState(() {
            _selectedDate = DateTime.now();
          });
        });
      },
      child: Container(
        height: 60,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3a3a3a), Color(0xFF2a2a2a)],
          ),
          border: Border.all(color: const Color(0xFF333333)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.calendar_today, color: Color(0xFFfdd835), size: 18),
            SizedBox(height: 2),
            Text(
              'Today',
              style: TextStyle(color: Colors.white, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackspaceKey(StateSetter setModalState) {
    return GestureDetector(
      onTap: () {
        setModalState(() {
          setState(() {
            if (_currentAmount.length > 1) {
              _currentAmount = _currentAmount.substring(0, _currentAmount.length - 1);
            } else {
              _currentAmount = '0';
            }
          });
        });
      },
      child: Container(
        height: 60,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2a2a2a), Color(0xFF1f1f1f)],
          ),
          border: Border.all(color: const Color(0xFF333333)),
        ),
        child: const Center(
          child: Icon(Icons.backspace, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildConfirmKey() {
    return GestureDetector(
      onTap: _saveIncome,
      child: Container(
        height: 60,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4a4a4a), Color(0xFF3a3a3a)],
          ),
          border: Border.all(color: const Color(0xFF333333)),
        ),
        child: const Center(
          child: Icon(Icons.check, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _selectedSource = null;
      _currentAmount = '0';
      _note = '';
      _selectedDate = DateTime.now();
    });
  }

  Future<void> _saveIncome() async {
    final user = _authService.currentUser;
    if (user == null) {
      print('DEBUG: No user logged in');
      return;
    }

    // Evaluate expression
    double amount;
    try {
      amount = _evaluateExpression(_currentAmount);
    } catch (e) {
      amount = double.tryParse(_currentAmount) ?? 0;
    }

    print('DEBUG: Saving income - Amount: $amount, Source: $_selectedSource, Date: $_selectedDate');

    if (amount <= 0) {
      print('DEBUG: Invalid amount');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (_selectedSource == null) {
      print('DEBUG: No source selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a source')),
      );
      return;
    }

    try {
      final amountInCents = (amount * 100).round();
      final income = IncomeModel(
        amount: amountInCents,
        baseAmount: amountInCents,
        originalCurrency: 'INR',
        source: _selectedSource!,
        date: _selectedDate,
        createdAt: DateTime.now(),
      );
      
      print('DEBUG: Income model created: ${income.toMap()}');
      await _firestoreService.addIncome(user.uid, income);
      print('DEBUG: Income saved successfully to Firestore');

      if (mounted) {
        Navigator.pop(context); // Close modal
        Navigator.pop(context); // Close add screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Income added successfully!')),
        );
      }
    } catch (e) {
      print('DEBUG: Error saving income: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  double _evaluateExpression(String expression) {
    if (expression.contains('+')) {
      final parts = expression.split('+');
      return parts.fold(0.0, (sum, part) => sum + (double.tryParse(part.trim()) ?? 0));
    } else if (expression.contains('-') && expression.indexOf('-') > 0) {
      final parts = expression.split('-');
      double result = double.tryParse(parts[0].trim()) ?? 0;
      for (int i = 1; i < parts.length; i++) {
        result -= double.tryParse(parts[i].trim()) ?? 0;
      }
      return result;
    }
    return double.tryParse(expression) ?? 0;
  }
}
