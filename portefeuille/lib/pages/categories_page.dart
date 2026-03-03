import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database.dart';
import '../theme/theme_provider.dart';
import '../widgets/user_initial_avatar.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final DatabaseService _dbService = DatabaseService();
  List<Map<String, dynamic>> _incomeCategories = [];
  List<Map<String, dynamic>> _expenseCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);

    try {
      final incomeCategories = await _dbService.getCategoriesByType('income');
      final expenseCategories = await _dbService.getCategoriesByType('expense');

      setState(() {
        _incomeCategories = incomeCategories;
        _expenseCategories = expenseCategories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _showAddEditDialog({Map<String, dynamic>? category}) async {
    final nameController = TextEditingController(text: category?['name'] ?? '');
    String selectedType = category?['type'] ?? 'expense';
    bool isEditing = category != null;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            isEditing ? 'Modifier la catégorie' : 'Ajouter une catégorie',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de la catégorie',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Type:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Revenu'),
                      value: 'income',
                      groupValue: selectedType,
                      onChanged: (value) =>
                          setState(() => selectedType = value!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Dépense'),
                      value: 'expense',
                      groupValue: selectedType,
                      onChanged: (value) =>
                          setState(() => selectedType = value!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Le nom ne peut pas être vide'),
                    ),
                  );
                  return;
                }

                try {
                  if (isEditing) {
                    await _dbService.updateCategory(category['id'], {
                      'name': name,
                      'type': selectedType,
                    });
                  } else {
                    final exists = await _dbService.categoryExists(
                      name,
                      selectedType,
                    );
                    if (exists) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cette catégorie existe déjà'),
                        ),
                      );
                      return;
                    }

                    await _dbService.insertCategory({
                      'name': name,
                      'type': selectedType,
                      'created_at': DateTime.now().millisecondsSinceEpoch,
                    });
                  }

                  Navigator.pop(context);
                  _loadCategories();
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                }
              },
              child: Text(isEditing ? 'Modifier' : 'Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCategory(Map<String, dynamic> category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Voulez-vous vraiment supprimer la catégorie "${category['name']}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _dbService.deleteCategory(category['id']);
        _loadCategories();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
        }
      }
    }
  }

  Widget _buildCategoryList(
    List<Map<String, dynamic>> categories,
    String title,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 18,
              ),
            ),
          ),
          if (categories.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Aucune catégorie'),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return ListTile(
                  title: Text(category['name']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showAddEditDialog(category: category),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteCategory(category),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Gestion des catégories",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.teal,
        elevation: 0,
        actions: const [UserInitialAvatar()],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCategories,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildCategoryList(
                      _incomeCategories,
                      'Catégories de revenus',
                      Colors.green,
                    ),
                    _buildCategoryList(
                      _expenseCategories,
                      'Catégories de dépenses',
                      Colors.red,
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: isDarkMode ? Colors.grey[700] : Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
