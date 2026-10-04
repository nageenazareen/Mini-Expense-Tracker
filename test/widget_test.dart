import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:spendly/add_expense.dart';
import 'package:spendly/auth.dart';
import 'package:spendly/expense.dart';
import 'package:spendly/home_shell.dart';
import 'package:spendly/main.dart';

void main() {
  // Start every test with an empty, fake device storage
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    expenses = [];
    currentUser = null;
  });

  group('helpers', () {
    test('formatAmount adds commas and keeps decimals', () {
      expect(formatAmount(12500), 'Rs. 12,500');
      expect(formatAmount(1000000), 'Rs. 1,000,000');
      expect(formatAmount(99.5), 'Rs. 99.50');
      expect(formatAmount(0), 'Rs. 0');
    });

    test('monthly and category totals', () {
      expenses = [
        Expense(
            title: 'Lunch',
            amount: 500,
            category: 'Food',
            date: DateTime(2026, 10, 2)),
        Expense(
            title: 'Bus',
            amount: 100,
            category: 'Transport',
            date: DateTime(2026, 10, 20)),
        Expense(
            title: 'Shoes',
            amount: 3000,
            category: 'Shopping',
            date: DateTime(2026, 9, 15)),
        Expense(
            title: 'Dinner',
            amount: 700,
            category: 'Food',
            date: DateTime(2026, 9, 1)),
      ];
      expect(monthTotal(DateTime(2026, 10)), 600);
      expect(monthTotal(DateTime(2026, 9)), 3700);
      expect(monthTotal(DateTime(2026, 8)), 0);
      expect(getTotal(), 4300);
      expect(categoryTotal('Food'), 1200);
      expect(categoryTotal('Food', month: DateTime(2026, 10)), 500);
      expect(expenseMonths(), [DateTime(2026, 10), DateTime(2026, 9)]);
    });
  });

  group('storage', () {
    test('save and load keep the same expenses', () async {
      currentUser = AppUser(name: 'Test User', email: 'test@example.com');
      expenses = [
        Expense(
            title: 'Tea',
            amount: 80.5,
            category: 'Food',
            date: DateTime(2026, 10, 1),
            note: 'With friends'),
      ];
      expect(await saveExpenses(), isTrue);
      expenses = [];
      await loadExpenses();
      expect(expenses.length, 1);
      expect(expenses.first.amount, 80.5);
      expect(expenses.first.note, 'With friends');
    });

    test('a broken saved entry is skipped instead of crashing', () async {
      currentUser = AppUser(name: 'Test User', email: 'test@example.com');
      SharedPreferences.setMockInitialValues({
        'expenses_test@example.com': [
          '{"title":"Ok","amount":10,"category":"Food","date":"2026-10-01T00:00:00.000"}',
          'this is not json',
        ],
      });
      await loadExpenses();
      expect(expenses.length, 1);
      expect(skippedExpenses, 1);
    });

    test('each user only sees their own expenses', () async {
      await signUp('Ali Khan', 'ali@example.com', 'secret1');
      expenses = [
        Expense(
            title: 'Ali lunch',
            amount: 300,
            category: 'Food',
            date: DateTime(2026, 10, 1)),
      ];
      await saveExpenses();

      await signUp('Sara Ahmed', 'sara@example.com', 'secret2');
      await loadExpenses();
      expect(expenses, isEmpty);

      await logIn('ali@example.com', 'secret1');
      await loadExpenses();
      expect(expenses.single.title, 'Ali lunch');
    });

    test('Day 1 expenses are moved to the first user', () async {
      SharedPreferences.setMockInitialValues({
        'expenses': [
          '{"title":"Old one","amount":50,"category":"Food","date":"2026-10-01T00:00:00.000"}',
        ],
      });
      await signUp('Ali Khan', 'ali@example.com', 'secret1');
      await loadExpenses();
      expect(expenses.single.title, 'Old one');
    });
  });

  group('auth', () {
    test('sign up, log out and log in', () async {
      expect(await signUp('Nageena Zareen', 'Nageena@Example.com', 'pass123'),
          isNull);
      expect(currentUser!.email, 'nageena@example.com');
      expect(currentUser!.initials, 'NZ');
      expect(currentUser!.firstName, 'Nageena');

      await logOut();
      expect(currentUser, isNull);

      expect(await logIn('nageena@example.com', 'wrong-pass'),
          'Incorrect email or password.');
      expect(await logIn('nobody@example.com', 'pass123'),
          'Incorrect email or password.');
      expect(await logIn('NAGEENA@example.com', 'pass123'), isNull);
      expect(currentUser!.name, 'Nageena Zareen');
    });

    test('the same email cannot sign up twice', () async {
      await signUp('Ali Khan', 'ali@example.com', 'secret1');
      expect(await signUp('Ali Two', 'ali@example.com', 'secret2'),
          contains('already exists'));
    });

    test('the password is not saved as plain text', () async {
      await signUp('Ali Khan', 'ali@example.com', 'mySecret99');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('accounts'), isNot(contains('mySecret99')));
    });

    test('email and password checks', () {
      expect(validateEmail(''), isNotNull);
      expect(validateEmail('abc'), isNotNull);
      expect(validateEmail('a@b.com'), isNull);
      expect(validatePassword('123'), isNotNull);
      expect(validatePassword('123456'), isNull);
    });
  });

  group('screens', () {
    testWidgets('logged out users see the login screen', (tester) async {
      await tester.pumpWidget(const MyApp());
      expect(find.text('Welcome back'), findsOneWidget);

      await tester.tap(find.text('Log In'));
      await tester.pump();
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter a password'), findsOneWidget);
    });

    testWidgets('home shows the empty state and all 4 tabs', (tester) async {
      currentUser = AppUser(name: 'Nageena Zareen', email: 'n@example.com');
      await tester.pumpWidget(const MaterialApp(home: HomeShell()));
      expect(find.text('Nageena'), findsOneWidget);
      expect(find.text('No expenses yet'), findsOneWidget);
      for (String tab in ['Home', 'Expenses', 'Stats', 'Profile']) {
        expect(find.text(tab), findsWidgets);
      }
    });

    testWidgets('saving an empty form shows validation errors', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AddExpense()));
      await tester.ensureVisible(find.text('Save Expense'));
      await tester.tap(find.text('Save Expense'));
      await tester.pump();

      expect(find.text('Please enter a title'), findsOneWidget);
      expect(find.text('Please enter an amount'), findsOneWidget);
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
        expect(
            find.textContaining(
                RegExp('Enter a number|more than 0|cannot be more')),
            findsOneWidget,
            reason: '"$bad" should be rejected');
      }
    });

    testWidgets('editing an expense updates it', (tester) async {
      Expense expense = Expense(
          title: 'Lunch',
          amount: 500,
          category: 'Food',
          date: DateTime(2026, 10, 2));
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
          title: 'Lunch',
          amount: 500,
          category: 'Food',
          date: DateTime(2026, 10, 2));
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
