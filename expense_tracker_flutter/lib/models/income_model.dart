import 'package:cloud_firestore/cloud_firestore.dart';

class IncomeModel {
  final String? id;
  final int amount; // Stored as cents
  final int baseAmount; // Stored as cents in base currency
  final String originalCurrency;
  final String source;
  final DateTime date;
  final DateTime createdAt;

  IncomeModel({
    this.id,
    required this.amount,
    required this.baseAmount,
    required this.originalCurrency,
    required this.source,
    required this.date,
    required this.createdAt,
  });

  factory IncomeModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return IncomeModel(
      id: doc.id,
      amount: data['amount'] ?? 0,
      baseAmount: data['base_amount'] ?? 0,
      originalCurrency: data['original_currency'] ?? 'USD',
      source: data['source'] ?? 'Other',
      date: (data['date'] as Timestamp).toDate(),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'base_amount': baseAmount,
      'original_currency': originalCurrency,
      'source': source,
      'date': Timestamp.fromDate(date),
      'created_at': FieldValue.serverTimestamp(),
      'type': 'income',
    };
  }

  // Helper to get amount in dollars/rupees
  double get displayAmount => amount / 100.0;
  double get displayBaseAmount => baseAmount / 100.0;
}
