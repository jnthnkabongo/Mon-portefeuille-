import 'package:flutter/material.dart';
import 'package:portefeuille/pages/auth.dart';
import 'package:portefeuille/services/service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import 'package:portefeuille/services/database.dart'; // service SQLite que tu dois avoir ou créer

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool biometricAvailable = false;
  bool enableBiometric = false;

  final BiometricService biometricService = BiometricService();

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailable();
  }

  /// Vérifie si l’appareil supporte la biométrie
  Future<void> _checkBiometricAvailable() async {
    biometricAvailable = await biometricService.isBiometricAvailable();
    if (!mounted) return;
    setState(() {});
  }

  /// Hash du mot de passe
  String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<void> login() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  /// Fonction signup
  Future<void> signup() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tous les champs sont requis")),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Le mot de passe doit contenir au moins 6 caractères"),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final passwordHash = hashPassword(password);
      final db = DatabaseService();
      final database = await db.database;
      final existingUsers = await database.query(
        'users',
        columns: ['email'],
        where: 'email = ?',
        whereArgs: [email],
        limit: 1,
      );

      if (existingUsers.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cet email est déjà utilisé")),
        );
        setState(() => isLoading = false);
        return;
      }

      final userData = {'name': name, 'email': email, 'password': passwordHash};
      final userId = await db.insertUser(userData);

      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userName', name);
      prefs.setInt('Id', userId).toString();

      if (!mounted) return;

      // Si biométrie disponible, demande si l'utilisateur veut l'activer
      if (biometricAvailable) {
        if (!mounted) return;
        final enable = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Activer l'empreinte ?"),
            content: const Text(
              "Voulez-vous vous connecter plus tard avec votre empreinte digitale ?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Non"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Oui"),
              ),
            ],
          ),
        );

        if (!mounted) return;

        if (enable == true) {
          await prefs.setBool('biometricEnabled', true);
        } else {
          //print('❌ Biométrie désactivée');
        }
      }

      if (!mounted) return;
      setState(() => isLoading = false);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de l'inscription: $e")),
      );
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 160),
              const Icon(
                Icons.account_balance_wallet,
                size: 90,
                color: Colors.teal,
              ),
              const SizedBox(height: 16),
              const Text(
                "Créer un compte",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Enregistrez-vous pour accéder à votre portefeuille",
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 30),

              // Carte signup
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Nom
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: "Nom complet",
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Email
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: "Email",
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Mot de passe
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Mot de passe",
                          prefixIcon: const Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Bouton signup
                      SizedBox(
                        width: double.infinity,
                        height: 48,

                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: isLoading ? null : signup,
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "S'inscrire",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,

                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: isLoading ? null : login,
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "Connexion",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Text("Vous avez deja un compte conncetez-vous"),
              // Indication biométrie
              if (biometricAvailable)
                Text(
                  "Vous pourrez vous connecter plus tard avec votre empreinte digitale",
                  style: TextStyle(color: Colors.teal.shade400),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
