import 'package:flutter/material.dart';
import 'auth.dart';
import 'expense.dart';
import 'home_shell.dart';
import 'login_screen.dart';

void main() async {
  // Needed before using SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();
  await loadSession();
  if (currentUser != null) {
    await loadExpenses();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild the app when dark mode is switched on or off
    return ValueListenableBuilder<bool>(
      valueListenable: darkMode,
      builder: (context, isDark, _) {
        return MaterialApp(
          title: 'Spendly',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          // Skip the login screen if the user is still logged in
          home: currentUser == null ? const LoginScreen() : const HomeShell(),
        );
      },
    );
  }
}
