import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/finance_transaction.dart';
import '../theme/theme_provider.dart';
import '../widgets/user_initial_avatar.dart';
import '../services/database.dart';

enum _HistoryTypeFilter { all, income, expense }

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<FinanceTransaction>> _futureTransactions;
  final _currency = NumberFormat.currency(symbol: '');

  _HistoryTypeFilter _typeFilter = _HistoryTypeFilter.all;
  String _categoryFilter = 'Toutes';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  void _loadTransactions() {
    _futureTransactions = DatabaseService().getAllTransactions().then(
      (maps) => maps.map((map) => FinanceTransaction.fromDbMap(map)).toList(),
    );
  }

  Future<void> _refresh() async {
    setState(_loadTransactions);
    await _futureTransactions;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Historique",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.teal,
        elevation: 0,
        actions: const [UserInitialAvatar()],
      ),
      body: FutureBuilder<List<FinanceTransaction>>(
        future: _futureTransactions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  SizedBox(height: 24),
                  Center(child: Text("Aucune transaction disponible.")),
                ],
              ),
            );
          }

          final transactions = snapshot.data!;

          final categoryOptions = <String>{'Toutes'}
            ..addAll(
              transactions
                  .map((t) => t.category.trim())
                  .where((c) => c.isNotEmpty),
            );

          final filtered = transactions.where((tx) {
            final matchesType = switch (_typeFilter) {
              _HistoryTypeFilter.all => true,
              _HistoryTypeFilter.income => tx.type == TransactionType.income,
              _HistoryTypeFilter.expense => tx.type == TransactionType.expense,
            };

            final matchesCategory =
                _categoryFilter == 'Toutes' || tx.category == _categoryFilter;

            return matchesType && matchesCategory;
          }).toList();

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  final options = categoryOptions.toList()..sort();
                  if (!options.contains(_categoryFilter)) {
                    _categoryFilter = 'Toutes';
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('Toutes'),
                              selected: _typeFilter == _HistoryTypeFilter.all,
                              onSelected: (_) {
                                setState(() {
                                  _typeFilter = _HistoryTypeFilter.all;
                                });
                              },
                            ),
                            ChoiceChip(
                              label: const Text('Entrées'),
                              selected:
                                  _typeFilter == _HistoryTypeFilter.income,
                              onSelected: (_) {
                                setState(() {
                                  _typeFilter = _HistoryTypeFilter.income;
                                });
                              },
                            ),
                            ChoiceChip(
                              label: const Text('Dépenses'),
                              selected:
                                  _typeFilter == _HistoryTypeFilter.expense,
                              onSelected: (_) {
                                setState(() {
                                  _typeFilter = _HistoryTypeFilter.expense;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Text(
                              'Catégorie:',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? Colors.grey[850]
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDarkMode
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _categoryFilter,
                                    isExpanded: true,
                                    items: options
                                        .map(
                                          (c) => DropdownMenuItem<String>(
                                            value: c,
                                            child: Text(c),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setState(() {
                                        _categoryFilter = value;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (filtered.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: Center(
                              child: Text('Aucune transaction pour ce filtre.'),
                            ),
                          ),
                      ],
                    ),
                  );
                }

                final tx = filtered[index - 1];
                final isIncome = tx.type == TransactionType.income;
                final color = isIncome ? Colors.green : Colors.red;

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withAlpha(51),
                      child: Icon(
                        isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                        color: color,
                      ),
                    ),
                    title: Text(
                      tx.category.isEmpty ? 'Sans catégorie' : tx.category,
                    ),
                    subtitle: Text(
                      tx.note.isEmpty
                          ? _formatDate(tx.createdAt)
                          : '${tx.note} • ${_formatDate(tx.createdAt)}',
                    ),
                    trailing: Text(
                      '${isIncome ? '+' : '-'}${_currency.format(tx.amount)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final d = NumberFormat('00');
    return '${d.format(dt.day)}/${d.format(dt.month)}/${dt.year}';
  }
}
