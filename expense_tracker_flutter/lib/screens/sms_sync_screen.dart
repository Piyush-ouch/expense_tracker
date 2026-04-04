import 'package:flutter/material.dart';
// import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import '../services/sms_parser_service.dart';
import '../services/transaction_sync_service.dart';
import '../services/auth_service.dart';
import '../models/parsed_transaction.dart';
import '../utils/theme.dart';
import '../widgets/glowing_loader.dart';
import 'package:intl/intl.dart';

class SmsSyncScreen extends StatefulWidget {
  const SmsSyncScreen({super.key});

  @override
  State<SmsSyncScreen> createState() => _SmsSyncScreenState();
}

class _SmsSyncScreenState extends State<SmsSyncScreen> {
  final SmsParserService _smsParser = SmsParserService();
  final TransactionSyncService _syncService = TransactionSyncService();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _hasPermission = false;
  List<ParsedTransaction> _parsedTransactions = [];
  Map<String, int>? _syncResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final hasPermission = await _smsParser.hasSmsPermission();
    setState(() {
      _hasPermission = hasPermission;
    });
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final granted = await _smsParser.requestSmsPermission();
      setState(() {
        _hasPermission = granted;
        _isLoading = false;
      });

      if (!granted) {
        setState(() {
          _errorMessage = 'SMS permission is required to sync transactions';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error requesting permission: $e';
      });
    }
  }

  Future<void> _scanSms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _parsedTransactions = [];
    });

    try {
      // Get SMS from last 3 months
      final now = DateTime.now();
      final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);

      final parsed = await _smsParser.getSmsInRange(threeMonthsAgo, now);

      setState(() {
        _parsedTransactions = parsed;
        _isLoading = false;
      });

      if (parsed.isEmpty) {
        setState(() {
          _errorMessage = 'No UPI transactions found in SMS';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error scanning SMS: $e';
      });
    }
  }

  Future<void> _syncToFirebase() async {
    final user = _authService.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'User not logged in';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _syncService.syncTransactions(user.uid, _parsedTransactions);
      
      setState(() {
        _syncResult = result;
        _isLoading = false;
      });

      // Show success dialog
      if (mounted) {
        _showSuccessDialog(result);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error syncing transactions: $e';
      });
    }
  }

  void _showSuccessDialog(Map<String, int> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text(
          'Sync Complete!',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '✅ Added: ${result['added']} transactions',
              style: const TextStyle(color: AppTheme.accentColor, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '⏭️ Skipped: ${result['skipped']} (duplicates)',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              '📊 Total found: ${result['total']}',
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to dashboard
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'Sync from SMS',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: GlowingCircularLoader())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_hasPermission) {
      return _buildPermissionRequest();
    }

    if (_parsedTransactions.isEmpty && _syncResult == null) {
      return _buildScanPrompt();
    }

    if (_parsedTransactions.isNotEmpty) {
      return _buildTransactionsList();
    }

    return const Center(child: Text('No data'));
  }

  Widget _buildPermissionRequest() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.sms,
              size: 80,
              color: AppTheme.accentColor,
            ),
            const SizedBox(height: 24),
            const Text(
              'SMS Permission Required',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'To automatically track your UPI transactions, we need permission to read your SMS messages.\n\nWe only read banking/UPI messages and never share your data.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _requestPermission,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(
                'Grant Permission',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScanPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search,
              size: 80,
              color: AppTheme.accentColor,
            ),
            const SizedBox(height: 24),
            const Text(
              'Scan SMS for Transactions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'We\'ll scan your SMS from the last 3 months for UPI transactions and automatically categorize them.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _scanSms,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(
                'Scan SMS',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    final summary = _syncService.getSummary(_parsedTransactions);
    final grouped = _syncService.groupByMonth(_parsedTransactions);

    return Column(
      children: [
        // Summary card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                'Found ${summary['totalTransactions']} Transactions',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text(
                        'Expenses',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${summary['debitCount']}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text(
                        'Income',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${summary['creditCount']}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _syncToFirebase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text(
                  'Sync to App',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),

        // Transactions list
        Expanded(
          child: ListView.builder(
            itemCount: _parsedTransactions.length,
            itemBuilder: (context, index) {
              final transaction = _parsedTransactions[index];
              return _buildTransactionItem(transaction);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(ParsedTransaction transaction) {
    final isExpense = transaction.type == TransactionType.debit;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isExpense ? Icons.arrow_upward : Icons.arrow_downward,
            color: isExpense ? const Color(0xFFEF4444) : AppTheme.accentColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.merchant ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${transaction.category} • ${DateFormat('dd MMM yyyy').format(transaction.date)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${transaction.amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isExpense ? const Color(0xFFEF4444) : AppTheme.accentColor,
            ),
          ),
        ],
      ),
    );
  }
}
