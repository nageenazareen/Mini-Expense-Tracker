import 'package:flutter/material.dart';
import 'expense.dart';

// This screen is used for both adding and editing.
// If an expense is passed in, we are editing it.
class AddExpense extends StatefulWidget {
  final Expense? expense;

  const AddExpense({super.key, this.expense});

  @override
  State<AddExpense> createState() => _AddExpenseState();
}

class _AddExpenseState extends State<AddExpense> {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final amountController = TextEditingController();
  final dateController = TextEditingController();

  String? selectedCategory;
  DateTime? selectedDate;

  bool get isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    // Fill the form with old values when editing
    if (widget.expense != null) {
      Expense expense = widget.expense!;
      titleController.text = expense.title;
      // Keep decimals like 99.50 instead of rounding them away
      amountController.text = expense.amount == expense.amount.roundToDouble()
          ? expense.amount.toStringAsFixed(0)
          : expense.amount.toStringAsFixed(2);
      selectedCategory = expense.category;
      selectedDate = expense.date;
      dateController.text = formatDate(expense.date);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    dateController.dispose();
    super.dispose();
  }

  void pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        dateController.text = formatDate(picked);
      });
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void saveExpense() async {
    if (!formKey.currentState!.validate()) return;

    String title = titleController.text.trim();
    double amount = double.parse(amountController.text.trim());

    if (isEditing) {
      widget.expense!.title = title;
      widget.expense!.amount = amount;
      widget.expense!.category = selectedCategory!;
      widget.expense!.date = selectedDate!;
    } else {
      expenses.add(Expense(
        title: title,
        amount: amount,
        category: selectedCategory!,
        date: selectedDate!,
      ));
    }

    // Keep newest expenses at the top, then save
    expenses.sort((a, b) => b.date.compareTo(a.date));
    bool saved = await saveExpenses();
    if (!mounted) return;
    if (!saved) {
      showError('Could not save on this device. Please try again.');
    }
    Navigator.pop(context);
  }

  // Ask before deleting, because this cannot be undone from here
  void confirmDelete() async {
    bool? yes = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete expense?'),
          content: Text('"${widget.expense!.title}" will be removed.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (yes != true) return;

    expenses.remove(widget.expense);
    bool saved = await saveExpenses();
    if (!mounted) return;
    if (!saved) {
      showError('Could not save on this device. Please try again.');
    }
    Navigator.pop(context);
  }

  // Same look for every text field
  InputDecoration fieldStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Expense' : 'Add Expense'),
        actions: [
          if (isEditing)
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: confirmDelete,
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: titleController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 40,
                  decoration: fieldStyle('Title', Icons.edit),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    if (value.trim().length < 2) {
                      return 'Title must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: fieldStyle('Amount (Rs.)', Icons.payments),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an amount';
                    }
                    // Only digits, with at most 2 digits after the dot.
                    // This also blocks "-5", "1e5", "NaN" and "Infinity".
                    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(value.trim())) {
                      return 'Enter a number like 500 or 99.50';
                    }
                    double amount = double.parse(value.trim());
                    if (amount <= 0) {
                      return 'Amount must be more than 0';
                    }
                    if (amount > 10000000) {
                      return 'Amount cannot be more than Rs. 10,000,000';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: dateController,
                  readOnly: true,
                  onTap: pickDate,
                  decoration: fieldStyle('Date', Icons.calendar_today),
                  validator: (value) {
                    if (selectedDate == null) {
                      return 'Please select a date';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Category chips with validation
                FormField<String>(
                  initialValue: selectedCategory,
                  validator: (value) {
                    if (selectedCategory == null) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                  builder: (field) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Category',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: categories.map((category) {
                            return ChoiceChip(
                              avatar: Icon(categoryIcon(category), size: 18),
                              label: Text(category),
                              showCheckmark: false,
                              selected: selectedCategory == category,
                              selectedColor: lightAccent,
                              onSelected: (selected) {
                                setState(() {
                                  selectedCategory = category;
                                });
                                field.didChange(category);
                              },
                            );
                          }).toList(),
                        ),
                        if (field.hasError)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, left: 4),
                            child: Text(
                              field.errorText!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: saveExpense,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(isEditing ? 'Update Expense' : 'Save Expense',
                        style: const TextStyle(fontSize: 16)),
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
