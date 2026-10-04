import 'package:flutter/material.dart';
import 'auth.dart';
import 'expense.dart';

// Home tab: greeting, this month's spending, categories and recent expenses
class Dashboard extends StatelessWidget {
  final VoidCallback onAdd;
  final void Function(Expense expense) onEdit;
  final void Function({DateTime? month}) onSeeAll;

  const Dashboard({
    super.key,
    required this.onAdd,
    required this.onEdit,
    required this.onSeeAll,
  });

  String greeting() {
    int hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget sectionTitle(String title, {VoidCallback? onTap, String? action}) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          if (onTap != null)
            TextButton(onPressed: onTap, child: Text(action ?? 'See all')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    DateTime thisMonth = DateTime(now.year, now.month);
    double spentThisMonth = monthTotal(thisMonth);
    double spentLastMonth = monthTotal(DateTime(now.year, now.month - 1));
    List<Expense> recent = expenses.take(5).toList();
    List<DateTime> months = expenseMonths().take(6).toList();

    // Categories of this month, biggest first
    List<String> topCategories = categories
        .where((c) => categoryTotal(c, month: thisMonth) > 0)
        .toList()
      ..sort((a, b) => categoryTotal(b, month: thisMonth)
          .compareTo(categoryTotal(a, month: thisMonth)));

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            // Greeting row
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: accentColor,
                  child: Text(currentUser?.initials ?? '?',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${greeting()},',
                          style: const TextStyle(color: Colors.grey)),
                      Text(currentUser?.firstName ?? 'there',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 16, color: accentColor),
                      const SizedBox(width: 6),
                      Text(formatMonth(now),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Main gradient card
            BalanceCard(
              spentThisMonth: spentThisMonth,
              spentLastMonth: spentLastMonth,
            ),

            if (expenses.isEmpty) ...[
              const SizedBox(height: 24),
              Card(
                child: EmptyState(
                  icon: Icons.receipt_long_rounded,
                  title: 'No expenses yet',
                  message:
                      'Add your first expense to see your spending summary here.',
                  action: FilledButton.icon(
                    onPressed: onAdd,
                    style: FilledButton.styleFrom(backgroundColor: accentColor),
                    icon: const Icon(Icons.add),
                    label: const Text('Add first expense'),
                  ),
                ),
              ),
            ],

            // This month by category
            if (topCategories.isNotEmpty) ...[
              sectionTitle('This Month by Category'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Column(
                    children: [
                      for (String category in topCategories)
                        CategoryBar(
                          category: category,
                          amount: categoryTotal(category, month: thisMonth),
                          total: spentThisMonth,
                        ),
                    ],
                  ),
                ),
              ),
            ],

            // Monthly totals
            if (months.isNotEmpty) ...[
              sectionTitle('Monthly Totals'),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (DateTime month in months)
                      ListTile(
                        leading: const Icon(Icons.calendar_month_rounded,
                            color: accentColor),
                        title: Text(formatMonth(month)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              formatAmount(monthTotal(month)),
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                        // Open the Expenses tab filtered to this month
                        onTap: () => onSeeAll(month: month),
                      ),
                  ],
                ),
              ),
            ],

            // Recent expenses
            if (recent.isNotEmpty) ...[
              sectionTitle('Recent Expenses', onTap: () => onSeeAll()),
              for (Expense expense in recent)
                ExpenseTile(expense: expense, onTap: () => onEdit(expense)),
            ],
          ],
        ),
      ),
    );
  }
}

class BalanceCard extends StatelessWidget {
  final double spentThisMonth;
  final double spentLastMonth;

  const BalanceCard({
    super.key,
    required this.spentThisMonth,
    required this.spentLastMonth,
  });

  @override
  Widget build(BuildContext context) {
    // Compare with last month, e.g. "12% less than last month"
    String? compare;
    bool spentLess = true;
    if (spentLastMonth > 0) {
      double change = (spentThisMonth - spentLastMonth) / spentLastMonth * 100;
      spentLess = change <= 0;
      compare =
          '${change.abs().toStringAsFixed(0)}% ${spentLess ? 'less' : 'more'} than last month';
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: brandGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Spent this month',
              style: TextStyle(color: Colors.white70, fontSize: 15)),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatAmount(spentThisMonth),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (compare != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                      spentLess
                          ? Icons.trending_down_rounded
                          : Icons.trending_up_rounded,
                      color: Colors.white,
                      size: 16),
                  const SizedBox(width: 6),
                  Text(compare,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
            ),
          ],
          const Divider(color: Colors.white24, height: 32),
          // Gaps between the columns so long amounts never touch
          Row(
            children: [
              Expanded(
                flex: 4,
                child: cardStat('Last month', formatAmount(spentLastMonth)),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: cardStat('All time', formatAmount(getTotal())),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: cardStat('Expenses', '${expenses.length}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget cardStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

// Category name, amount, percent and a colored progress bar
class CategoryBar extends StatelessWidget {
  final String category;
  final double amount;
  final double total;

  const CategoryBar({
    super.key,
    required this.category,
    required this.amount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    double share = total == 0 ? 0 : amount / total;
    Color color = categoryColor(category);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          CategoryIcon(category: category, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(category,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    Text(formatAmount(amount),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 40,
                      child: Text('${(share * 100).toStringAsFixed(0)}%',
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: share,
                    minHeight: 7,
                    color: color,
                    backgroundColor: color.withValues(alpha: 0.12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
