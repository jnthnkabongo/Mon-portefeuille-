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

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  Future<List<FinanceTransaction>> _usdTransactions = Future.value([]);
  Future<List<FinanceTransaction>> _fcTransactions = Future.value([]);
  final _currency = NumberFormat.currency(symbol: '');
  final DatabaseService _databaseService = DatabaseService();

  _HistoryTypeFilter _typeFilter = _HistoryTypeFilter.all;
  String _categoryFilter = 'Toutes';
  int? _selectedDeviceId;
  int? _usdSelectedDeviceId;
  int? _fcSelectedDeviceId;
  List<Map<String, dynamic>> _devices = [];
  bool _isLoadingDevices = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController?.addListener(_onTabChanged);
    _loadData();
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
    await _loadDevices();
    _loadTransactions();
  }

  Future<void> _loadDevices() async {
    try {
      final devices = await _databaseService.getAllDevices();
      if (mounted) {
        setState(() {
          _devices = devices;
          _isLoadingDevices = false;
          if (_selectedDeviceId == null && _devices.isNotEmpty) {
            _selectedDeviceId = _devices.first['id'] as int;
            _usdSelectedDeviceId = _devices.first['id'] as int;
            _fcSelectedDeviceId = _devices.first['id'] as int;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDevices = false;
        });
      }
    }
  }

  void _loadTransactions() {

    // Charger les transactions USD
    _usdTransactions = _databaseService
        .getAllTransactions(deviceId: _usdSelectedDeviceId)
        .then((maps) {
          final allTransactions = maps
              .map((map) => FinanceTransaction.fromDbMap(map))
              .toList();

          final usdFiltered = allTransactions.where((tx) {
            final currency = tx.currency.toUpperCase().trim();
            return currency == 'USD';
          }).toList();
          return usdFiltered;
        });

    // Charger les transactions FC
    _fcTransactions = _databaseService
        .getAllTransactions(deviceId: _fcSelectedDeviceId)
        .then((maps) {
          final allTransactions = maps
              .map((map) => FinanceTransaction.fromDbMap(map))
              .toList();

          final fcFiltered = allTransactions.where((tx) {
            final currency = tx.currency.toUpperCase().trim();
            return currency == 'FC';
          }).toList();
          return fcFiltered;
        });
  }

  Future<void> _refresh() async {
    setState(_loadTransactions);
    await _usdTransactions;
    await _fcTransactions;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    if (_tabController == null) {
      _tabController = TabController(length: 2, vsync: this);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Historique",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.teal,
        elevation: 0,
        actions: [const UserInitialAvatar()],
      ),
      body: Column(
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
                    color: (isDarkMode ? Colors.grey : Colors.teal).withOpacity(
                      0.3,
                    ),
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
                _CurrencyHistoryTab(
                  futureTransactions: _usdTransactions,
                  typeFilter: _typeFilter,
                  categoryFilter: _categoryFilter,
                  onTypeFilterChanged: (filter) {
                    setState(() {
                      _typeFilter = filter;
                    });
                    _loadTransactions();
                  },
                  onCategoryFilterChanged: (category) {
                    setState(() {
                      _categoryFilter = category;
                    });
                    _loadTransactions();
                  },
                  currency: 'USD',
                  currencySymbol: '\$',
                  onRefresh: _refresh,
                  devices: _devices,
                  selectedDeviceId: _usdSelectedDeviceId,
                  onDeviceChanged: (deviceId) {
                    setState(() {
                      _usdSelectedDeviceId = deviceId;
                    });
                    _loadTransactions();
                  },
                ),
                // Onglet FC
                _CurrencyHistoryTab(
                  futureTransactions: _fcTransactions,
                  typeFilter: _typeFilter,
                  categoryFilter: _categoryFilter,
                  onTypeFilterChanged: (filter) {
                    setState(() {
                      _typeFilter = filter;
                    });
                    _loadTransactions();
                  },
                  onCategoryFilterChanged: (category) {
                    setState(() {
                      _categoryFilter = category;
                    });
                    _loadTransactions();
                  },
                  currency: 'FC',
                  currencySymbol: 'FC',
                  onRefresh: _refresh,
                  devices: _devices,
                  selectedDeviceId: _fcSelectedDeviceId,
                  onDeviceChanged: (deviceId) {
                    setState(() {
                      _fcSelectedDeviceId = deviceId;
                    });
                    _loadTransactions();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyHistoryTab extends StatelessWidget {
  const _CurrencyHistoryTab({
    required this.futureTransactions,
    required this.typeFilter,
    required this.categoryFilter,
    required this.onTypeFilterChanged,
    required this.onCategoryFilterChanged,
    required this.currency,
    required this.currencySymbol,
    required this.onRefresh,
    required this.devices,
    required this.selectedDeviceId,
    required this.onDeviceChanged,
  });

  final Future<List<FinanceTransaction>> futureTransactions;
  final _HistoryTypeFilter typeFilter;
  final String categoryFilter;
  final Function(_HistoryTypeFilter) onTypeFilterChanged;
  final Function(String) onCategoryFilterChanged;
  final String currency;
  final String currencySymbol;
  final Future<void> Function() onRefresh;
  final List<Map<String, dynamic>> devices;
  final int? selectedDeviceId;
  final Function(int?) onDeviceChanged;

  String? _getDeviceName() {
    if (devices.isEmpty) return null;
    try {
      return devices.firstWhere((d) => d['id'] == selectedDeviceId)['nom']
          as String?;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final _currency = NumberFormat.currency(symbol: '');
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final deviceName = _getDeviceName();

    return Column(
      children: [
        // Liste des transactions
        Expanded(
          child: FutureBuilder<List<FinanceTransaction>>(
            future: futureTransactions,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return RefreshIndicator(
                  onRefresh: onRefresh,
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
                final matchesCategory =
                    categoryFilter == 'Toutes' || tx.category == categoryFilter;

                return matchesCategory;
              }).toList();

              return RefreshIndicator(
                onRefresh: onRefresh,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final options = categoryOptions.toList()..sort();
                      if (!options.contains(categoryFilter)) {
                        onCategoryFilterChanged('Toutes');
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: options.map((cat) {
                            return ChoiceChip(
                              label: Text(cat),
                              selected: categoryFilter == cat,
                              onSelected: (_) {
                                onCategoryFilterChanged(cat);
                              },
                            );
                          }).toList(),
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
                            isIncome
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: color,
                          ),
                        ),
                        title: Text(
                          tx.category.isEmpty ? 'Sans catégorie' : tx.category,
                        ),
                        subtitle: Text(
                          deviceName != null
                              ? tx.note.isEmpty
                                    ? '$deviceName • ${_formatDate(tx.createdAt)}'
                                    : '$deviceName • ${tx.note} • ${_formatDate(tx.createdAt)}'
                              : tx.note.isEmpty
                              ? _formatDate(tx.createdAt)
                              : '${tx.note} • ${_formatDate(tx.createdAt)}',
                        ),
                        trailing: Text(
                          '${isIncome ? '+' : '-'}${_currency.format(tx.amount)} ${currencySymbol}',
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
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final d = NumberFormat('00');
    return '${d.format(dt.day)}/${d.format(dt.month)}/${dt.year}';
  }
}
