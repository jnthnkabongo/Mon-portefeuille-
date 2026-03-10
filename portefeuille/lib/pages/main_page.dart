import 'package:flutter/material.dart';
import 'package:portefeuille/pages/statistiques_page.dart';
import 'home_page.dart';
import 'package:portefeuille/pages/historiques.dart';
import 'profile_page.dart';
import 'settings_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;

  final _pages = const [
    HomePage(),
    StatsPage(),
    HistoryPage(),
    ProfilePage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Page affichée
          IndexedStack(index: _index, children: _pages),

          /// NAVIGATION FLOTTANTE
          Positioned(
            left: 12,
            right: 12,
            bottom: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(31),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceAround, // <-- répartit les items
                children: [
                  _navItem(icon: Icons.home, label: "Accueil", index: 0),
                  _navItem(
                    icon: Icons.bar_chart,
                    label: "Statistique",
                    index: 1,
                  ),
                  _navItem(icon: Icons.history, label: "Historiques", index: 2),
                  _navItem(icon: Icons.person, label: "Profil", index: 3),
                  _navItem(icon: Icons.settings, label: "Paramètres", index: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _index == index;
    final color = isSelected ? Colors.teal : Colors.grey;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _index = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
