import 'package:flutter/material.dart';
import 'auth.dart';
import 'expense.dart';
import 'login_screen.dart';

// Profile tab: user info, dark mode, clear data and log out
class ProfileScreen extends StatelessWidget {
  // Called after the expenses are cleared, so the other tabs refresh
  final VoidCallback onDataChanged;

  const ProfileScreen({super.key, required this.onDataChanged});

  Future<bool> confirm(
      BuildContext context, String title, String message, String button) async {
    bool? yes = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(button),
            ),
          ],
        );
      },
    );
    return yes == true;
  }

  void clearData(BuildContext context) async {
    bool yes = await confirm(
      context,
      'Delete all expenses?',
      'All ${expenses.length} expenses of this account will be removed. This cannot be undone.',
      'Delete all',
    );
    if (!yes) return;
    expenses.clear();
    bool saved = await saveExpenses();
    onDataChanged();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(saved
            ? 'All expenses deleted'
            : 'Could not save on this device. Please try again.'),
      ),
    );
  }

  void doLogOut(BuildContext context) async {
    bool yes = await confirm(context, 'Log out?',
        'You can log in again with your email.', 'Log out');
    if (!yes) return;
    await logOut();
    expenses = [];
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    AppUser? user = currentUser;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            const Text('Profile',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // User card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: brandGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: Text(user?.initials ?? '?',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: accentColor)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.name ?? '',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(user?.email ?? '',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                    child: miniStat('Expenses', '${expenses.length}',
                        Icons.receipt_long_rounded)),
                const SizedBox(width: 12),
                Expanded(
                    child: miniStat('All time', formatAmount(getTotal()),
                        Icons.account_balance_wallet_rounded)),
              ],
            ),

            const SizedBox(height: 24),
            const Text('Settings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ValueListenableBuilder<bool>(
                    valueListenable: darkMode,
                    builder: (context, isDark, _) {
                      return SwitchListTile(
                        secondary: const Icon(Icons.dark_mode_outlined),
                        title: const Text('Dark mode'),
                        value: isDark,
                        activeThumbColor: accentColor,
                        onChanged: setDarkMode,
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_sweep_outlined,
                        color: Colors.red),
                    title: const Text('Delete all expenses',
                        style: TextStyle(color: Colors.red)),
                    enabled: expenses.isNotEmpty,
                    onTap: () => clearData(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text('About',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Spendly'),
                    subtitle: Text('Version 2.0 • Made with Flutter'),
                  ),
                  ListTile(
                    leading: Icon(Icons.lock_outline),
                    title: Text('Your data'),
                    subtitle: Text(
                        'Your account and expenses are stored only on this device.'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => doLogOut(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Log out'),
            ),
          ],
        ),
      ),
    );
  }

  Widget miniStat(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: accentColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
