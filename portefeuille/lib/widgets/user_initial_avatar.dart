import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserInitialAvatar extends StatelessWidget {
  const UserInitialAvatar({super.key});

  Future<String?> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userName');
  }

  String _initialFromName(String? name) {
    final trimmed = (name ?? '').trim();
    if (trimmed.isEmpty) return '?';

    final parts = trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final first = parts.isEmpty ? trimmed : parts.first;
    return first.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _loadUserName(),
      builder: (context, snapshot) {
        final initial = _initialFromName(snapshot.data);

        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.teal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
