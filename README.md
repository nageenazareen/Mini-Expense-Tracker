# Spendly – Expense Tracker

Spendly is a Flutter app to record, understand and control daily spending.
It has accounts, a dashboard, charts, search and filters, and dark mode.

## Screens

| Screen | What it does |
|---|---|
| **Login / Sign up** | Create an account or log in. Stays logged in until you log out |
| **Home** | Greeting, money spent this month vs last month, this month by category, monthly totals, recent expenses |
| **Expenses** | Full list grouped by day (Today, Yesterday, …), search, category and month filters, filtered total, swipe to delete with Undo |
| **Stats** | Month switcher, total / per-day / top category / biggest expense, donut chart by category, bar chart of the last 6 months |
| **Profile** | Name and email, dark mode switch, delete all expenses, log out |
| **Add / Edit Expense** | Title, amount, date, category, optional note. Edit screen has a Delete button with confirmation |

## Task Checklist

### Day 1
- Add expenses (title, amount, category, date), list, total, form validation, navigation

### Day 2 – Full CRUD
- **Add, Edit, Delete, List** of expenses with **category** and **date**
- **Delete** from the edit screen (with a "Delete expense?" dialog) or by swiping left in the list (with Undo)
- **Total calculation:** this month, last month, all time, per category, and the total of the current filter
- **Form validation:**
  - Title is required, 2–40 characters
  - Amount must be a plain number (`500` or `99.50`), more than 0, at most Rs. 10,000,000 and at most 2 decimal places. `-5`, `abc`, `1e5` are rejected
  - Category is required; the date cannot be in the future
- **Local storage:** `shared_preferences`

### Day 3 – Improvements (all 7 done)
- **Search/filter:** search by title, category or note; filter by category and by month; "Clear filters"
- **Category-wise expenses:** colored category bars on Home and a donut chart on Stats
- **Monthly total:** this month vs last month (with % change), monthly totals list, 6-month bar chart
- **Local persistence:** every user's expenses are saved on the device under their own key
- **Better UI/UX:** bottom navigation, gradient cards, colored categories, charts, dark mode, list grouped by day
- **Empty state:** on Home, Expenses (no expenses / no matches) and Stats (no data in a month)
- **Error handling:**
  - A broken saved entry is skipped instead of crashing the app, and the user is told
  - If saving fails, a red error message is shown
  - Login shows clear errors (wrong password, email already used) and a loading spinner

### Extra
- **Login & Sign up** with name, email and password
  - Passwords are **never saved as plain text**: a random salt + SHA-256 hash is stored
  - Same error for wrong email or wrong password, so emails cannot be guessed
  - Each account only sees its own expenses
  - Expenses saved by the Day 1 version are moved to the first account that logs in, so nothing is lost
- **Dark mode**, remembered after closing the app
- **16 automated tests** (`flutter test`)

> Note: accounts are stored on this device only (no server). The task's Advanced
> part (Supabase) is the next step to store accounts and expenses online.

## Flutter/Dart Version

- Tested with Flutter 3.44 (stable channel) and Dart 3.12 (works on Flutter 3.35+ / Dart 3.9+)

Check yours with `flutter --version`.

## Packages Used

- `shared_preferences` – saves accounts, expenses and settings on the device
- `fl_chart` – donut and bar charts on the Stats screen
- `crypto` – SHA-256 hashing for passwords

## How to Run

```bash
flutter pub get
flutter run
```

Run the tests:

```bash
flutter test
```

## Project Structure

```text
lib/
  main.dart            -> starts the app, restores the login, light/dark theme
  theme.dart           -> colors, category colors, gradient, light & dark themes
  auth.dart            -> sign up, log in, log out, password hashing, dark mode setting
  expense.dart         -> Expense class, save/load per user, totals,
                          formatting helpers, ExpenseTile, EmptyState
  login_screen.dart    -> login and sign up form
  home_shell.dart      -> bottom navigation with the 4 tabs
  dashboard.dart       -> Home tab
  expense_list.dart    -> Expenses tab (search, filters, grouped list)
  stats_screen.dart    -> Stats tab (charts)
  profile_screen.dart  -> Profile tab
  add_expense.dart     -> add / edit / delete one expense
test/
  widget_test.dart     -> 16 unit and widget tests
```

## What I Learned

- How StatefulWidget works and how setState updates the UI
- How forms and validation work with Form, GlobalKey and TextFormField
- How to make a custom form field (category chips) using FormField
- How navigation works with Navigator.push, pop and pushReplacement
- How to build a bottom navigation bar with NavigationBar
- How to save data with shared_preferences by converting objects to JSON
- How to store passwords safely with a salt and a hash
- How to draw charts with fl_chart
- How to support light and dark themes with ThemeData
- How to write unit and widget tests

## Problems Faced

- **Passing data between screens:** I kept one `expenses` list in `expense.dart` and imported it in every screen.
- **Updating the total after adding an expense:** I used `await Navigator.push(...)` and then `setState()`.
- **Form validation:** The amount field accepted text and negative numbers. Now a regular expression only allows numbers like `500` or `99.50`.
- **Decimals were lost:** `99.50` showed as `Rs. 100`. I changed `formatAmount` to keep 2 decimals.
- **App crash on bad saved data:** One broken entry crashed the app on start. Now it is skipped with try/catch.
- **Overflow on small screens:** A Row on the login screen went off-screen in a test, so I changed it to a Wrap.
- **Keeping each user's data separate:** Every user's expenses are saved under `expenses_<email>`.

## Future Improvements

- Supabase database and online login (the task's Advanced part)
- Monthly budget with alerts
- Export expenses to PDF or CSV
