import 'package:flutter/material.dart';
import 'package:portefeuille/pages/main_page.dart';
import 'package:portefeuille/pages/signup.dart';
import 'package:portefeuille/services/database.dart';
import 'package:portefeuille/services/service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool biometricAvailable = false;

  final BiometricService biometricService = BiometricService();

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  /// Vérifie si la biométrie est disponible et activée
  Future<void> _checkBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('biometricEnabled') ?? true;

    if (!enabled) return;

    biometricAvailable = await biometricService.isBiometricAvailable();

    if (biometricAvailable) {
      setState(() {});
    }
  }

  /// Hash du mot de passe
  String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<void> loginWithPassword() async {
    // Afficher immédiatement le loading
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final email = emailController.text.trim();
      final password = passwordController.text;

      if (email.isEmpty || password.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Veuillez remplir tous les champs")),
        );
        setState(() => isLoading = false);
        return;
      }

      final passwordHash = hashPassword(password);
      final user = await DatabaseService().getUser(email, passwordHash);

      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setBool('biometricEnabled', true);
        final name = (user['name'] as String?)?.trim();
        if (name != null && name.isNotEmpty) {
          await prefs.setString('userName', name);
        }

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Identifiants incorrects")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur de connexion: $e")));
    }

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  /// Connexion par empreinte
  Future<void> loginWithBiometric() async {
    final success = await biometricService.authenticate();

    if (!mounted) return;

    if (success) {
      // Récupérer les informations utilisateur depuis SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 160),

              // Logo / Icône
              const Icon(
                Icons.account_balance_wallet,
                size: 90,
                color: Colors.teal,
              ),

              const SizedBox(height: 16),

              const Text(
                "Portefeuille",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                "Connectez-vous pour continuer",
                style: TextStyle(color: Colors.black54),
              ),

              const SizedBox(height: 30),

              // Carte login
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
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
                          onPressed: isLoading ? null : loginWithPassword,
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "Se connecter",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
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
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignupPage(),
                            ),
                          ),
                          child: const Text(
                            "Créer un compte",
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

              // Empreinte digitale
              if (biometricAvailable)
                Column(
                  children: [
                    const Text(
                      "Ou utilisez votre empreinte",
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 10),
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.teal.withAlpha(26),
                      child: IconButton(
                        icon: const Icon(
                          Icons.fingerprint,
                          size: 36,
                          color: Colors.teal,
                        ),
                        onPressed: loginWithBiometric,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
