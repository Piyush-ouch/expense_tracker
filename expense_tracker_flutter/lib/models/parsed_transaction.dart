enum TransactionType {
  debit,
  credit,
}

class ParsedTransaction {
  final String smsBody;
  final DateTime date;
  final double amount;
  final TransactionType type;
  final String? merchant;
  final String? category;
  final String sender;
  final String? upiId;

  ParsedTransaction({
    required this.smsBody,
    required this.date,
    required this.amount,
    required this.type,
    this.merchant,
    this.category,
    required this.sender,
    this.upiId,
  });

  @override
  String toString() {
    return 'ParsedTransaction(type: $type, amount: $amount, merchant: $merchant, date: $date)';
  }
}
