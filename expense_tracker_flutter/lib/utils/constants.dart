class AppConstants {
  // FCM Endpoint
  static const String flaskBackendUrl = 'https://expense-tracker-2ya5.onrender.com'; // Production Server

  // Currencies
  static const Map<String, Map<String, String>> currencies = {
    'USD': {'symbol': '\$', 'name': 'US Dollar'},
    'INR': {'symbol': '₹', 'name': 'Indian Rupee'},
    'EUR': {'symbol': '€', 'name': 'Euro'},
    'GBP': {'symbol': '£', 'name': 'British Pound'},
    'JPY': {'symbol': '¥', 'name': 'Japanese Yen'},
  };

  // Expense Categories
  static const List<String> expenseCategories = [
    'Food & Drink',
    'Transportation',
    'Housing',
    'Bills',
    'Shopping',
    'Entertainment',
    'Other'
  ];

  // Income Sources
  static const List<String> incomeSources = [
    'Salary',
    'Freelance',
    'Investment',
    'Gift',
    'Other'
  ];

  // Exchange Rates (Mock rates to USD)
  static const Map<String, double> exchangeRatesToUSD = {
    'EUR': 1.08,
    'INR': 0.012,
    'GBP': 1.25,
    'JPY': 0.0067,
    'USD': 1.0,
  };

  // Get exchange rate between two currencies
  static double getExchangeRate(String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return 1.0;
    
    double rateFromToUSD = exchangeRatesToUSD[fromCurrency] ?? 1.0;
    double rateToUSDToTarget = 1.0 / (exchangeRatesToUSD[toCurrency] ?? 1.0);
    
    return rateFromToUSD * rateToUSDToTarget;
  }
}
