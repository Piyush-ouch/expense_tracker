import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../models/expense_model.dart';
import '../models/income_model.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import '../widgets/glowing_loader.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  DateTime _selectedDate = DateTime.now();
  String _filterType = 'month'; // month, week, year
  String _chartMode = 'expense'; // expense or income
  UserModel? _userData;

  // Chart.js color palette from web app
  final List<Color> _chartColors = [
    const Color(0xFFfdd835), // Yellow
    const Color(0xFF00bcd4), // Cyan
    const Color(0xFFff4081), // Pink
    const Color(0xFF4caf50), // Green
    const Color(0xFF9c27b0), // Purple
    const Color(0xFFff9800), // Orange
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _authService.currentUser;
    if (user != null) {
      final data = await _authService.getUserData(user.uid);
      setState(() {
        _userData = data;
      });
    }
  }

  DateTime get _startDate {
    if (_filterType == 'year') {
      return DateTime(_selectedDate.year, 1, 1);
    } else if (_filterType == 'week') {
      final weekday = _selectedDate.weekday;
      return _selectedDate.subtract(Duration(days: weekday - 1));
    } else {
      return DateTime(_selectedDate.year, _selectedDate.month, 1);
    }
  }

  DateTime get _endDate {
    if (_filterType == 'year') {
      return DateTime(_selectedDate.year, 12, 31, 23, 59, 59);
    } else if (_filterType == 'week') {
      return _startDate.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    } else {
      return DateTime(_selectedDate.year, _selectedDate.month + 1, 0, 23, 59, 59);
    }
  }

  String get _periodLabel {
    if (_filterType == 'year') {
      return _selectedDate.year.toString();
    } else if (_filterType == 'week') {
      return '${DateFormat('MMM dd').format(_startDate)} - ${DateFormat('MMM dd').format(_endDate)}';
    } else {
      return DateFormat('MMMM yyyy').format(_selectedDate);
    }
  }

  void _previousPeriod() {
    setState(() {
      if (_filterType == 'year') {
        _selectedDate = DateTime(_selectedDate.year - 1, _selectedDate.month);
      } else if (_filterType == 'week') {
        _selectedDate = _selectedDate.subtract(const Duration(days: 7));
      } else {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
      }
    });
  }

  void _nextPeriod() {
    setState(() {
      if (_filterType == 'year') {
        _selectedDate = DateTime(_selectedDate.year + 1, _selectedDate.month);
      } else if (_filterType == 'week') {
        _selectedDate = _selectedDate.add(const Duration(days: 7));
      } else {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
      }
    });
  }

  void _toggleChartMode() {
    setState(() {
      _chartMode = _chartMode == 'expense' ? 'income' : 'expense';
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) return const Center(child: Text('Not logged in'));

    return Column(
      children: [
        const SizedBox(height: 20), // Add top spacing
        
        // Top header with Expenses/Income toggle
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          color: AppTheme.backgroundColor,
          child: GestureDetector(
            onTap: _toggleChartMode,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _chartMode == 'expense' ? 'Expenses' : 'Income',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(Icons.arrow_drop_down, color: AppTheme.textPrimary),
              ],
            ),
          ),
        ),

        // Week/Month/Year filter tabs
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: const Color(0xFF1f1f1f),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF333333)),
          ),
          child: Row(
            children: [
              Expanded(child: _buildFilterTab('Week', 'week')),
              Expanded(child: _buildFilterTab('Month', 'month')),
              Expanded(child: _buildFilterTab('Year', 'year')),
            ],
          ),
        ),

        // Period navigator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _previousPeriod,
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('❮', style: TextStyle(fontSize: 20, color: AppTheme.textSecondary)),
                ),
              ),
              Text(
                _periodLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: _nextPeriod,
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('❯', style: TextStyle(fontSize: 20, color: AppTheme.textSecondary)),
                ),
              ),
            ],
          ),
        ),

        // Chart and breakdown
        Expanded(
          child: SingleChildScrollView(
            child: _chartMode == 'expense'
                ? _buildExpenseChart(user.uid)
                : _buildIncomeChart(user.uid),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTab(String label, String value) {
    final isSelected = _filterType == value;
    return GestureDetector(
      onTap: () => setState(() => _filterType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.black : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseChart(String uid) {
    return FutureBuilder<Map<String, double>>(
      future: _firestoreService.getExpenseChartData(uid, _startDate, _endDate),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: GlowingCircularLoader());
        }

        final data = snapshot.data!;
        if (data.isEmpty) {
          return _buildEmptyChart('No expenses in this period');
        }

        return _buildChartLayout(data);
      },
    );
  }

  Widget _buildIncomeChart(String uid) {
    return FutureBuilder<Map<String, double>>(
      future: _firestoreService.getIncomeChartData(uid, _startDate, _endDate),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: GlowingCircularLoader());
        }

        final data = snapshot.data!;
        if (data.isEmpty) {
          return _buildEmptyChart('No income in this period');
        }

        return _buildChartLayout(data);
      },
    );
  }

  Widget _buildChartLayout(Map<String, double> data) {
    final total = data.values.fold(0.0, (sum, value) => sum + value);
    
    // Sort data by value descending
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        // Chart area
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: SizedBox(
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: _createDonutSections(sortedEntries),
                    sectionsSpace: 2,
                    centerSpaceRadius: 55,
                  ),
                ),
                // Total in center
                Text(
                  total.toStringAsFixed(0),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 10),
        
        // Breakdown list
        _buildBreakdownList(sortedEntries, total),
      ],
    );
  }

  List<PieChartSectionData> _createDonutSections(List<MapEntry<String, double>> sortedEntries) {
    return sortedEntries.asMap().entries.map((entry) {
      final index = entry.key;
      final dataEntry = entry.value;
      
      return PieChartSectionData(
        value: dataEntry.value,
        title: '',
        color: _chartColors[index % _chartColors.length],
        radius: 40,
      );
    }).toList();
  }

  Widget _buildBreakdownList(List<MapEntry<String, double>> sortedEntries, double total) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: sortedEntries.asMap().entries.map((entry) {
          final index = entry.key;
          final dataEntry = entry.value;
          final percentage = (dataEntry.value / total * 100);
          final categoryStyle = _getCategoryStyle(dataEntry.key);
          final chartColor = _chartColors[index % _chartColors.length];
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 25),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category icon
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: categoryStyle['color'] as Color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    categoryStyle['icon'] as IconData,
                    color: AppTheme.surfaceColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 15),
                // Right column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name, percentage, and amount
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  dataEntry.key,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${percentage.toStringAsFixed(2)}%',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            dataEntry.value.toStringAsFixed(0),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Progress bar
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFF333333),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: percentage / 100,
                          child: Container(
                            decoration: BoxDecoration(
                              color: chartColor,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Map<String, dynamic> _getCategoryStyle(String category) {
    // Exact mapping from web app's getCategoryStyle function
    final styles = {
      // Expense categories
      'Shopping': {'icon': Icons.shopping_cart, 'color': const Color(0xFFfde68a)},
      'Food': {'icon': Icons.restaurant, 'color': const Color(0xFFa7f3d0)},
      'Food & Drink': {'icon': Icons.restaurant, 'color': const Color(0xFFa7f3d0)},
      'Phone': {'icon': Icons.phone_android, 'color': const Color(0xFFe5e7eb)},
      'Entertainment': {'icon': Icons.movie, 'color': const Color(0xFFfbcfe8)},
      'Education': {'icon': Icons.school, 'color': const Color(0xFFe5e7eb)},
      'Beauty': {'icon': Icons.spa, 'color': const Color(0xFFe5e7eb)},
      'Sports': {'icon': Icons.sports_soccer, 'color': const Color(0xFFe5e7eb)},
      'Social': {'icon': Icons.people, 'color': const Color(0xFFe5e7eb)},
      'Transportation': {'icon': Icons.directions_bus, 'color': const Color(0xFFbfdbfe)},
      'Transport': {'icon': Icons.directions_bus, 'color': const Color(0xFFbfdbfe)},
      'Clothing': {'icon': Icons.checkroom, 'color': const Color(0xFFe5e7eb)},
      'Car': {'icon': Icons.directions_car, 'color': const Color(0xFFbfdbfe)},
      'Alcohol': {'icon': Icons.local_bar, 'color': const Color(0xFFe5e7eb)},
      'Cigarettes': {'icon': Icons.smoking_rooms, 'color': const Color(0xFFe5e7eb)},
      'Electronics': {'icon': Icons.laptop, 'color': const Color(0xFFe5e7eb)},
      'Travel': {'icon': Icons.flight, 'color': const Color(0xFFe5e7eb)},
      'Health': {'icon': Icons.favorite, 'color': const Color(0xFFe5e7eb)},
      'Pets': {'icon': Icons.pets, 'color': const Color(0xFFe5e7eb)},
      'Repairs': {'icon': Icons.build, 'color': const Color(0xFFe5e7eb)},
      'Housing': {'icon': Icons.home, 'color': const Color(0xFFe5e7eb)},
      'Home': {'icon': Icons.weekend, 'color': const Color(0xFFe5e7eb)},
      'Gifts': {'icon': Icons.card_giftcard, 'color': const Color(0xFFe5e7eb)},
      'Donations': {'icon': Icons.volunteer_activism, 'color': const Color(0xFFe5e7eb)},
      'Lottery': {'icon': Icons.casino, 'color': const Color(0xFFe5e7eb)},
      'Snacks': {'icon': Icons.cookie, 'color': const Color(0xFFe5e7eb)},
      'Kids': {'icon': Icons.child_care, 'color': const Color(0xFFe5e7eb)},
      'Vegetables': {'icon': Icons.eco, 'color': const Color(0xFFe5e7eb)},
      'Fruits': {'icon': Icons.apple, 'color': const Color(0xFFe5e7eb)},
      'Bills': {'icon': Icons.receipt_long, 'color': const Color(0xFFe5e7eb)},
      'Other': {'icon': Icons.receipt, 'color': const Color(0xFFe5e7eb)},
      
      // Income sources
      'Salary': {'icon': Icons.work, 'color': const Color(0xFFfdd835)},
      'Freelance': {'icon': Icons.laptop_mac, 'color': const Color(0xFFfdd835)},
      'Investment': {'icon': Icons.trending_up, 'color': const Color(0xFFfdd835)},
      'Gift': {'icon': Icons.card_giftcard, 'color': const Color(0xFFfdd835)},
      'Other': {'icon': Icons.attach_money, 'color': const Color(0xFFfdd835)},
    };

    return styles[category] ?? {'icon': Icons.receipt, 'color': const Color(0xFFe5e7eb)};
  }

  Widget _buildEmptyChart(String message) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pie_chart_outline, size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
