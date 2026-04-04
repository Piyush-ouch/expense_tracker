import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/parsed_transaction.dart';
import '../models/expense_model.dart';
import '../models/income_model.dart';
import 'firestore_service.dart';
import 'package:intl/intl.dart';

class TransactionSyncService {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sync parsed transactions to Firebase
  Future<Map<String, int>> syncTransactions(
    String uid,
    List<ParsedTransaction> transactions,
  ) async {
    int addedCount = 0;
    int skippedCount = 0;

    for (var transaction in transactions) {
      try {
        // Check for duplicates
        final isDuplicate = await _isDuplicate(uid, transaction);
        
        if (isDuplicate) {
          skippedCount++;
          continue;
        }

        // Add to Firebase
        if (transaction.type == TransactionType.debit) {
          await _addExpense(uid, transaction);
        } else {
          await _addIncome(uid, transaction);
        }

        addedCount++;
      } catch (e) {
        // Skip transactions that fail
        skippedCount++;
        continue;
      }
    }

    return {
      'added': addedCount,
      'skipped': skippedCount,
      'total': transactions.length,
    };
  }

  // Check if transaction already exists (duplicate detection)
  Future<bool> _isDuplicate(String uid, ParsedTransaction transaction) async {
    try {
      // Check in expenses
      if (transaction.type == TransactionType.debit) {
        final expensesSnapshot = await _firestore
            .collection('users')
            .doc(uid)
            .collection('expenses')
            .where('amount', isEqualTo: (transaction.amount * 100).round())
            .where('date', isEqualTo: Timestamp.fromDate(transaction.date))
            .get();

        if (expensesSnapshot.docs.isNotEmpty) {
          // Check if any match the merchant/description
          for (var doc in expensesSnapshot.docs) {
            final data = doc.data();
            final description = data['description'] ?? '';
            if (description.contains(transaction.merchant ?? '')) {
              return true;
            }
          }
        }
      } else {
        // Check in incomes
        final incomesSnapshot = await _firestore
            .collection('users')
            .doc(uid)
            .collection('incomes')
            .where('amount', isEqualTo: (transaction.amount * 100).round())
            .where('date', isEqualTo: Timestamp.fromDate(transaction.date))
            .get();

        if (incomesSnapshot.docs.isNotEmpty) {
          return true;
        }
      }

      return false;
    } catch (e) {
      // If error checking, assume not duplicate to be safe
      return false;
    }
  }

  // Add expense from parsed transaction
  Future<void> _addExpense(String uid, ParsedTransaction transaction) async {
    final expense = ExpenseModel(
      amount: (transaction.amount * 100).round(),
      baseAmount: (transaction.amount * 100).round(),
      originalCurrency: 'INR',
      category: transaction.category ?? 'Other',
      description: transaction.merchant ?? 'SMS Auto-sync',
      date: transaction.date,
      createdAt: DateTime.now(),
    );

    await _firestoreService.addExpense(uid, expense);
  }

  // Add income from parsed transaction
  Future<void> _addIncome(String uid, ParsedTransaction transaction) async {
    final income = IncomeModel(
      amount: (transaction.amount * 100).round(),
      baseAmount: (transaction.amount * 100).round(),
      originalCurrency: 'INR',
      source: transaction.merchant ?? 'UPI Payment',
      date: transaction.date,
      createdAt: DateTime.now(),
    );

    await _firestoreService.addIncome(uid, income);
  }

  // Get transactions grouped by month
  Map<String, List<ParsedTransaction>> groupByMonth(List<ParsedTransaction> transactions) {
    final Map<String, List<ParsedTransaction>> grouped = {};

    for (var transaction in transactions) {
      final monthKey = DateFormat('MMM yyyy').format(transaction.date);
      
      if (!grouped.containsKey(monthKey)) {
        grouped[monthKey] = [];
      }
      
      grouped[monthKey]!.add(transaction);
    }

    return grouped;
  }

  // Get summary statistics
  Map<String, dynamic> getSummary(List<ParsedTransaction> transactions) {
    double totalDebits = 0;
    double totalCredits = 0;
    int debitCount = 0;
    int creditCount = 0;

    for (var transaction in transactions) {
      if (transaction.type == TransactionType.debit) {
        totalDebits += transaction.amount;
        debitCount++;
      } else {
        totalCredits += transaction.amount;
        creditCount++;
      }
    }

    return {
      'totalDebits': totalDebits,
      'totalCredits': totalCredits,
      'debitCount': debitCount,
      'creditCount': creditCount,
      'totalTransactions': transactions.length,
    };
  }

  // Remove junk transactions (promotional/recharge)
  Future<int> removeJunkTransactions(String uid) async {
    int deletedCount = 0;
    final promoKeywords = [
      "recharge now", "plan", "offer", "benefits", "validity", 
      "data", "quota", "expired", "click", "link", "http", "www",
      "otp", "code", "verification", "login", "win", "lucky"
    ];

    try {
      // 1. Scan Expenses
      final expensesSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .get();

      for (var doc in expensesSnapshot.docs) {
        final data = doc.data();
        final description = (data['description'] as String? ?? '').toLowerCase();
        
        if (promoKeywords.any((k) => description.contains(k))) {
          await doc.reference.delete();
          deletedCount++;
        }
      }

      // 2. Scan Incomes (less likely, but good to check source)
      final incomesSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('incomes')
          .get();

      for (var doc in incomesSnapshot.docs) {
        final data = doc.data();
        final source = (data['source'] as String? ?? '').toLowerCase();
        
        if (promoKeywords.any((k) => source.contains(k))) {
          await doc.reference.delete();
          deletedCount++;
        }
      }
    } catch (e) {
      print("Error removing junk transactions: $e");
    }

    return deletedCount;
  }
}
