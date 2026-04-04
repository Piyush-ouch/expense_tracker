import 'package:flutter/services.dart';
import '../models/parsed_transaction.dart';

class SmsParserService {
  static const platform = MethodChannel('com.example.expense_tracker_flutter/sms');

  // Request SMS permission via Native Channel
  Future<bool> requestSmsPermission() async {
    try {
      final bool granted = await platform.invokeMethod('requestPermission');
      return granted;
    } on PlatformException catch (e) {
      print("Failed to request permission: ${e.message}");
      return false;
    }
  }

  // Check if SMS permission is granted via Native Channel
  Future<bool> hasSmsPermission() async {
    try {
      final bool granted = await platform.invokeMethod('checkPermission');
      return granted;
    } on PlatformException catch (e) {
      print("Failed to check permission: ${e.message}");
      return false;
    }
  }

  // Sync UID to native side for background processing
  Future<void> syncUid(String uid) async {
    try {
      await platform.invokeMethod('saveUid', {'uid': uid});
    } on PlatformException catch (e) {
      print("Failed to sync UID: ${e.message}");
    }
  }

  // Get SMS from specific time range using Native Channel
  Future<List<ParsedTransaction>> getSmsInRange(DateTime startDate, DateTime endDate) async {
    if (!await hasSmsPermission()) {
      throw Exception('SMS permission not granted');
    }

    try {
      final List<dynamic> result = await platform.invokeMethod('getSms', {
        'start': startDate.millisecondsSinceEpoch,
        'end': endDate.millisecondsSinceEpoch,
      });

      return _parseRawMessages(result);
    } on PlatformException catch (e) {
      throw Exception('Failed to read SMS: ${e.message}');
    }
  }

  // Parse raw messages from native channel
  List<ParsedTransaction> _parseRawMessages(List<dynamic> rawMessages) {
    List<ParsedTransaction> transactions = [];

    for (var msg in rawMessages) {
      if (msg is Map) {
        try {
          final parsed = _parseSingleSms(msg);
          if (parsed != null) {
            transactions.add(parsed);
          }
        } catch (e) {
          continue;
        }
      }
    }

    return transactions;
  }

  // ------------------------------ //
  //   1. Master Keyword Database   //
  // ------------------------------ //

  final List<String> _debitKeywords = [
    "debited", "paid", "sent", "deducted", "withdrawn",
    "purchased", "spent", "upi payment", "transfer",
    "imps", "neft", "pos", "autopay", "mandate", "charge"
  ];

  final List<String> _creditKeywords = [
    "credited", "received", "deposited", "refund", "cashback",
    "interest", "neft", "imps", "reward", "reversal"
  ];

  // ------------------------------ //
  //        2. Amount Regex         //
  // ------------------------------ //

  final List<RegExp> _amountPatterns = [
    RegExp(r"rs\.?\s*([\d,]+\.?\d*)", caseSensitive: false),
    RegExp(r"inr\.?\s*([\d,]+\.?\d*)", caseSensitive: false),
    RegExp(r"₹\s*([\d,]+\.?\d*)"),
    RegExp(r"amount\s*([\d,]+\.?\d*)", caseSensitive: false),
    RegExp(r"sum\s*([\d,]+\.?\d*)", caseSensitive: false),
    RegExp(r"paid\s*([\d,]+\.?\d*)", caseSensitive: false),
  ];

  // ------------------------------ //
  //      3. Merchant Extraction    //
  // ------------------------------ //

  final List<RegExp> _merchantPatterns = [
    RegExp(r"to vpa ([\w@._-]+)", caseSensitive: false),
    RegExp(r"by ([a-zA-Z0-9@._-]+)", caseSensitive: false),
    RegExp(r"at ([a-zA-Z\s&]+)", caseSensitive: false),
    RegExp(r"to ([a-zA-Z\s&]+)", caseSensitive: false),
  ];

  // ------------------------------ //
  //       4. Categorization        //
  // ------------------------------ //

  final Map<String, String> _categoryMapping = {
    // Food
    "zomato": "Food & Drinks",
    "swiggy": "Food & Drinks",
    "dominos": "Food & Drinks",
    "kfc": "Food & Drinks",
    "mcd": "Food & Drinks",
    "restaurant": "Food & Drinks",

    // Shopping
    "amazon": "Shopping",
    "flipkart": "Shopping",
    "myntra": "Shopping",
    "meesho": "Shopping",
    "ajio": "Shopping",

    // Travel
    "uber": "Transport",
    "ola": "Transport",
    "rapido": "Transport",
    "irctc": "Transport",
    "makemytrip": "Transport",

    // Entertainment
    "netflix": "Entertainment",
    "youtube": "Entertainment",
    "spotify": "Entertainment",
    "bookmyshow": "Entertainment",

    // Bills
    "jio": "Bills",
    "airtel": "Bills",
    "vi": "Bills",
    "bsnl": "Bills",
    "electricity": "Bills",
    "gas": "Bills",
    "broadband": "Bills",
  };

  // Parse a single SMS message map
  ParsedTransaction? _parseSingleSms(Map<dynamic, dynamic> sms) {
    final body = (sms['body'] as String?) ?? '';
    final sender = (sms['address'] as String?) ?? '';
    final dateMillis = sms['date'] as int?;

    // Use user's parsing logic
    final parsedData = _parseSmsLogic(body);

    if (parsedData['confidence'] < 40) {
      return null; // Skip low confidence messages
    }

    if (parsedData['amount'] == null) {
      return null;
    }

    // Extract date
    final date = dateMillis != null 
        ? DateTime.fromMillisecondsSinceEpoch(dateMillis)
        : DateTime.now();

    return ParsedTransaction(
      smsBody: body,
      date: date,
      amount: parsedData['amount'],
      type: parsedData['type'] == 'debit' ? TransactionType.debit : TransactionType.credit,
      merchant: parsedData['merchant'],
      category: parsedData['category'],
      sender: sender,
      upiId: null, // User logic doesn't explicitly extract UPI ID separately, but merchant might be one
    );
  }

  // ------------------------------ //
  //      6. Main Parsing Engine    //
  // ------------------------------ //

  Map<String, dynamic> _parseSmsLogic(String message) {
    final rawMessage = message;
    message = message.toLowerCase();

    // ---------- STEP 1: Detect transaction type ----------
    
    // 1. Check for Promotional Content (Immediate Rejection)
    if (_isPromotional(message)) {
      return {
        "original": rawMessage,
        "type": "unknown",
        "amount": null,
        "merchant": "Unknown",
        "category": "Other",
        "confidence": 0,
      };
    }

    String type = "unknown";

    bool isDebit = _containsWord(message, _debitKeywords);
    bool isCredit = _containsWord(message, _creditKeywords);

    if (isDebit && !isCredit) type = "debit";
    else if (isCredit && !isDebit) type = "credit";
    else if (isDebit && isCredit) {
      // fallback: priority to credit
      type = "credit";
    }

    // ---------- STEP 2: Extract Amount ----------
    double? amount;
    for (var pattern in _amountPatterns) {
      var match = pattern.firstMatch(message);
      if (match != null) {
        amount = double.tryParse(match.group(1)!.replaceAll(",", ""));
        break;
      }
    }

    // ---------- STEP 3: Extract Merchant ----------
    String merchant = "Unknown";
    for (var pattern in _merchantPatterns) {
      var match = pattern.firstMatch(message);
      if (match != null) {
        merchant = match.group(1)!.trim();
        break;
      }
    }

    // ---------- STEP 4: Auto Categorization ----------
    String category = "Other";
    for (var keyword in _categoryMapping.keys) {
      if (message.contains(keyword)) {
        category = _categoryMapping[keyword]!;
        break;
      }
    }

    // ---------- STEP 5: Confidence Score ----------
    int confidence = _calculateConfidence(
      hasAmount: amount != null,
      hasType: type != "unknown",
    );

    return {
      "original": rawMessage,
      "type": type,
      "amount": amount,
      "merchant": merchant,
      "category": category,
      "confidence": confidence,
    };
  }

  bool _isPromotional(String body) {
    final promoKeywords = [
      "recharge now", "plan", "offer", "benefits", "validity", 
      "data", "quota", "expired", "click", "link", "http", "www",
      "otp", "code", "verification", "login", "win", "lucky"
    ];
    return promoKeywords.any((k) => body.contains(k));
  }

  bool _containsWord(String text, List<String> keywords) {
    for (var keyword in keywords) {
      // Regex for word boundary: \bWORD\b
      if (RegExp(r'\b' + RegExp.escape(keyword) + r'\b', caseSensitive: false).hasMatch(text)) {
        return true;
      }
    }
    return false;
  }

  int _calculateConfidence({
    required bool hasAmount,
    required bool hasType,
  }) {
    int score = 0;
    if (hasAmount) score += 60;
    if (hasType) score += 40;
    return score;
  }
}
