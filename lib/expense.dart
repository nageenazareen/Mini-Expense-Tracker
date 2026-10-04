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

// How many saved expenses could not be read (shown as a warning on start)
int skippedExpenses = 0;

// Save the list on the device.
// Returns false if saving failed, so the screen can show an error.
Future<bool> saveExpenses() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    List<String> data = [];
    for (Expense expense in expenses) {
      data.add(jsonEncode(expense.toMap()));
    }
    return await prefs.setStringList('expenses', data);
  } catch (error) {
    debugPrint('Could not save expenses: $error');
    return false;
  }
}

// Load the saved list when the app starts.
// A broken entry is skipped instead of crashing the whole app.
Future<void> loadExpenses() async {
  expenses = [];
  skippedExpenses = 0;
  try {
    final prefs = await SharedPreferences.getInstance();
    List<String> data = prefs.getStringList('expenses') ?? [];
    for (String item in data) {
      try {
        expenses.add(Expense.fromMap(jsonDecode(item)));
      } catch (error) {
        skippedExpenses++;
        debugPrint('Skipped a broken expense: $error');
      }
    }
  } catch (error) {
    debugPrint('Could not load expenses: $error');
  }
  expenses.sort((a, b) => b.date.compareTo(a.date));
}

double getTotal() {
  double total = 0;
  for (Expense expense in expenses) {
    total = total + expense.amount;
  }
  return total;
}

// Total of one month, e.g. monthTotal(DateTime(2026, 10))
double monthTotal(DateTime month) {
  double total = 0;
  for (Expense expense in expenses) {
    if (isSameMonth(expense.date, month)) {
      total = total + expense.amount;
    }
  }
  return total;
}

bool isSameMonth(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month;
}

// All months that have at least one expense, newest first
List<DateTime> expenseMonths() {
  List<DateTime> months = [];
  for (Expense expense in expenses) {
    DateTime month = DateTime(expense.date.year, expense.date.month);
    if (!months.contains(month)) {
      months.add(month);
    }
  }
  months.sort((a, b) => b.compareTo(a));
  return months;
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

// Turns 12500 into "Rs. 12,500" and 99.5 into "Rs. 99.50"
String formatAmount(double amount) {
  String fixed = amount.toStringAsFixed(2);
  String number = fixed.substring(0, fixed.length - 3);
  String decimals = fixed.substring(fixed.length - 3);
  String result = '';
  int count = 0;
  for (int i = number.length - 1; i >= 0; i--) {
    result = number[i] + result;
    count++;
    if (count % 3 == 0 && i != 0) {
      result = ',$result';
    }
  }
  if (decimals == '.00') decimals = '';
  return 'Rs. $result$decimals';
}

const List<String> monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

// Turns a date into "5 Mar 2026"
String formatDate(DateTime date) {
  return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
}

// Turns a date into "Mar 2026"
String formatMonth(DateTime date) {
  return '${monthNames[date.month - 1]} ${date.year}';
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
