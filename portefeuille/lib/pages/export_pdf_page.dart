import 'package:flutter/material.dart';
import '../widgets/user_initial_avatar.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "À propos",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: const [UserInitialAvatar()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAppInfoCard(),
          const SizedBox(height: 24),
          _buildDeveloperCard(),
        ],
      ),
    );
  }

  Widget _buildAppInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Infos de l'application",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Text("Nom : FinancePro"),
          Text("Version : 1.0.0"),
          Text("Licence : MIT"),
          Text(
            "Description : Gestion moderne de vos finances avec synchronisation cloud et export PDF.",
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Développeur",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Text("Jonathan Kabongo"),
          Text("Email : jonathan.k@example.com"),
          Text("Site web : www.example.com"),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(13),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}
