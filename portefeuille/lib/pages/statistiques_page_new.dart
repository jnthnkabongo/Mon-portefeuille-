import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:portefeuille/theme/theme_provider.dart';
import 'package:portefeuille/widgets/user_initial_avatar.dart';
import 'package:provider/provider.dart';
import '../services/database.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  bool _hasLoadedData = false;

  // Variables spécifiques par devise
  double _usdIncome = 0;
  double _usdExpense = 0;
  Map<String, double> _usdCategoryTotals = {};
  double _fcIncome = 0;
  double _fcExpense = 0;
  Map<String, double> _fcCategoryTotals = {};

  bool _isLoading = true;
  int? _selectedDeviceId;
  List<Map<String, dynamic>> _devices = [];
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController?.addListener(_onTabChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoadedData) {
      _hasLoadedData = true;
      _loadData();
    }
  }

  @override
  void dispose() {
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted) {
      _loadTransactions();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    await _loadDevices();

    if (_selectedDeviceId == null && _devices.isNotEmpty) {
      _selectedDeviceId = _devices.first['id'] as int;
    }

    await _loadTransactions();
  }

  Future<void> _loadDevices() async {
    try {
      final devices = await _databaseService.getAllDevices();
      if (mounted) {
        setState(() {
          _devices = devices;
          if (_selectedDeviceId == null && _devices.isNotEmpty) {
            _selectedDeviceId = _devices.first['id'] as int;
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadTransactions() async {
    try {
      final transactionsData = await _databaseService.getAllTransactions(
        deviceId: _selectedDeviceId,
      );

      double usdIncome = 0, usdExpense = 0, fcIncome = 0, fcExpense = 0;
      final usdCategoryTotals = <String, double>{};
      final fcCategoryTotals = <String, double>{};

      for (final data in transactionsData) {
        final category = data['category'] as String? ?? 'Sans catégorie';
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final currency = data['currency'] as String? ?? 'USD';
        final type = data['type'] as String? ?? 'expense';

        final validCurrency = (currency != 'USD' && currency != 'FC')
            ? 'USD'
            : currency;

        if (validCurrency == 'USD') {
          usdCategoryTotals[category] =
              (usdCategoryTotals[category] ?? 0) + amount;
          if (type == 'income') {
            usdIncome += amount;
          } else {
            usdExpense += amount;
          }
        } else {
          fcCategoryTotals[category] =
              (fcCategoryTotals[category] ?? 0) + amount;
          if (type == 'income') {
            fcIncome += amount;
          } else {
            fcExpense += amount;
          }
        }
      }

      if (mounted) {
        setState(() {
          _usdIncome = usdIncome;
          _usdExpense = usdExpense;
          _usdCategoryTotals = usdCategoryTotals;
          _fcIncome = fcIncome;
          _fcExpense = fcExpense;
          _fcCategoryTotals = fcCategoryTotals;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _getDeviceName() {
    if (_devices.isEmpty) return null;
    try {
      return _devices.firstWhere((d) => d['id'] == _selectedDeviceId)['nom']
          as String?;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    if (_tabController == null) {
      _tabController = TabController(length: 2, vsync: this);
    }

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
        appBar: AppBar(
          title: const Text(
            "Statistiques",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: isDarkMode ? Colors.grey[900] : Colors.teal,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final deviceName = _getDeviceName();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Statistiques",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.teal,
        elevation: 0,
        actions: const [UserInitialAvatar()],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Column(
          children: [
            // TabBar pour les devises
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.teal,
                borderRadius: BorderRadius.circular(6),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white,
                indicator: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade400, Colors.teal.shade600],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: (isDarkMode ? Colors.grey : Colors.teal)
                          .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorWeight: 0,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                splashFactory: InkRipple.splashFactory,
                overlayColor: MaterialStateProperty.resolveWith<Color?>((
                  Set<MaterialState> states,
                ) {
                  if (states.contains(MaterialState.pressed)) {
                    return Colors.teal.withOpacity(0.1);
                  }
                  return null;
                }),
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.attach_money, size: 18, color: Colors.white),
                        SizedBox(width: 6),
                        Text('Dollars'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.money, size: 18, color: Colors.white),
                        SizedBox(width: 6),
                        Text('Francs'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Contenu des onglets
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Onglet USD
                  _CurrencyStatsTab(
                    income: _usdIncome,
                    expense: _usdExpense,
                    categoryTotals: _usdCategoryTotals,
                    currency: 'USD',
                    currencySymbol: '\$',
                    deviceName: deviceName,
                  ),
                  // Onglet FC
                  _CurrencyStatsTab(
                    income: _fcIncome,
                    expense: _fcExpense,
                    categoryTotals: _fcCategoryTotals,
                    currency: 'FC',
                    currencySymbol: 'FC',
                    deviceName: deviceName,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
    this.deviceName,
  });

  final String title;
  final double amount;
  final Color color;
  final IconData icon;
  final String? deviceName;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                if (deviceName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      deviceName!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              NumberFormat.currency(symbol: '').format(amount),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance, this.deviceName});

  final double balance;
  final String? deviceName;

  @override
  Widget build(BuildContext context) {
    final isPositive = balance >= 0;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isPositive ? Icons.account_balance_wallet : Icons.warning,
                      color: isPositive ? Colors.blue : Colors.orange,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Solde',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                if (deviceName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (isPositive ? Colors.blue : Colors.orange)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      deviceName!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isPositive ? Colors.blue : Colors.orange,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              NumberFormat.currency(symbol: '').format(balance),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isPositive ? Colors.blue : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.income, required this.expense});

  final double income;
  final double expense;

  @override
  Widget build(BuildContext context) {
    final total = income + expense;
    final incomePercentage = total > 0
        ? (income / total * 100).toDouble()
        : 0.0;
    final expensePercentage = total > 0
        ? (expense / total * 100).toDouble()
        : 0.0;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Répartition',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: total > 0
                  ? BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: income > expense ? income * 1.2 : expense * 1.2,
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final value = rod.toY.round();
                              final label = group.x.toInt() == 0
                                  ? 'Revenus'
                                  : 'Dépenses';
                              return BarTooltipItem(
                                '$label\n${NumberFormat.currency(symbol: '').format(value)}',
                                const TextStyle(color: Colors.white),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final style = TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                );
                                return Text(
                                  value.toInt() == 0 ? 'Revenus' : 'Dépenses',
                                  style: style,
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  NumberFormat.compactCurrency(
                                    symbol: '',
                                  ).format(value),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 10,
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          BarChartGroupData(
                            x: 0,
                            barRods: [
                              BarChartRodData(
                                toY: income,
                                color: Colors.green,
                                width: 40,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 1,
                            barRods: [
                              BarChartRodData(
                                toY: expense,
                                color: Colors.red,
                                width: 40,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : const Center(
                      child: Text(
                        'Aucune donnée disponible',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                _LegendItem(
                  color: Colors.green,
                  label: 'Revenus',
                  value: income,
                  percentage: incomePercentage,
                ),
                const SizedBox(height: 2),
                _LegendItem(
                  color: Colors.red,
                  label: 'Dépenses',
                  value: expense,
                  percentage: expensePercentage,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChart extends StatelessWidget {
  const _CategoryChart({required this.categoryTotals});

  final Map<String, double> categoryTotals;

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = sortedCategories.take(7).toList();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top catégories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: topCategories.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucune catégorie',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    )
                  : PieChart(
                      PieChartData(
                        sections: topCategories.asMap().entries.map((entry) {
                          final index = entry.key;
                          final category = entry.value;
                          final total = categoryTotals.values.fold(
                            0.0,
                            (a, b) => a + b.abs(),
                          );
                          final percentage = (category.value / total * 100);
                          return PieChartSectionData(
                            value: category.value,
                            title: '${percentage.toStringAsFixed(1)}%',
                            color: colors[index % colors.length],
                            radius: 60,
                            titleStyle: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                        centerSpaceRadius: 30,
                        centerSpaceColor: Colors.grey[100],
                        sectionsSpace: 2,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: topCategories.asMap().entries.map((entry) {
                  final index = entry.key;
                  final category = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: colors[index % colors.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          category.key,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
    required this.percentage,
  });

  final Color color;
  final String label;
  final double value;
  final double percentage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
        Text(
          '${NumberFormat.currency(symbol: '').format(value)} (${percentage.toStringAsFixed(1)}%)',
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _CurrencyStatsTab extends StatelessWidget {
  const _CurrencyStatsTab({
    required this.income,
    required this.expense,
    required this.categoryTotals,
    required this.currency,
    required this.currencySymbol,
    this.deviceName,
  });

  final double income;
  final double expense;
  final Map<String, double> categoryTotals;
  final String currency;
  final String currencySymbol;
  final String? deviceName;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 100),
      children: [
        // Cartes résumé
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Revenus',
                amount: income,
                color: Colors.green,
                icon: Icons.trending_up,
                deviceName: deviceName,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _SummaryCard(
                title: 'Dépenses',
                amount: expense,
                color: Colors.red,
                icon: Icons.trending_down,
                deviceName: deviceName,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Solde
        _BalanceCard(balance: income - expense, deviceName: deviceName),
        const SizedBox(height: 24),
        // Graphiques
        Column(
          children: [
            SizedBox(
              height: 300,
              child: _ChartCard(income: income, expense: expense),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: _CategoryChart(categoryTotals: categoryTotals),
            ),
          ],
        ),
      ],
    );
  }
}
