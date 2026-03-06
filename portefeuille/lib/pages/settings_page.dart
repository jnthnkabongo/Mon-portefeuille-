import 'package:flutter/material.dart';
import 'package:portefeuille/pages/reset_password.dart';
import '../widgets/user_initial_avatar.dart';
import '../services/database.dart';
import 'categories_page.dart';
import 'savings_page.dart';
import 'motif_epargne_page.dart';
import 'devices_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = true;
  Map<String, List<String>> _categoriesByType = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final db = await _databaseService.database;
      final result = await db.query(
        'transactions',
        columns: ['category', 'type'],
      );

      // Extraire les catégories uniques avec leur type
      final categoriesByType = <String, List<String>>{
        'Revenus': [],
        'Dépenses': [],
      };

      for (final tx in result) {
        final category = tx['category'] as String;
        final type = tx['type'] as String;

        if (category.trim().isNotEmpty) {
          if (type == 'income') {
            if (!categoriesByType['Revenus']!.contains(category)) {
              categoriesByType['Revenus']!.add(category);
            }
          } else {
            if (!categoriesByType['Dépenses']!.contains(category)) {
              categoriesByType['Dépenses']!.add(category);
            }
          }
        }
      }

      setState(() {
        _categoriesByType = categoriesByType;
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
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.teal,
        elevation: 0,
        title: const Text(
          "Paramètres",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        actions: const [UserInitialAvatar()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionCard(
            title: "Général",
            items: const [
              SettingItem(label: "Langue", icon: Icons.language),
              SettingItem(label: "Notifications", icon: Icons.notifications),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: "Sécurité",
            items: [
              SettingItem(label: "Changer mot de passe", icon: Icons.lock),
              SettingItem(
                label: "Authentification biométrique",
                icon: Icons.fingerprint,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ResetPasswordPage(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: "Synchronisation",
            items: const [
              SettingItem(label: "Cloud Sync", icon: Icons.cloud_upload),
              SettingItem(label: "Exporter PDF", icon: Icons.picture_as_pdf),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: "Devises",
            items: [
              SettingItem(
                label: "Gérer les devises",
                icon: Icons.devices,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DevicesPage(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: "Catégories",
            items: [
              SettingItem(
                label: "Gérer les catégories",
                icon: Icons.category,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CategoriesPage(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: "Épargne",
            items: [
              SettingItem(
                label: "Versements d'épargne",
                icon: Icons.savings,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SavingsPage(),
                    ),
                  );
                },
              ),
              SettingItem(
                label: "Gérer les motifs d'épargne",
                icon: Icons.lightbulb,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MotifEpargnePage(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(String type) {
    final controller = TextEditingController();
    final isIncome = type == 'Revenus';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ajouter une catégorie - $type'),
        content: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Nom de la catégorie',
            border: OutlineInputBorder(),
            prefixIcon: Icon(
              isIncome ? Icons.trending_up : Icons.trending_down,
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              final categoryName = controller.text.trim();
              if (categoryName.isNotEmpty) {
                await _addCategoryToDatabase(
                  categoryName,
                  isIncome ? 'income' : 'expense',
                );
                Navigator.pop(context);
                _loadUsers(); // Recharger les catégories
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(String type, String oldCategory) {
    final controller = TextEditingController(text: oldCategory);
    final isIncome = type == 'Revenus';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier la catégorie - $type'),
        content: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Nouveau nom',
            border: OutlineInputBorder(),
            prefixIcon: Icon(
              isIncome ? Icons.trending_up : Icons.trending_down,
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              final newCategoryName = controller.text.trim();
              if (newCategoryName.isNotEmpty &&
                  newCategoryName != oldCategory) {
                await _updateCategoryInDatabase(
                  oldCategory,
                  newCategoryName,
                  isIncome ? 'income' : 'expense',
                );
                Navigator.pop(context);
                _loadUsers(); // Recharger les catégories
              }
            },
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  void _showDeleteCategoryDialog(String type, String category) {
    final isIncome = type == 'Revenus';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer la catégorie - $type'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer la catégorie "$category" ?\n\nAttention : cette action ne supprimera pas les transactions existantes avec cette catégorie.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              await _deleteCategoryFromTransactions(
                category,
                isIncome ? 'income' : 'expense',
              );
              Navigator.pop(context);
              _loadUsers(); // Recharger les catégories
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _addCategoryToDatabase(String categoryName, String type) async {
    try {
      // Créer une transaction fictive avec la nouvelle catégorie pour l'ajouter à la base
      final db = await _databaseService.database;
      await db.insert('transactions', {
        'type': type,
        'amount': 0.0,
        'category': categoryName,
        'note': 'Catégorie ajoutée',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });

      // Supprimer immédiatement la transaction fictive
      await db.delete(
        'transactions',
        where: 'category = ? AND amount = 0 AND note = ?',
        whereArgs: [categoryName, 'Catégorie ajoutée'],
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Catégorie "$categoryName" ajoutée avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'ajout de la catégorie: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateCategoryInDatabase(
    String oldCategory,
    String newCategory,
    String type,
  ) async {
    try {
      final db = await _databaseService.database;
      await db.update(
        'transactions',
        {'category': newCategory},
        where: 'category = ? AND type = ?',
        whereArgs: [oldCategory, type],
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Catégorie renommée en "$newCategory"'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la modification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteCategoryFromTransactions(
    String category,
    String type,
  ) async {
    try {
      final db = await _databaseService.database;

      // Optionnel : Supprimer ou mettre à jour les transactions avec cette catégorie
      // Ici on les met à jour avec "Sans catégorie"
      await db.update(
        'transactions',
        {'category': 'Sans catégorie'},
        where: 'category = ? AND type = ?',
        whereArgs: [category, type],
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Catégorie "$category" supprimée'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSectionCard({
    required String title,
    required List<SettingItem> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(item.icon, color: Colors.teal),
              title: Text(item.label),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: item.onTap,
            ),
          ),
        ],
      ),
    );
  }
}

class SettingItem {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const SettingItem({required this.label, required this.icon, this.onTap});
}
