import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:portefeuille/pages/auth.dart';
import 'package:portefeuille/pages/onboarding_page.dart';
import 'package:provider/provider.dart';
import 'theme/theme_provider.dart';
import 'theme/theme.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FinancePro',
      themeMode: themeProvider.themeMode,
      theme: lightTheme,
      darkTheme: darkTheme,
      home: FutureBuilder<bool>(
        future: _checkOnboardingStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final onboardingCompleted = snapshot.data ?? false;
          return onboardingCompleted
              ? const LoginPage()
              : const OnboardingPage();
        },
      ),
      routes: {
        '/auth': (context) => const LoginPage(),
        '/onboarding': (context) => const OnboardingPage(),
      },
    );
  }

  Future<bool> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed') ?? false;
  }
}
