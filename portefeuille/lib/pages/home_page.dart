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

class _HomePageState extends State<HomePage> {
  final _currency = NumberFormat.currency(symbol: '');
  late Future<void> _loadFuture;
  final DatabaseService _databaseService = DatabaseService();

  List<FinanceTransaction> _items = const [];
  double _incomeTotal = 0;
  double _expenseTotal = 0;

  @override
  void initState() {
    super.initState();
    _loadFuture = _reload();
  }

  Future<void> _reload() async {
    final items = await _databaseService.getAllTransactions();
    final totals = await _databaseService.getTotals();

    if (!mounted) return;
    setState(() {
      _items = items.map((item) => FinanceTransaction.fromDbMap(item)).toList();
      _incomeTotal = totals['income'] ?? 0;
      _expenseTotal = totals['expense'] ?? 0;
    });
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

  @override
  Widget build(BuildContext context) {
    final balance = _incomeTotal - _expenseTotal;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Portefeuille',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.teal,
        elevation: 0,
        actions: const [UserInitialAvatar()],
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
                // Carte du solde
                _BalanceCard(
                  income: _incomeTotal,
                  expense: _expenseTotal,
                  balance: balance,
                  currency: _currency,
                ),
                const SizedBox(height: 20),

                // Titre
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Transactions récentes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Liste scrollable des transactions
                Expanded(
                  child: _items.isEmpty
                      ? const Center(
                          child: Text('Aucune transaction pour le moment.'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final tx = _items[index];
                            return Dismissible(
                              key: ValueKey(
                                'tx_${tx.id}_${tx.createdAt.millisecondsSinceEpoch}',
                              ),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade400,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              confirmDismiss: (direction) async {
                                return await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Supprimer'),
                                        content: const Text(
                                          'Voulez-vous supprimer cette transaction ?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(
                                              context,
                                            ).pop(false),
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
                              onDismissed: (_) => _deleteTx(tx),
                              child: _TransactionTile(
                                tx: tx,
                                currency: _currency,
                              ),
                            );
                          },
                        ),
                ),
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

/// Carte de solde
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.income,
    required this.expense,
    required this.balance,
    required this.currency,
  });

  final double income;
  final double expense;
  final double balance;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final Color balanceColor = balance > 0
        ? Colors.white
        : balance < 0
        ? Colors.red.shade700
        : Colors.grey;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [Colors.teal.shade400, Colors.teal.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
              SizedBox(width: 10),
              Text(
                'Solde',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            currency.format(balance),
            style: TextStyle(
              color: balanceColor,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            "CDF",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MiniStat(
                label: 'Revenus',
                value: currency.format(income),
                icon: Icons.arrow_downward,
                color: Colors.green.shade100,
                textColor: Colors.green.shade800,
              ),
              const SizedBox(width: 12),
              _MiniStat(
                label: 'Dépenses',
                value: currency.format(expense),
                icon: Icons.arrow_upward,
                color: Colors.red.shade100,
                textColor: Colors.red.shade800,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.textColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: textColor, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isIncome ? Colors.green.shade50 : Colors.red.shade50,
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: amountColor,
          ),
        ),
        title: Text(tx.category.isEmpty ? 'Sans catégorie' : tx.category),
        subtitle: Text(
          tx.note.isEmpty
              ? _formatDate(tx.createdAt)
              : '${tx.note} • ${_formatDate(tx.createdAt)}',
        ),
        trailing: Text(
          '$sign${currency.format(tx.amount)}',
          style: TextStyle(fontWeight: FontWeight.bold, color: amountColor),
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

  List<String> _categories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
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
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Ajouter une transaction',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
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
                        if (v.isEmpty) return 'Montant obligatoire';
                        final parsed = double.tryParse(v.replaceAll(',', '.'));
                        if (parsed == null) return 'Montant invalide';
                        if (parsed <= 0) return 'Le montant doit être > 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _isLoadingCategories
                        ? const CircularProgressIndicator()
                        : DropdownButtonFormField<String>(
                            initialValue: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Catégorie',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.category),
                            ),
                            items: _categories.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Catégorie obligatoire';
                              }
                              return null;
                            },
                          ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: 'Note (optionnel)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Enregistrer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
