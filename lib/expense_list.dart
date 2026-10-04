import 'package:flutter/material.dart';
import 'expense.dart';
import 'add_expense.dart';

class ExpenseList extends StatefulWidget {
  // If given, the list opens filtered to this month
  final DateTime? initialMonth;

  const ExpenseList({super.key, this.initialMonth});

  @override
  State<ExpenseList> createState() => _ExpenseListState();
}

class _ExpenseListState extends State<ExpenseList> {
  String searchText = '';
  String selectedFilter = 'All';
  DateTime? selectedMonth; // null means all months
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedMonth = widget.initialMonth;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void deleteExpense(Expense expense) async {
    int index = expenses.indexOf(expense);
    setState(() {
      expenses.remove(expense);
    });
    bool saved = await saveExpenses();
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(saved
            ? '${expense.title} deleted'
            : '${expense.title} deleted, but it could not be saved on this device'),
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
    // Apply search, category and month filters
    List<Expense> filtered = [];
    double filteredTotal = 0;
    String search = searchText.trim().toLowerCase();
    for (Expense expense in expenses) {
      bool matchSearch = expense.title.toLowerCase().contains(search) ||
          expense.category.toLowerCase().contains(search);
      bool matchCategory =
          selectedFilter == 'All' || expense.category == selectedFilter;
      bool matchMonth =
          selectedMonth == null || isSameMonth(expense.date, selectedMonth!);
      if (matchSearch && matchCategory && matchMonth) {
        filtered.add(expense);
        filteredTotal = filteredTotal + expense.amount;
      }
    }

    List<String> filters = ['All', ...categories];
    List<DateTime> months = expenseMonths();
    // The chosen month may have no expenses left after a delete
    if (selectedMonth != null && !months.contains(selectedMonth)) {
      months.insert(0, selectedMonth!);
    }

    String totalLabel = 'Total';
    if (selectedFilter != 'All') totalLabel = '$totalLabel ($selectedFilter)';
    if (selectedMonth != null) {
      totalLabel = '$totalLabel - ${formatMonth(selectedMonth!)}';
    }

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
                        controller: searchController,
                        onChanged: (value) {
                          setState(() {
                            searchText = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search by title or category',
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

                    // Month filter
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: DropdownButtonFormField<DateTime?>(
                        // New key when the month changes from outside
                        // (e.g. "Clear filters"), so the dropdown updates
                        key: ValueKey(selectedMonth),
                        initialValue: selectedMonth,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.calendar_month),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<DateTime?>(
                            value: null,
                            child: Text('All months'),
                          ),
                          for (DateTime month in months)
                            DropdownMenuItem<DateTime?>(
                              value: month,
                              child: Text(formatMonth(month)),
                            ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedMonth = value;
                          });
                        },
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
                          Flexible(
                            child: Text(
                              totalLabel,
                              style: const TextStyle(fontSize: 16),
                            ),
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
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.search_off,
                                      size: 48, color: Colors.grey),
                                  const SizedBox(height: 8),
                                  const Text('No expenses match your filters.',
                                      style: TextStyle(color: Colors.grey)),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        searchText = '';
                                        selectedFilter = 'All';
                                        selectedMonth = null;
                                      });
                                      searchController.clear();
                                    },
                                    child: const Text('Clear filters'),
                                  ),
                                ],
                              ),
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
