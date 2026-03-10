import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/finance_transaction.dart';
import '../widgets/user_initial_avatar.dart';
import '../services/database.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final _currency = NumberFormat.currency(symbol: '');
  late Future<void> _loadFuture;
  final DatabaseService _databaseService = DatabaseService();
  late TabController _tabController;

  List<FinanceTransaction> _usdItems = const [];
  List<FinanceTransaction> _fcItems = const [];
  double _incomeTotal = 0;
  double _expenseTotal = 0;
  double _usdIncomeTotal = 0;
  double _usdExpenseTotal = 0;
  double _fcIncomeTotal = 0;
  double _fcExpenseTotal = 0;
  int? _selectedDeviceId;
  List<Map<String, dynamic>> _devices = [];
  bool _isLoadingDevices = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFuture = _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _loadDevices();
    // Mettre à jour les anciennes transactions sans devise
    await _databaseService.updateTransactionsWithoutCurrency();
    await _reload();
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

  Future<void> _reload() async {
    print('=== DEBUG: _reload() called ===');
    print('Selected Device ID: $_selectedDeviceId');

    final itemsData = await _databaseService.getAllTransactions(
      deviceId: _selectedDeviceId,
    );

    print('Total transactions from DB: ${itemsData.length}');

    // Convertir les Map en FinanceTransaction et séparer par devise
    final usdTransactions = <FinanceTransaction>[];
    final fcTransactions = <FinanceTransaction>[];
    double usdIncome = 0, usdExpense = 0, fcIncome = 0, fcExpense = 0;

    for (final item in itemsData) {
      final tx = FinanceTransaction.fromDbMap(item);

      // Debug: afficher la devise de chaque transaction
      print('Transaction: ${tx.category}, Currency: "${tx.currency}"');

      // Gérer le cas où la devise est vide ou non définie
      String currency = tx.currency.isEmpty ? 'USD' : tx.currency;

      // Si la devise n'est ni USD ni FC, on met par défaut USD
      if (currency != 'USD' && currency != 'FC') {
        currency = 'USD';
        print(
          'Transaction ${tx.category} had invalid currency "${tx.currency}", setting to USD',
        );
      }

      if (currency == 'USD') {
        usdTransactions.add(tx);
        if (tx.type == TransactionType.income) {
          usdIncome += tx.amount;
        } else {
          usdExpense += tx.amount;
        }
      } else if (currency == 'FC') {
        fcTransactions.add(tx);
        if (tx.type == TransactionType.income) {
          fcIncome += tx.amount;
        } else {
          fcExpense += tx.amount;
        }
      }
    }

    // Debug: afficher les totaux
    print(
      'USD: ${usdTransactions.length} transactions, FC: ${fcTransactions.length} transactions',
    );

    if (mounted) {
      setState(() {
        _usdItems = usdTransactions;
        _fcItems = fcTransactions;
        _usdIncomeTotal = usdIncome;
        _usdExpenseTotal = usdExpense;
        _fcIncomeTotal = fcIncome;
        _fcExpenseTotal = fcExpense;

        // Calculer les totaux globaux pour la rétrocompatibilité
        _incomeTotal = usdIncome + fcIncome;
        _expenseTotal = usdExpense + fcExpense;

        print(
          'State updated - _usdItems: ${_usdItems.length}, _fcItems: ${_fcItems.length}',
        );
      });
    }
  }

  Future<void> _openAddSheet() async {
    final created = await showModalBottomSheet<FinanceTransaction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddTransactionSheet(),
    );

    if (created == null) return;
    await _databaseService.insertTransaction(created.toDbMap());
    await _reload();
  }

  Future<void> _deleteTx(FinanceTransaction tx) async {
    final id = tx.id;
    if (id == null) return;
    await _databaseService.deleteTransaction(id);
    await _reload();
  }

  double get balance => _incomeTotal - _expenseTotal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Portefeuille',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.teal,
        elevation: 0,
        actions: [const UserInitialAvatar()],
      ),
      body: FutureBuilder<void>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: Column(
              children: [
                const SizedBox(height: 20),

                // TabBar pour les devises
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.teal,
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
                          color: Colors.teal.withOpacity(0.3),
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
                    tabs: [
                      Tab(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.attach_money,
                                size: 18,
                                color: _tabController.index == 0
                                    ? Colors.white
                                    : Colors.white,
                              ),
                              const SizedBox(width: 6),
                              const Text('Dollars'),
                            ],
                          ),
                        ),
                      ),
                      Tab(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.money,
                                size: 18,
                                color: _tabController.index == 1
                                    ? Colors.white
                                    : Colors.white,
                              ),
                              const SizedBox(width: 6),
                              const Text('Francs'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // TabView pour le contenu
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Onglet Dollars
                      _CurrencyTab(
                        transactions: _usdItems,
                        incomeTotal: _usdIncomeTotal,
                        expenseTotal: _usdExpenseTotal,
                        currency: '\$',
                        currencySymbol: 'USD',
                        onDeleteTx: _deleteTx,
                      ),
                      // Onglet Francs
                      _CurrencyTab(
                        transactions: _fcItems,
                        incomeTotal: _fcIncomeTotal,
                        expenseTotal: _fcExpenseTotal,
                        currency: 'FC',
                        currencySymbol: 'FC',
                        onDeleteTx: _deleteTx,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 86),
        child: FloatingActionButton.extended(
          onPressed: _openAddSheet,
          icon: const Icon(Icons.add),
          label: const Text('Ajouter'),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _CurrencyTab extends StatelessWidget {
  const _CurrencyTab({
    required this.transactions,
    required this.incomeTotal,
    required this.expenseTotal,
    required this.currency,
    required this.currencySymbol,
    required this.onDeleteTx,
  });

  final List<FinanceTransaction> transactions;
  final double incomeTotal;
  final double expenseTotal;
  final String currency;
  final String currencySymbol;
  final Function(FinanceTransaction) onDeleteTx;

  double get balance => incomeTotal - expenseTotal;

  @override
  Widget build(BuildContext context) {
    print('=== DEBUG: _CurrencyTab build ===');
    print('Currency: $currencySymbol');
    print('Transactions count: ${transactions.length}');
    print('Income: $incomeTotal, Expense: $expenseTotal');

    return Column(
      children: [
        // Carte de solde pour la devise
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                currencySymbol == '\$'
                    ? Colors.blue.shade400
                    : Colors.teal.shade400,
                currencySymbol == '\$'
                    ? Colors.blue.shade600
                    : Colors.teal.shade600,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: (currencySymbol == '\$' ? Colors.blue : Colors.teal)
                    .withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Pattern de fond subtil
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              // Contenu
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            currencySymbol,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          currencySymbol == '\$'
                              ? Icons.trending_up
                              : Icons.show_chart,
                          color: Colors.white.withOpacity(0.7),
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Solde Total',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$currency ${balance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.greenAccent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Revenus',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$currency ${incomeTotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.redAccent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Dépenses',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$currency ${expenseTotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Liste des transactions
        Expanded(
          child: transactions.isEmpty
              ? Center(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200, width: 1),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: currencySymbol == '\$'
                                ? Colors.blue.shade50
                                : Colors.teal.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            currencySymbol == '\$'
                                ? Icons.account_balance_wallet_outlined
                                : Icons.savings_outlined,
                            size: 48,
                            color: currencySymbol == '\$'
                                ? Colors.blue.shade400
                                : Colors.teal.shade400,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Aucune transaction $currencySymbol',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Commencez par ajouter votre première transaction',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    return Dismissible(
                      key: ValueKey(
                        'tx_${tx.id}_${tx.currency}_${tx.createdAt.millisecondsSinceEpoch}',
                      ),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade400,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Supprimer'),
                                content: Text(
                                  'Voulez-vous supprimer cette transaction ${tx.currency} ?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Annuler'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('Supprimer'),
                                  ),
                                ],
                              ),
                            ) ??
                            false;
                      },
                      onDismissed: (_) => onDeleteTx(tx),
                      child: _TransactionTile(
                        tx: tx,
                        currency: NumberFormat.currency(symbol: currency),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.tx, required this.currency});

  final FinanceTransaction tx;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.type == TransactionType.income;
    final sign = isIncome ? '+' : '-';
    final amountColor = isIncome ? Colors.green.shade700 : Colors.red.shade700;
    final bgColor = isIncome ? Colors.green.shade50 : Colors.red.shade50;
    final iconColor = isIncome ? Colors.green.shade600 : Colors.red.shade600;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icône avec fond coloré
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Informations principales
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.category.isEmpty ? 'Sans catégorie' : tx.category,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(tx.createdAt),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (tx.note.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.note_alt,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            tx.note,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Badge de devise et montant
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Badge de devise
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: tx.currency == 'USD'
                        ? Colors.blue.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tx.currency,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: tx.currency == 'USD'
                          ? Colors.blue.shade700
                          : Colors.teal.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Montant
                Text(
                  '$sign${currency.format(tx.amount)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: amountColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final d = NumberFormat('00');
    return '${d.format(dt.day)}/${d.format(dt.month)}/${dt.year}';
  }
}

class _AddTransactionSheet extends StatefulWidget {
  const _AddTransactionSheet();

  @override
  State<_AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<_AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _databaseService = DatabaseService();

  TransactionType _type = TransactionType.expense;
  final _amountController = TextEditingController();
  String? _selectedCategory;
  final _noteController = TextEditingController();
  int? _selectedDeviceId;
  String _selectedCurrency = 'USD'; // Par défaut USD

  List<String> _categories = [];
  List<Map<String, dynamic>> _devices = [];
  bool _isLoadingCategories = true;
  bool _isLoadingDevices = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadDevices();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _databaseService.getCategoriesByType(
        _type == TransactionType.income ? 'income' : 'expense',
      );

      setState(() {
        _categories = categories.map((cat) => cat['name'] as String).toList();
        _isLoadingCategories = false;
        if (_selectedCategory == null && _categories.isNotEmpty) {
          _selectedCategory = _categories.first;
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _loadDevices() async {
    try {
      final devices = await _databaseService.getAllDevices();
      setState(() {
        _devices = devices;
        _isLoadingDevices = false;
        if (_selectedDeviceId == null && _devices.isNotEmpty) {
          _selectedDeviceId = _devices.first['id'] as int;
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingDevices = false;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final amount = double.parse(_amountController.text.replaceAll(',', '.'));
    final tx = FinanceTransaction(
      id: null,
      type: _type,
      amount: amount,
      category: _selectedCategory?.trim() ?? 'Général',
      note: _noteController.text.trim(),
      createdAt: DateTime.now(),
      deviceId: _selectedDeviceId,
      currency: _selectedCurrency,
    );

    Navigator.of(context).pop(tx);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: bottomInset + 16,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ajouter une transaction',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<TransactionType>(
                    segments: const [
                      ButtonSegment(
                        value: TransactionType.expense,
                        label: Text('Dépense'),
                        icon: Icon(Icons.arrow_upward),
                      ),
                      ButtonSegment(
                        value: TransactionType.income,
                        label: Text('Revenu'),
                        icon: Icon(Icons.arrow_downward),
                      ),
                    ],
                    selected: <TransactionType>{_type},
                    onSelectionChanged: (value) {
                      setState(() {
                        _type = value.first;
                        _selectedCategory = null;
                        _isLoadingCategories = true;
                      });
                      _loadCategories();
                    },
                  ),
                  const SizedBox(height: 16),
                  // Sélection de la devise
                  DropdownButtonFormField<String>(
                    value: _selectedCurrency,
                    decoration: const InputDecoration(
                      labelText: 'Devise',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.currency_exchange),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'USD', child: Text('Dollars')),
                      DropdownMenuItem(value: 'FC', child: Text('Francs')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCurrency = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: false,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Montant',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.money),
                    ),
                    validator: (value) {
                      final v = (value ?? '').trim();
                      if (v.isEmpty) return 'Champ obligatoire';
                      if (double.tryParse(v.replaceAll(',', '.')) == null) {
                        return 'Montant invalide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Catégorie',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _categories.map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'Note (optionnel)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.save),
                    label: const Text('Enregistrer'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
