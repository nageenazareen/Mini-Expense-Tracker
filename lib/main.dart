import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'expense.dart';

void main() async {
  // Needed before using SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();
  await loadExpenses();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spendly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: accentColor),
        scaffoldBackgroundColor: const Color(0xFFF5F6F8),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F6F8),
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
        ),
      ),
      home: const Dashboard(),
    );
  }
}
