import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:spendly/add_expense.dart';
import 'package:spendly/expense.dart';
import 'package:spendly/main.dart';

void main() {
  // Start every test with an empty, fake device storage
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    expenses = [];
  });

  group('helpers', () {
    test('formatAmount adds commas and keeps decimals', () {
      expect(formatAmount(12500), 'Rs. 12,500');
      expect(formatAmount(1000000), 'Rs. 1,000,000');
      expect(formatAmount(99.5), 'Rs. 99.50');
      expect(formatAmount(0), 'Rs. 0');
    });

    test('monthTotal only counts the chosen month', () {
      expenses = [
        Expense(title: 'Lunch', amount: 500, category: 'Food', date: DateTime(2026, 10, 2)),
        Expense(title: 'Bus', amount: 100, category: 'Transport', date: DateTime(2026, 10, 20)),
        Expense(title: 'Shoes', amount: 3000, category: 'Shopping', date: DateTime(2026, 9, 15)),
      ];
      expect(monthTotal(DateTime(2026, 10)), 600);
      expect(monthTotal(DateTime(2026, 9)), 3000);
      expect(monthTotal(DateTime(2026, 8)), 0);
      expect(getTotal(), 3600);
      expect(categoryTotal('Food'), 500);
      expect(expenseMonths(), [DateTime(2026, 10), DateTime(2026, 9)]);
    });

    test('save and load keep the same expenses', () async {
      expenses = [
        Expense(title: 'Tea', amount: 80.5, category: 'Food', date: DateTime(2026, 10, 1)),
      ];
      expect(await saveExpenses(), isTrue);
      expenses = [];
      await loadExpenses();
      expect(expenses.length, 1);
      expect(expenses.first.title, 'Tea');
      expect(expenses.first.amount, 80.5);
    });

    test('a broken saved entry is skipped instead of crashing', () async {
      SharedPreferences.setMockInitialValues({
        'expenses': [
          '{"title":"Ok","amount":10,"category":"Food","date":"2026-10-01T00:00:00.000"}',
          'this is not json',
        ],
      });
      await loadExpenses();
      expect(expenses.length, 1);
      expect(skippedExpenses, 1);
    });
  });

  group('screens', () {
    testWidgets('empty dashboard shows the empty state', (tester) async {
      await tester.pumpWidget(const MyApp());
      // Total, This Month and Last Month are all zero
      expect(find.text('Rs. 0'), findsNWidgets(3));
      expect(find.text('No expenses yet. Tap + to add one.'), findsOneWidget);
    });

    testWidgets('saving an empty form shows validation errors', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AddExpense()));
      await tester.ensureVisible(find.text('Save Expense'));
      await tester.tap(find.text('Save Expense'));
      await tester.pump();

      expect(find.text('Please enter a title'), findsOneWidget);
      expect(find.text('Please enter an amount'), findsOneWidget);
      expect(find.text('Please select a date'), findsOneWidget);
      expect(find.text('Please select a category'), findsOneWidget);
      expect(expenses, isEmpty);
    });

    testWidgets('bad amounts are rejected', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AddExpense()));
      Finder amountField = find.byType(TextFormField).at(1);

      for (String bad in ['-500', 'abc', '0', '1e5', '10.999', '20000000']) {
        await tester.enterText(amountField, bad);
        await tester.ensureVisible(find.text('Save Expense'));
        await tester.tap(find.text('Save Expense'));
        await tester.pump();
        expect(find.textContaining(RegExp('Enter a number|more than 0|cannot be more')),
            findsOneWidget,
            reason: '"$bad" should be rejected');
      }
    });

    testWidgets('editing an expense updates it', (tester) async {
      Expense expense = Expense(
          title: 'Lunch', amount: 500, category: 'Food', date: DateTime(2026, 10, 2));
      expenses = [expense];

      await tester.pumpWidget(MaterialApp(home: AddExpense(expense: expense)));
      await tester.enterText(find.byType(TextFormField).first, 'Dinner');
      await tester.enterText(find.byType(TextFormField).at(1), '750.25');
      await tester.ensureVisible(find.text('Update Expense'));
      await tester.tap(find.text('Update Expense'));
      await tester.pumpAndSettle();

      expect(expenses.length, 1);
      expect(expenses.first.title, 'Dinner');
      expect(expenses.first.amount, 750.25);
    });

    testWidgets('delete asks first, then removes the expense', (tester) async {
      Expense expense = Expense(
          title: 'Lunch', amount: 500, category: 'Food', date: DateTime(2026, 10, 2));
      expenses = [expense];

      await tester.pumpWidget(MaterialApp(home: AddExpense(expense: expense)));
      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Delete expense?'), findsOneWidget);

      // Cancel keeps it
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(expenses.length, 1);

      // Delete removes it
      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(expenses, isEmpty);
    });
  });
}
