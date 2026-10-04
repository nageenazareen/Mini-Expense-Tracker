import 'package:flutter/material.dart';
import 'expense.dart';

// Expenses tab: search, filters, total and the full list grouped by day
class ExpenseList extends StatefulWidget {
  // If given, the list opens filtered to this month
  final DateTime? initialMonth;
  final void Function(Expense expense) onEdit;
  // Called after a delete or undo, so the other tabs can refresh
  final VoidCallback onChanged;

  const ExpenseList({
    super.key,
    this.initialMonth,
    required this.onEdit,
    required this.onChanged,
  });

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
    widget.onChanged();
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
            widget.onChanged();
          },
        ),
      ),
    );
  }

  void clearFilters() {
    setState(() {
      searchText = '';
      selectedFilter = 'All';
      selectedMonth = null;
    });
    searchController.clear();
  }

  // "Today", "Yesterday" or "5 Mar 2026"
  String dayLabel(DateTime date) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime day = DateTime(date.year, date.month, date.day);
    if (day == today) return 'Today';
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return formatDate(date);
  }

  @override
  Widget build(BuildContext context) {
    // Apply search, category and month filters
    List<Expense> filtered = [];
    double filteredTotal = 0;
    String search = searchText.trim().toLowerCase();
    for (Expense expense in expenses) {
      bool matchSearch = expense.title.toLowerCase().contains(search) ||
          expense.category.toLowerCase().contains(search) ||
          expense.note.toLowerCase().contains(search);
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
    bool hasFilters =
        search.isNotEmpty || selectedFilter != 'All' || selectedMonth != null;

    // Build the list with a date header before each new day
    List<Widget> rows = [];
    String? lastDay;
    for (Expense expense in filtered) {
      String day = dayLabel(expense.date);
      if (day != lastDay) {
        rows.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text(day,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.grey)),
        ));
        lastDay = day;
      }
      rows.add(Dismissible(
        key: ObjectKey(expense),
        direction: DismissDirection.endToStart,
        onDismissed: (direction) => deleteExpense(expense),
        background: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.only(right: 20),
          alignment: Alignment.centerRight,
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.delete_rounded, color: Colors.white),
        ),
        child: ExpenseTile(
          expense: expense,
          onTap: () => widget.onEdit(expense),
        ),
      ));
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverList.list(
                children: [
                  const Text('Expenses',
                      style:
                          TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // Search box
                  TextField(
                    controller: searchController,
                    onChanged: (value) {
                      setState(() {
                        searchText = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search title, category or note',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchText.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                searchController.clear();
                                setState(() {
                                  searchText = '';
                                });
                              },
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Month filter
                  DropdownButtonFormField<DateTime?>(
                    // New key when the month changes from outside
                    // (e.g. "Clear filters"), so the dropdown updates
                    key: ValueKey(selectedMonth),
                    initialValue: selectedMonth,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.calendar_month_rounded),
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
                ],
              ),
            ),

            // Category filter chips
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: filters.map((filter) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: filter == 'All'
                            ? null
                            : Icon(categoryIcon(filter),
                                size: 18, color: categoryColor(filter)),
                        label: Text(filter),
                        showCheckmark: false,
                        selected: selectedFilter == filter,
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
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              sliver: SliverList.list(
                children: [
                  // Total of the shown expenses
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: brandGradient,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hasFilters ? 'Filtered total' : 'Total spent',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              Text(
                                filtered.length == 1
                                    ? '1 expense'
                                    : '${filtered.length} expenses',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatAmount(filteredTotal),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (filtered.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text('Tap to edit • Swipe left to delete',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ),

                  if (expenses.isEmpty)
                    const EmptyState(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Your list is empty',
                      message: 'Tap "Add Expense" to record your first one.',
                    )
                  else if (filtered.isEmpty)
                    EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No matches',
                      message: 'No expenses match your search or filters.',
                      action: TextButton(
                        onPressed: clearFilters,
                        child: const Text('Clear filters'),
                      ),
                    ),
                  ...rows,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
