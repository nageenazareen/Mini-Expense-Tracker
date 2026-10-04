import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Accounts are saved on this device only (no server).
// The password itself is never saved: we save a salted SHA-256 hash.

class AppUser {
  final String name;
  final String email;

  AppUser({required this.name, required this.email});

  String get firstName => name.trim().split(' ').first;

  String get initials {
    List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

// The user who is logged in right now (null = logged out)
AppUser? currentUser;

// Light / dark mode, saved so it is remembered
final ValueNotifier<bool> darkMode = ValueNotifier(false);

String _hash(String password, String salt) {
  return sha256.convert(utf8.encode('$salt:$password')).toString();
}

String _newSalt() {
  Random random = Random.secure();
  List<int> bytes = List.generate(16, (_) => random.nextInt(256));
  return base64Url.encode(bytes);
}

Future<Map<String, dynamic>> _readAccounts(SharedPreferences prefs) async {
  String? data = prefs.getString('accounts');
  if (data == null) return {};
  try {
    return Map<String, dynamic>.from(jsonDecode(data));
  } catch (error) {
    debugPrint('Could not read accounts: $error');
    return {};
  }
}

String normalizeEmail(String email) => email.trim().toLowerCase();

// Called once when the app starts
Future<void> loadSession() async {
  final prefs = await SharedPreferences.getInstance();
  darkMode.value = prefs.getBool('dark_mode') ?? false;

  String? email = prefs.getString('current_user');
  if (email == null) return;
  Map<String, dynamic> accounts = await _readAccounts(prefs);
  if (accounts[email] == null) return;
  currentUser = AppUser(name: accounts[email]['name'], email: email);
}

// Returns an error message, or null when sign up worked
Future<String?> signUp(String name, String email, String password) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> accounts = await _readAccounts(prefs);
    email = normalizeEmail(email);

    if (accounts.containsKey(email)) {
      return 'An account with this email already exists. Please log in.';
    }
    String salt = _newSalt();
    accounts[email] = {
      'name': name.trim(),
      'salt': salt,
      'hash': _hash(password, salt),
    };
    await prefs.setString('accounts', jsonEncode(accounts));
    await prefs.setString('current_user', email);
    currentUser = AppUser(name: name.trim(), email: email);
    return null;
  } catch (error) {
    debugPrint('Sign up failed: $error');
    return 'Something went wrong. Please try again.';
  }
}

// Returns an error message, or null when log in worked
Future<String?> logIn(String email, String password) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> accounts = await _readAccounts(prefs);
    email = normalizeEmail(email);

    Map? account = accounts[email];
    // Same message for both cases, so nobody can guess which emails exist
    if (account == null ||
        _hash(password, account['salt']) != account['hash']) {
      return 'Incorrect email or password.';
    }
    await prefs.setString('current_user', email);
    currentUser = AppUser(name: account['name'], email: email);
    return null;
  } catch (error) {
    debugPrint('Log in failed: $error');
    return 'Something went wrong. Please try again.';
  }
}

Future<void> logOut() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('current_user');
  currentUser = null;
}

Future<void> setDarkMode(bool value) async {
  darkMode.value = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('dark_mode', value);
}

// Simple checks shared by the login and sign up forms
String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) return 'Please enter your email';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
    return 'Please enter a valid email';
  }
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) return 'Please enter a password';
  if (value.length < 6) return 'Password must be at least 6 characters';
  return null;
}
