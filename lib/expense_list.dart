import 'package:flutter/material.dart';
import 'expense.dart';
import 'add_expense.dart';

class ExpenseList extends StatefulWidget {
  const ExpenseList({super.key});

  @override
  State<ExpenseList> createState() => _ExpenseListState();
}

class _ExpenseListState extends State<ExpenseList> {
  String searchText = '';
  String selectedFilter = 'All';

  void deleteExpense(Expense expense) {
    int index = expenses.indexOf(expense);
    setState(() {
      expenses.remove(expense);
    });
    saveExpenses();

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${expense.title} deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            expenses.insert(index, expense);
            saveExpenses();
            if (mounted) setState(() {});
          },
        ),
      ),
    );
  }

  void openEditExpense(Expense expense) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddExpense(expense: expense)),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Apply search and category filter
    List<Expense> filtered = [];
    double filteredTotal = 0;
    for (Expense expense in expenses) {
      bool matchSearch =
          expense.title.toLowerCase().contains(searchText.toLowerCase());
      bool matchCategory =
          selectedFilter == 'All' || expense.category == selectedFilter;
      if (matchSearch && matchCategory) {
        filtered.add(expense);
        filteredTotal = filteredTotal + expense.amount;
      }
    }

    List<String> filters = ['All', ...categories];

    return Scaffold(
      appBar: AppBar(title: const Text('All Expenses')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: expenses.isEmpty
              ? const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.account_balance_wallet_outlined,
                        size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('Your spending list is empty.',
                        style: TextStyle(fontSize: 16, color: Colors.grey)),
                  ],
                )
              : Column(
                  children: [
                    // Search box
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            searchText = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search expenses',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),

                    // Category filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: filters.map((filter) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(filter),
                              showCheckmark: false,
                              selected: selectedFilter == filter,
                              selectedColor: lightAccent,
                              onSelected: (selected) {
                                setState(() {
                                  selectedFilter = filter;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // Total of the shown expenses
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: lightAccent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedFilter == 'All'
                                ? 'Total'
                                : 'Total ($selectedFilter)',
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            formatAmount(filteredTotal),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text('Tap to edit • Swipe left to delete',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),

                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Text('No expenses match your search.',
                                  style: TextStyle(color: Colors.grey)),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                Expense expense = filtered[index];
                                return Dismissible(
                                  key: ObjectKey(expense),
                                  direction: DismissDirection.endToStart,
                                  onDismissed: (direction) =>
                                      deleteExpense(expense),
                                  background: Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.only(right: 20),
                                    alignment: Alignment.centerRight,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(Icons.delete,
                                        color: Colors.white),
                                  ),
                                  child: ExpenseTile(
                                    expense: expense,
                                    onTap: () => openEditExpense(expense),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
