import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth.dart';
import 'theme.dart';

export 'theme.dart';

List<String> categories = [
  'Food',
  'Transport',
  'Shopping',
  'Bills',
  'Health',
  'Entertainment',
  'Other',
];

class Expense {
  String title;
  double amount;
  String category;
  DateTime date;
  String note;

  Expense({
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note = '',
  });

  // Convert to a Map so we can save it as text
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  // Build an Expense back from a saved Map
  static Expense fromMap(Map<String, dynamic> map) {
    return Expense(
      title: map['title'],
      amount: (map['amount'] as num).toDouble(),
      category: map['category'],
      date: DateTime.parse(map['date']),
      note: map['note'] ?? '',
    );
  }
}

// All expenses of the logged in user are kept in this list
List<Expense> expenses = [];

// How many saved expenses could not be read (shown as a warning)
int skippedExpenses = 0;

// Every user has their own saved list
String storageKey() {
  if (currentUser == null) return 'expenses';
  return 'expenses_${currentUser!.email}';
}

// Save the list on the device.
// Returns false if saving failed, so the screen can show an error.
Future<bool> saveExpenses() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    List<String> data = [];
    for (Expense expense in expenses) {
      data.add(jsonEncode(expense.toMap()));
    }
    return await prefs.setStringList(storageKey(), data);
  } catch (error) {
    debugPrint('Could not save expenses: $error');
    return false;
  }
}

// Load the saved list of the logged in user.
// A broken entry is skipped instead of crashing the whole app.
Future<void> loadExpenses() async {
  expenses = [];
  skippedExpenses = 0;
  try {
    final prefs = await SharedPreferences.getInstance();
    List<String>? data = prefs.getStringList(storageKey());

    // Day 1 saved everything under "expenses". Give those old
    // expenses to the first user who logs in, so nothing is lost.
    if (data == null && currentUser != null) {
      data = prefs.getStringList('expenses');
      if (data != null) {
        await prefs.setStringList(storageKey(), data);
        await prefs.remove('expenses');
      }
    }

    for (String item in data ?? []) {
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

double categoryTotal(String category, {DateTime? month}) {
  double total = 0;
  for (Expense expense in expenses) {
    bool inMonth = month == null || isSameMonth(expense.date, month);
    if (expense.category == category && inMonth) {
      total = total + expense.amount;
    }
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

IconData categoryIcon(String category) {
  if (category == 'Food') return Icons.restaurant_rounded;
  if (category == 'Transport') return Icons.directions_car_rounded;
  if (category == 'Shopping') return Icons.shopping_bag_rounded;
  if (category == 'Bills') return Icons.receipt_long_rounded;
  if (category == 'Health') return Icons.favorite_rounded;
  if (category == 'Entertainment') return Icons.movie_rounded;
  return Icons.category_rounded;
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
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec'
];

// Turns a date into "5 Mar 2026"
String formatDate(DateTime date) {
  return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
}

// Turns a date into "Mar 2026"
String formatMonth(DateTime date) {
  return '${monthNames[date.month - 1]} ${date.year}';
}

// Colored rounded icon for a category
class CategoryIcon extends StatelessWidget {
  final String category;
  final double size;

  const CategoryIcon({super.key, required this.category, this.size = 44});

  @override
  Widget build(BuildContext context) {
    Color color = categoryColor(category);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(categoryIcon(category), color: color, size: size * 0.5),
    );
  }
}

// One expense row, used on the home screen and the list screen
class ExpenseTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onTap;

  const ExpenseTile({super.key, required this.expense, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CategoryIcon(category: expense.category),
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
                        style:
                            const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Text(
                  '- ${formatAmount(expense.amount)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Shown when a list has nothing in it
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: accentColor),
          ),
          const SizedBox(height: 16),
          Text(title,
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey)),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    );
  }
}
