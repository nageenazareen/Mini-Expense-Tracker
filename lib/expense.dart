import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Main colors used in the whole app
const Color accentColor = Color(0xFF0F766E);
const Color lightAccent = Color(0xFFE6F4F1);

List<String> categories = ['Food', 'Transport', 'Shopping', 'Bills', 'Other'];

class Expense {
  String title;
  double amount;
  String category;
  DateTime date;

  Expense({
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
  });

  // Convert to a Map so we can save it as text
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
    };
  }

  // Build an Expense back from a saved Map
  static Expense fromMap(Map<String, dynamic> map) {
    return Expense(
      title: map['title'],
      amount: (map['amount'] as num).toDouble(),
      category: map['category'],
      date: DateTime.parse(map['date']),
    );
  }
}

// All expenses are kept in this list
List<Expense> expenses = [];

// Save the list on the device
Future<void> saveExpenses() async {
  final prefs = await SharedPreferences.getInstance();
  List<String> data = [];
  for (Expense expense in expenses) {
    data.add(jsonEncode(expense.toMap()));
  }
  await prefs.setStringList('expenses', data);
}

// Load the saved list when the app starts
Future<void> loadExpenses() async {
  final prefs = await SharedPreferences.getInstance();
  List<String> data = prefs.getStringList('expenses') ?? [];
  expenses = [];
  for (String item in data) {
    expenses.add(Expense.fromMap(jsonDecode(item)));
  }
}

double getTotal() {
  double total = 0;
  for (Expense expense in expenses) {
    total = total + expense.amount;
  }
  return total;
}

double categoryTotal(String category) {
  double total = 0;
  for (Expense expense in expenses) {
    if (expense.category == category) {
      total = total + expense.amount;
    }
  }
  return total;
}

IconData categoryIcon(String category) {
  if (category == 'Food') return Icons.restaurant;
  if (category == 'Transport') return Icons.directions_car;
  if (category == 'Shopping') return Icons.shopping_bag;
  if (category == 'Bills') return Icons.receipt_long;
  return Icons.category;
}

// Turns 12500 into "Rs. 12,500"
String formatAmount(double amount) {
  String number = amount.toStringAsFixed(0);
  String result = '';
  int count = 0;
  for (int i = number.length - 1; i >= 0; i--) {
    result = number[i] + result;
    count++;
    if (count % 3 == 0 && i != 0) {
      result = ',$result';
    }
  }
  return 'Rs. $result';
}

// Turns a date into "5 Mar 2026"
String formatDate(DateTime date) {
  List<String> months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

// One expense row, used on the dashboard and the list screen
class ExpenseTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onTap;

  const ExpenseTile({super.key, required this.expense, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: lightAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(categoryIcon(expense.category), color: accentColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${expense.category} • ${formatDate(expense.date)}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Text(
              formatAmount(expense.amount),
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
