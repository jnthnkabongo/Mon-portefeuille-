import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/number_symbols_data.dart';
import '../services/database.dart';
import '../widgets/user_initial_avatar.dart';
import 'motif_epargne_page.dart';

class SavingsPage extends StatefulWidget {
  const SavingsPage({super.key});

  @override
  State<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  final DatabaseService _databaseService = DatabaseService();
  final _amountController = TextEditingController();
  final _libelleController = TextEditingController();
  bool _isLoading = true;
  double _totalSavings = 0.0;
  double _totalSavingsDollars = 0.0;
  List<Map<String, dynamic>> _savingsHistory = [];
  List<Map<String, dynamic>> _devices = [];
  List<Map<String, dynamic>> _motifs = [];
  int? _selectedDeviceId;
  int? _selectedMotifId;
  final formatter = NumberFormat('#,###', 'fr_FR');

  @override
  void initState() {
    super.initState();
    _updateDevicesIfNeeded();
  }

  Future<void> _updateDevicesIfNeeded() async {
    try {
      // Mettre à jour les devices avec les nouveaux noms
      // await _databaseService.updateDevices();
      await _loadSavings();
    } catch (e) {
      // Si la mise à jour échoue, essayer de charger normalement
      await _loadSavings();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _libelleController.dispose();
    super.dispose();
  }

  Future<void> _loadSavings() async {
    try {
      final [savings, devices, motifs] = await Future.wait([
        _databaseService.getAllEpargne(),
        _databaseService.getAllDevices(),
        _databaseService.getAllMotifsEpargne(),
      ]);

      double total = await _databaseService.getTotalEpargne();
      double totalFranc = await _databaseService.getTotalEpargneFranc();

      setState(() {
        _totalSavings = total;
        _totalSavingsDollars = totalFranc;
        _savingsHistory = savings;
        _devices = devices;
        _motifs = motifs;
        _isLoading = false;

        // Sélectionner le premier device et motif par défaut
        if (_devices.isNotEmpty && _selectedDeviceId == null) {
          _selectedDeviceId = _devices.first['id'];
        }
        if (_motifs.isNotEmpty && _selectedMotifId == null) {
          _selectedMotifId = _motifs.first['id'];
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addSavings() async {
    final amountText = _amountController.text.trim();
    final libelle = _libelleController.text.trim();

    if (amountText.isEmpty) {
      _showMessage('Veuillez entrer un montant', Colors.orange);
      return;
    }

    if (_selectedDeviceId == null) {
      _showMessage('Veuillez sélectionner un device', Colors.orange);
      return;
    }

    if (_selectedMotifId == null) {
      _showMessage('Veuillez sélectionner un motif', Colors.orange);
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showMessage('Veuillez entrer un montant valide', Colors.orange);
      return;
    }

    try {
      await _databaseService.insertEpargne({
        'device_id': _selectedDeviceId,
        'montant': amount,
        'motif_epargne_id': _selectedMotifId,
        'libelle': libelle.isNotEmpty ? libelle : 'Versement épargne',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });

      _amountController.clear();
      _libelleController.clear();
      await _loadSavings();

      _showMessage('Versement d\'épargne ajouté avec succès', Colors.green);
      Navigator.pop(context);
    } catch (e) {
      _showMessage('Erreur lors de l\'ajout du versement: $e', Colors.red);
    }
  }

  Future<void> _deleteSavings(int id) async {
    try {
      await _databaseService.deleteEpargne(id);
      await _loadSavings();
      _showMessage('Versement supprimé avec succès', Colors.green);
    } catch (e) {
      _showMessage('Erreur lors de la suppression: $e', Colors.red);
    }
  }

  void _showDeleteSavingsDialog(Map<String, dynamic> savings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Supprimer le versement',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ce versement de ${NumberFormat.currency(symbol: 'FC ').format(savings['montant'])} ?\n\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteSavings(savings['id']);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showEditSavingsDialog(Map<String, dynamic> savings) {
    final amountController = TextEditingController(
      text: savings['montant'].toString(),
    );
    final libelleController = TextEditingController(
      text: savings['libelle']?.toString() ?? '',
    );
    int? selectedDeviceId = savings['device_id'];
    int? selectedMotifId = savings['motif_epargne_id'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text(
            'Modifier le versement',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Montant (FC / \$)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.money, color: Colors.teal),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: libelleController,
                  decoration: InputDecoration(
                    labelText: 'Libellé (optionnel)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label, color: Colors.teal),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedDeviceId,
                  decoration: InputDecoration(
                    labelText: 'Device',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.devices, color: Colors.teal),
                  ),
                  items: _devices.map((device) {
                    return DropdownMenuItem<int>(
                      value: device['id'],
                      child: Text(device['nom']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedDeviceId = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedMotifId,
                  decoration: InputDecoration(
                    labelText: 'Motif d\'épargne',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lightbulb, color: Colors.teal),
                  ),
                  items: _motifs.map((motif) {
                    return DropdownMenuItem<int>(
                      value: motif['id'],
                      child: Text(motif['nom']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedMotifId = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () async {
                final amountText = amountController.text.trim();
                final libelle = libelleController.text.trim();

                if (amountText.isEmpty) {
                  _showMessage('Veuillez entrer un montant', Colors.orange);
                  return;
                }

                if (selectedDeviceId == null) {
                  _showMessage(
                    'Veuillez sélectionner un device',
                    Colors.orange,
                  );
                  return;
                }

                if (selectedMotifId == null) {
                  _showMessage('Veuillez sélectionner un motif', Colors.orange);
                  return;
                }

                final amount = double.tryParse(amountText);
                if (amount == null || amount <= 0) {
                  _showMessage(
                    'Veuillez entrer un montant valide',
                    Colors.orange,
                  );
                  return;
                }

                try {
                  await _databaseService.updateEpargne(savings['id'], {
                    'device_id': selectedDeviceId,
                    'montant': amount,
                    'motif_epargne_id': selectedMotifId,
                    'libelle': libelle.isNotEmpty
                        ? libelle
                        : 'Versement épargne',
                  });

                  Navigator.pop(context);
                  await _loadSavings();
                  _showMessage('Versement modifié avec succès', Colors.green);
                } catch (e) {
                  _showMessage(
                    'Erreur lors de la modification: $e',
                    Colors.red,
                  );
                }
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text('Modifier'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  void _showAddSavingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Nouveau versement d\'épargne',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Montant (FC)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.money, color: Colors.teal),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _libelleController,
                decoration: InputDecoration(
                  labelText: 'Libellé (optionnel)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label, color: Colors.teal),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedDeviceId,
                decoration: InputDecoration(
                  labelText: 'Device',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.devices, color: Colors.teal),
                ),
                items: _devices.map((device) {
                  return DropdownMenuItem<int>(
                    value: device['id'],
                    child: Text(device['nom']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDeviceId = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedMotifId,
                decoration: InputDecoration(
                  labelText: 'Motif d\'épargne',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lightbulb, color: Colors.teal),
                ),
                items: _motifs.map((motif) {
                  return DropdownMenuItem<int>(
                    value: motif['id'],
                    child: Text(motif['nom']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMotifId = value;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: _addSavings,
            style: FilledButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.teal,
        elevation: 0,
        title: const Text(
          "Épargne",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MotifEpargnePage(),
                ),
              );
            },
            icon: const Icon(Icons.settings),
            tooltip: 'Gérer les motifs',
          ),
          const UserInitialAvatar(),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSavings,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Carte de total d'épargne
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.teal, Colors.teal.shade700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withAlpha(51),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.savings, color: Colors.white, size: 32),
                            const SizedBox(width: 12),
                            const Text(
                              'Total épargné',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          NumberFormat.currency(
                            symbol: 'FC ',
                          ).format(_totalSavings),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          NumberFormat.currency(
                            symbol: '\$ ',
                          ).format(_totalSavingsDollars),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Bouton d'ajout
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _showAddSavingsDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Faire un versement'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Historique des versements
                  Text(
                    'Historique des versements',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _savingsHistory.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.savings_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucun versement d\'épargne',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Commencez à épargner pour voir votre historique',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _savingsHistory.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final savings = _savingsHistory[index];
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(13),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.teal.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.savings,
                                      color: Colors.teal,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          savings['libelle']?.toString() ??
                                              'Versement épargne',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat('dd MMM yyyy').format(
                                            DateTime.fromMillisecondsSinceEpoch(
                                              savings['created_at'],
                                            ),
                                          ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          '${savings['motif_nom']} - ${savings['device_nom']}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${savings['montant']} - ${savings['device_nom']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  PopupMenuButton<String>(
                                    icon: Icon(
                                      Icons.more_vert,
                                      color: Colors.grey[600],
                                    ),
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showEditSavingsDialog(savings);
                                      } else if (value == 'delete') {
                                        _showDeleteSavingsDialog(savings);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 16),
                                            SizedBox(width: 8),
                                            Text('Modifier'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete,
                                              size: 16,
                                              color: Colors.red,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Supprimer',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }
}
