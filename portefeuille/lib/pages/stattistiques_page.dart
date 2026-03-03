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

class _StatsPageState extends State<StatsPage> {
  double income = 0;
  double expense = 0;
  Map<String, double> _categoryTotals = {};
  bool _isLoading = true;
  final DatabaseService _databaseService = DatabaseService();
  final formatter = NumberFormat('#,###', 'fr_FR');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final totals = await _databaseService.getTotals();
      final transactionsData = await _databaseService.getAllTransactions();

      // Calculer les totaux par catégorie directement depuis les données brutes
      final categoryTotals = <String, double>{};
      for (final data in transactionsData) {
        final category = (data['category'] as String? ?? '').isEmpty
            ? 'Sans catégorie'
            : data['category'] as String;
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
      }

      setState(() {
        income = totals['income'] ?? 0;
        expense = totals['expense'] ?? 0;
        _categoryTotals = categoryTotals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(
                  left: 16,
                  top: 16,
                  right: 16,
                  bottom: 100,
                ),
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
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _SummaryCard(
                          title: 'Dépenses',
                          amount: expense,
                          color: Colors.red,
                          icon: Icons.trending_down,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Solde
                  _BalanceCard(balance: income - expense),
                  const SizedBox(height: 24),
                  // Graphiques
                  Column(
                    children: [
                      // Graphique circulaire
                      SizedBox(
                        height: 300,
                        child: _ChartCard(income: income, expense: expense),
                      ),
                      const SizedBox(height: 16),
                      // Graphique par catégorie
                      SizedBox(
                        height: 300,
                        child: _CategoryChart(categoryTotals: _categoryTotals),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    super.key,
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  final String title;
  final double amount;
  final Color color;
  final IconData icon;

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
            const SizedBox(height: 8),
            Text(
              NumberFormat.currency(symbol: 'FC ').format(amount),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            //Text('${formatter.format(amount)} FC'),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({super.key, required this.balance});

  final double balance;

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
            const SizedBox(height: 8),
            Text(
              NumberFormat.currency(symbol: 'FC ').format(balance),
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
  const _ChartCard({super.key, required this.income, required this.expense});

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
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final style = TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                );
                                switch (value.toInt()) {
                                  case 0:
                                    return Text('Revenus', style: style);
                                  case 1:
                                    return Text('Dépenses', style: style);
                                  default:
                                    return const Text('');
                                }
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
            // Légende avec montants
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
  const _CategoryChart({super.key, required this.categoryTotals});

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

    // Trier les catégories par montant (décroissant) et prendre les 7 premières
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
                          final percentage =
                              (category.value /
                              categoryTotals.values.fold(
                                0.0,
                                (a, b) => a + b.abs(),
                              ) *
                              100);
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
            // Légende
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
    this.isBold = false,
  });

  final Color color;
  final String label;
  final double value;
  final double percentage;
  final bool isBold;

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
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 14 : 12,
            ),
          ),
        ),
        Text(
          '${NumberFormat.currency(symbol: '').format(value)} (${percentage.toStringAsFixed(1)}%)',
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 14 : 12,
            color: color,
          ),
        ),
      ],
    );
  }
}
