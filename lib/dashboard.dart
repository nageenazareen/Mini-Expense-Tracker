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

  void openExpenseList() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ExpenseList()),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    double total = getTotal();
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
                  ],
                ),
              ),

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
