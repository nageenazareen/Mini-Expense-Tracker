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
      amountController.text = expense.amount.toStringAsFixed(0);
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

  void saveExpense() {
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
    saveExpenses();
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
      appBar: AppBar(title: Text(isEditing ? 'Edit Expense' : 'Add Expense')),
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
                  decoration: fieldStyle('Title', Icons.edit),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
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
                    double? amount = double.tryParse(value.trim());
                    if (amount == null) {
                      return 'Please enter a valid number';
                    }
                    if (amount <= 0) {
                      return 'Amount must be more than 0';
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
