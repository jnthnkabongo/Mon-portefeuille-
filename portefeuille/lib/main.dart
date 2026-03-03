import 'package:flutter/material.dart';
import 'package:portefeuille/pages/auth.dart';
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
      home: const LoginPage(),
    );
  }
}
