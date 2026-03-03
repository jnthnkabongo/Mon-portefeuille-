import 'package:flutter/material.dart';
import '../services/database.dart';
import '../widgets/user_initial_avatar.dart';

class MotifEpargnePage extends StatefulWidget {
  const MotifEpargnePage({super.key});

  @override
  State<MotifEpargnePage> createState() => _MotifEpargnePageState();
}

class _MotifEpargnePageState extends State<MotifEpargnePage> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _motifs = [];

  @override
  void initState() {
    super.initState();
    _loadMotifs();
  }

  Future<void> _loadMotifs() async {
    try {
      final motifs = await _databaseService.getAllMotifsEpargne();
      setState(() {
        _motifs = motifs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAddMotifDialog() {
    final nomController = TextEditingController();
    final motifController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Ajouter un motif d\'épargne',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomController,
              decoration: InputDecoration(
                labelText: 'Nom du motif',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label, color: Colors.teal),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: motifController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description, color: Colors.teal),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              final nom = nomController.text.trim();
              final motif = motifController.text.trim();

              if (nom.isEmpty) {
                _showMessage('Veuillez entrer un nom', Colors.orange);
                return;
              }

              try {
                await _databaseService.insertMotifEpargne({
                  'nom': nom,
                  'motif': motif.isNotEmpty ? motif : 'Aucune description',
                });

                Navigator.pop(context);
                await _loadMotifs();
                _showMessage('Motif ajouté avec succès', Colors.green);
              } catch (e) {
                _showMessage('Erreur: $e', Colors.red);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _showEditMotifDialog(Map<String, dynamic> motif) {
    final nomController = TextEditingController(text: motif['nom']);
    final motifController = TextEditingController(text: motif['motif']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Modifier le motif',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomController,
              decoration: InputDecoration(
                labelText: 'Nom du motif',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label, color: Colors.teal),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: motifController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description, color: Colors.teal),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              final nom = nomController.text.trim();
              final description = motifController.text.trim();

              if (nom.isEmpty) {
                _showMessage('Veuillez entrer un nom', Colors.orange);
                return;
              }

              try {
                await _databaseService.updateMotifEpargne(motif['id'], {
                  'nom': nom,
                  'motif': description.isNotEmpty ? description : 'Aucune description',
                });

                Navigator.pop(context);
                await _loadMotifs();
                _showMessage('Motif modifié avec succès', Colors.green);
              } catch (e) {
                _showMessage('Erreur: $e', Colors.red);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  void _showDeleteMotifDialog(Map<String, dynamic> motif) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Supprimer le motif',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le motif "${motif['nom']}\' ?\n\nAttention : cette action pourrait affecter les versements d\'épargne existants.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await _databaseService.deleteMotifEpargne(motif['id']);
                Navigator.pop(context);
                await _loadMotifs();
                _showMessage('Motif supprimé avec succès', Colors.green);
              } catch (e) {
                _showMessage('Erreur: $e', Colors.red);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
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
          "Motifs d'épargne",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        actions: const [UserInitialAvatar()],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMotifs,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Bouton d'ajout
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _showAddMotifDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter un motif'),
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
                  // Liste des motifs
                  Text(
                    'Liste des motifs',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _motifs.isEmpty
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
                                Icons.label_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucun motif d\'épargne',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Ajoutez des motifs pour organiser vos versements',
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
                          itemCount: _motifs.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final motif = _motifs[index];
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
                                      Icons.label,
                                      color: Colors.teal,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          motif['nom'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        if (motif['motif'] != null && motif['motif'].toString().isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(
                                              motif['motif'],
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showEditMotifDialog(motif);
                                      } else if (value == 'delete') {
                                        _showDeleteMotifDialog(motif);
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
                                            Icon(Icons.delete, size: 16, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Supprimer', style: TextStyle(color: Colors.red)),
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
