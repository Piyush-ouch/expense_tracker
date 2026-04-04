import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_model.dart';
import '../models/income_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add expense
  Future<void> addExpense(String uid, ExpenseModel expense) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .add(expense.toMap());
  }

  // Add income
  Future<void> addIncome(String uid, IncomeModel income) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('incomes')
        .add(income.toMap());
  }

  // Get expenses for a date range
  Stream<List<ExpenseModel>> getExpenses(
    String uid,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExpenseModel.fromFirestore(doc))
            .toList());
  }

  // Get incomes for a date range
  Stream<List<IncomeModel>> getIncomes(
    String uid,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('incomes')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => IncomeModel.fromFirestore(doc))
            .toList());
  }

  // Delete expense
  Future<void> deleteExpense(String uid, String expenseId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .doc(expenseId)
        .delete();
  }

  // Delete income
  Future<void> deleteIncome(String uid, String incomeId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('incomes')
        .doc(incomeId)
        .delete();
  }

  // Get chart data for expenses
  Future<Map<String, double>> getExpenseChartData(
    String uid,
    DateTime startDate,
    DateTime endDate,
  ) async {
    QuerySnapshot snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    Map<String, double> chartData = {};
    for (var doc in snapshot.docs) {
      ExpenseModel expense = ExpenseModel.fromFirestore(doc);
      chartData[expense.category] =
          (chartData[expense.category] ?? 0) + expense.displayBaseAmount;
    }

    return chartData;
  }

  // Get chart data for incomes
  Future<Map<String, double>> getIncomeChartData(
    String uid,
    DateTime startDate,
    DateTime endDate,
  ) async {
    QuerySnapshot snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('incomes')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    Map<String, double> chartData = {};
    for (var doc in snapshot.docs) {
      IncomeModel income = IncomeModel.fromFirestore(doc);
      chartData[income.source] =
          (chartData[income.source] ?? 0) + income.displayBaseAmount;
    }

    return chartData;
  }

  // Get lifetime statistics
  Future<Map<String, double>> getLifetimeStats(String uid) async {
    // Get all expenses
    QuerySnapshot expensesSnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .get();

    double totalExpenses = 0;
    for (var doc in expensesSnapshot.docs) {
      ExpenseModel expense = ExpenseModel.fromFirestore(doc);
      totalExpenses += expense.displayBaseAmount;
    }

    // Get all incomes
    QuerySnapshot incomesSnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('incomes')
        .get();

    double totalIncome = 0;
    for (var doc in incomesSnapshot.docs) {
      IncomeModel income = IncomeModel.fromFirestore(doc);
      totalIncome += income.displayBaseAmount;
    }

    return {
      'income': totalIncome,
      'expense': totalExpenses,
    };
  }
}
