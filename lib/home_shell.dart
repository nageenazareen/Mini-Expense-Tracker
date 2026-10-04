import 'package:flutter/material.dart';
import 'add_expense.dart';
import 'dashboard.dart';
import 'expense.dart';
import 'expense_list.dart';
import 'profile_screen.dart';
import 'stats_screen.dart';

// The main screen after login: 4 tabs with a bottom navigation bar
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int selectedTab = 0;
  DateTime? listMonth; // month filter used when opening the Expenses tab

  @override
  void initState() {
    super.initState();
    // Tell the user if some saved data could not be read
    if (skippedExpenses > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(skippedExpenses == 1
                ? '1 saved expense could not be loaded and was skipped.'
                : '$skippedExpenses saved expenses could not be loaded and were skipped.'),
          ),
        );
      });
    }
  }

  void openAddExpense() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddExpense()),
    );
    setState(() {});
  }

  void openEditExpense(Expense expense) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddExpense(expense: expense)),
    );
    setState(() {});
  }

  // Used by "See all" and the monthly list on the home tab
  void openExpensesTab({DateTime? month}) {
    setState(() {
      listMonth = month;
      selectedTab = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (selectedTab == 0) {
      body = Dashboard(
        onAdd: openAddExpense,
        onEdit: openEditExpense,
        onSeeAll: openExpensesTab,
      );
    } else if (selectedTab == 1) {
      body = ExpenseList(
        // New key when the month changes, so the filters start fresh
        key: ValueKey(listMonth),
        initialMonth: listMonth,
        onEdit: openEditExpense,
        onChanged: () => setState(() {}),
      );
    } else if (selectedTab == 2) {
      body = const StatsScreen();
    } else {
      body = ProfileScreen(onDataChanged: () => setState(() {}));
    }

    return Scaffold(
      body: SafeArea(child: body),
      floatingActionButton: selectedTab < 2
          ? FloatingActionButton.extended(
              onPressed: openAddExpense,
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab,
        onDestinationSelected: (index) {
          setState(() {
            selectedTab = index;
            listMonth = null;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: accentColor),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded, color: accentColor),
            label: 'Expenses',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline_rounded),
            selectedIcon: Icon(Icons.pie_chart_rounded, color: accentColor),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: accentColor),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
