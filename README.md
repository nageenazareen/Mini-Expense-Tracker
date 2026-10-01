# Spendly – Expense Tracker

Spendly is a small Flutter app to record and track daily spending.

## Features

### Required
- Add expenses (title, amount, category, date)
- View all expenses in a list
- Calculate total spending
- Form validation
- Navigation between Dashboard, Add Expense and Expense List

### Bonus
- **Categories:** Food, Transport, Shopping, Bills, Other (each with its own icon)
- **Delete expense:** swipe left, with an Undo option
- **Edit expense:** tap any expense to change it
- **Search & filter:** search by title and filter by category
- **Local persistence:** expenses stay saved after closing or refreshing the app
- **Better UI/UX:** spending-by-category breakdown, empty states, centered layout on web

## Flutter/Dart Version

- Flutter 3.35 (stable channel)
- Dart 3.9

Check yours with `flutter --version`.

## Package Used

- `shared_preferences` – the official Flutter package for saving small data on the device. Used only for local persistence.

## How to Run

```bash
flutter pub get
flutter run
```

## Project Structure

```text
lib/
  main.dart          -> starts the app, loads saved expenses, sets the theme
  expense.dart       -> Expense class, the expenses list, save/load,
                        and small helpers (total, Rs. format, date format,
                        category icon, ExpenseTile)
  dashboard.dart     -> total spent, spending by category, recent expenses
  add_expense.dart   -> form to add a new expense or edit an existing one
  expense_list.dart  -> all expenses with search, filter, edit and delete
```

## What I Learned

- How StatefulWidget works and how setState updates the UI
- How forms and validation work with Form, GlobalKey and TextFormField
- How to make a custom form field (category chips) using FormField
- How navigation works with Navigator.push and Navigator.pop
- How ListView and ListView.builder display data from a list
- How to calculate totals from a list with a simple for loop
- How to save data with shared_preferences by converting objects to JSON
- How to reuse one screen for both adding and editing

## Problems Faced

- **Passing data between screens:** I kept one `expenses` list in `expense.dart` and imported it in every screen.
- **Updating the total after adding an expense:** The dashboard did not update when I came back. I fixed it with `await Navigator.push(...)` and then `setState()`.
- **Form validation:** The amount field accepted text and negative numbers. I used `double.tryParse` and checked that the amount is more than 0.
- **Handling the date picker:** The date was not part of the form, so I used a read-only TextFormField that opens the date picker on tap.
- **Saving data:** SharedPreferences cannot store objects directly, so I converted each expense to a Map and then to a JSON string.

## Future Improvements

- Monthly reports
- Charts
- Firebase/Supabase database
- Export expenses to PDF or CSV
- Dark mode
