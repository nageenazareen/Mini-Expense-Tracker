import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'expense.dart';

// Stats tab: pie chart by category and bar chart of the last 6 months
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);

  void changeMonth(int step) {
    setState(() {
      month = DateTime(month.year, month.month + step);
    });
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    bool isCurrentMonth = isSameMonth(month, now);
    double total = monthTotal(month);

    List<String> used = categories
        .where((c) => categoryTotal(c, month: month) > 0)
        .toList()
      ..sort((a, b) => categoryTotal(b, month: month)
          .compareTo(categoryTotal(a, month: month)));

    // Biggest single expense of the month
    Expense? biggest;
    for (Expense expense in expenses) {
      if (isSameMonth(expense.date, month) &&
          (biggest == null || expense.amount > biggest.amount)) {
        biggest = expense;
      }
    }
    // Days passed so far (whole month if it is already over)
    int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    int days = isCurrentMonth ? now.day : daysInMonth;
    double perDay = total / days;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            const Text('Statistics',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Month switcher
            Card(
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Previous month',
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: () => changeMonth(-1),
                  ),
                  Expanded(
                    child: Text(formatMonth(month),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  IconButton(
                    tooltip: 'Next month',
                    icon: const Icon(Icons.chevron_right_rounded),
                    // No future months
                    onPressed: isCurrentMonth ? null : () => changeMonth(1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Small summary boxes
            Row(
              children: [
                Expanded(
                    child: statBox(context, 'Total', formatAmount(total),
                        Icons.account_balance_wallet_rounded)),
                const SizedBox(width: 12),
                Expanded(
                    child: statBox(context, 'Per day', formatAmount(perDay),
                        Icons.today_rounded)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: statBox(
                        context,
                        'Top category',
                        used.isEmpty ? '-' : used.first,
                        Icons.emoji_events_rounded)),
                const SizedBox(width: 12),
                Expanded(
                    child: statBox(
                        context,
                        'Biggest expense',
                        biggest == null ? '-' : formatAmount(biggest.amount),
                        Icons.arrow_upward_rounded)),
              ],
            ),

            // Pie chart
            const SizedBox(height: 24),
            const Text('Spending by Category',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: used.isEmpty
                    ? const EmptyState(
                        icon: Icons.pie_chart_outline_rounded,
                        title: 'Nothing to show',
                        message: 'There are no expenses in this month.',
                      )
                    : Column(
                        children: [
                          SizedBox(
                            height: 220,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                PieChart(
                                  PieChartData(
                                    sectionsSpace: 3,
                                    centerSpaceRadius: 62,
                                    sections: [
                                      for (String category in used)
                                        PieChartSectionData(
                                          value: categoryTotal(category,
                                              month: month),
                                          color: categoryColor(category),
                                          radius: 34,
                                          showTitle: false,
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('Total',
                                        style: TextStyle(color: Colors.grey)),
                                    Text(formatAmount(total),
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Legend
                          for (String category in used)
                            legendRow(category,
                                categoryTotal(category, month: month), total),
                        ],
                      ),
              ),
            ),

            // Bar chart of the last 6 months
            const SizedBox(height: 24),
            const Text('Last 6 Months',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
                child: SizedBox(height: 200, child: monthlyBarChart()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget statBox(
      BuildContext context, String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accentColor, size: 22),
            const SizedBox(height: 10),
            Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget legendRow(String category, double amount, double total) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: categoryColor(category),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(category)),
          Text(formatAmount(amount),
              style: const TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(
            width: 48,
            child: Text('${(amount / total * 100).toStringAsFixed(0)}%',
                textAlign: TextAlign.end,
                style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget monthlyBarChart() {
    // The 6 months ending with the selected month
    List<DateTime> months = [
      for (int i = 5; i >= 0; i--) DateTime(month.year, month.month - i)
    ];
    List<double> totals = [for (DateTime m in months) monthTotal(m)];
    double highest = totals.reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        maxY: highest == 0 ? 1 : highest * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                formatAmount(rod.toY),
                const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                DateTime m = months[value.toInt()];
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(monthNames[m.month - 1],
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (int i = 0; i < months.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: totals[i],
                  width: 22,
                  color: i == months.length - 1
                      ? accentColor
                      : accentBright.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
