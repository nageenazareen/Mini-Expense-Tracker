import 'package:flutter/material.dart';
import 'expense.dart';
import 'add_expense.dart';
import 'expense_list.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  // Small label + amount used inside the total card
  Widget monthStat(String label, double amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 4),
        Text(
          formatAmount(amount),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void openAddExpense() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddExpense()),
    );
    // Refresh the screen when we come back
    setState(() {});
  }

  void openEditExpense(Expense expense) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddExpense(expense: expense)),
    );
    setState(() {});
  }

  void openExpenseList({DateTime? month}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ExpenseList(initialMonth: month)),
    );
    setState(() {});
  }

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

  @override
  Widget build(BuildContext context) {
    double total = getTotal();
    DateTime now = DateTime.now();
    double thisMonth = monthTotal(now);
    double lastMonth = monthTotal(DateTime(now.year, now.month - 1));
    // Show at most 6 months in the monthly section
    List<DateTime> months = expenseMonths().take(6).toList();
    // Show only the 5 newest expenses here
    List<Expense> recent = expenses.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          children: [
            Text('Spendly', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Track your spending',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      ),
      // maxWidth keeps the layout neat on big screens (web/desktop)
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              // Total card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Spent',
                        style: TextStyle(color: Colors.white70, fontSize: 15)),
                    const SizedBox(height: 8),
                    Text(
                      formatAmount(total),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      expenses.length == 1
                          ? '1 expense added'
                          : '${expenses.length} expenses added',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const Divider(color: Colors.white24, height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: monthStat('This Month', thisMonth),
                        ),
                        Expanded(
                          child: monthStat('Last Month', lastMonth),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Monthly totals
              if (months.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text('Monthly Totals',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      for (DateTime month in months)
                        ListTile(
                          leading: const Icon(Icons.calendar_month,
                              color: accentColor),
                          title: Text(formatMonth(month)),
                          trailing: Text(
                            formatAmount(monthTotal(month)),
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          // Open the list already filtered to this month
                          onTap: () => openExpenseList(month: month),
                        ),
                    ],
                  ),
                ),
              ],

              // Spending by category
              if (total > 0) ...[
                const SizedBox(height: 24),
                const Text('Spending by Category',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      for (String category in categories)
                        if (categoryTotal(category) > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(categoryIcon(category),
                                        size: 18, color: accentColor),
                                    const SizedBox(width: 8),
                                    Text(category),
                                    const Spacer(),
                                    Text(
                                      formatAmount(categoryTotal(category)),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: categoryTotal(category) / total,
                                    minHeight: 8,
                                    color: accentColor,
                                    backgroundColor: lightAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                    ],
                  ),
                ),
              ],

              // Recent expenses
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Expenses',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: openExpenseList,
                    child: const Text('See all'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (recent.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(
                    child: Text('No expenses yet. Tap + to add one.',
                        style: TextStyle(color: Colors.grey)),
                  ),
                ),
              for (Expense expense in recent)
                ExpenseTile(
                  expense: expense,
                  onTap: () => openEditExpense(expense),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openAddExpense,
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }
}
