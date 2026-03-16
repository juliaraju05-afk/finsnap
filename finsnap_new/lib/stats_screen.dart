// stats_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import 'app_theme.dart';

class StatsScreen extends StatefulWidget {
  final List expenses;
  StatsScreen({required this.expenses});

  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _touchedIndex = -1;

  Map<String, double> budgets = {
    'Food': 3000, 'Transport': 1500, 'Shopping': 2000,
    'Entertainment': 1000, 'Bills': 2500, 'Health': 1000, 'Others': 1000,
  };

  double getIncome() => widget.expenses
      .where((e) => e['type'] == 'credit')
      .fold(0.0, (s, e) => s + (e['amount'] as double));

  double getExpenseTotal() => widget.expenses
      .where((e) => e['type'] == 'debit')
      .fold(0.0, (s, e) => s + (e['amount'] as double));

  Map<String, double> getCategoryExpenses() {
    final Map<String, double> result = {};
    for (var e in widget.expenses) {
      if (e['type'] == 'debit') {
        final cat = e['category'] ?? 'Others';
        result[cat] = (result[cat] ?? 0) + (e['amount'] as double);
      }
    }
    return result;
  }

  List<MapEntry<String, double>> getSortedCategories(Map<String, double> map) {
    final list = map.entries.toList();
    list.sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  void _editBudget(String category) {
    final c = TextEditingController(
        text: (budgets[category] ?? 1000).toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Budget — $category',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Monthly limit (₹)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.navy),
            onPressed: () {
              final val = double.tryParse(c.text);
              if (val != null && val > 0) setState(() => budgets[category] = val);
              Navigator.pop(ctx);
            },
            child: Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final income = getIncome();
    final expense = getExpenseTotal();
    final balance = income - expense;
    final catExp = getCategoryExpenses();
    final sortedCats = getSortedCategories(catExp);

    if (widget.expenses.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: Text('Stats')),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.bar_chart_rounded, size: 64, color: Colors.grey.shade300),
            SizedBox(height: 12),
            Text('No data yet', style: TextStyle(color: Colors.grey, fontSize: 15)),
          ]),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text('Stats'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorColor: AppTheme.amber,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Budget'),
            ],
          ),
        ),

        body: TabBarView(
          children: [

            // ── TAB 1: OVERVIEW ──
            SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
                    children: [
                      _buildStatCard('Income', income, AppTheme.green, Icons.arrow_downward_rounded),
                      SizedBox(width: 12),
                      _buildStatCard('Expense', expense, AppTheme.red, Icons.arrow_upward_rounded),
                    ],
                  ),

                  SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: balance >= 0
                          ? AppTheme.green.withOpacity(0.08)
                          : AppTheme.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: balance >= 0
                            ? AppTheme.green.withOpacity(0.2)
                            : AppTheme.red.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text('Net Balance',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                        Spacer(),
                        Text(
                          '${balance >= 0 ? '+' : ''}₹${balance.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: balance >= 0 ? AppTheme.green : AppTheme.red,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  if (catExp.isNotEmpty) ...[
                    Text('Expense Breakdown',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                            color: AppTheme.navy)),
                    SizedBox(height: 14),

                    // Pie chart card
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                            blurRadius: 12, offset: Offset(0, 4))],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: SizedBox(
                              height: 180,
                              child: PieChart(PieChartData(
                                pieTouchData: PieTouchData(
                                  touchCallback: (event, response) {
                                    setState(() {
                                      if (!event.isInterestedForInteractions ||
                                          response?.touchedSection == null) {
                                        _touchedIndex = -1;
                                        return;
                                      }
                                      _touchedIndex =
                                          response!.touchedSection!.touchedSectionIndex;
                                    });
                                  },
                                ),
                                borderData: FlBorderData(show: false),
                                sectionsSpace: 2,
                                centerSpaceRadius: 36,
                                sections: catExp.entries.toList().asMap().entries.map((entry) {
                                  final i = entry.key;
                                  final cat = entry.value.key;
                                  final val = entry.value.value;
                                  final pct = expense > 0 ? val / expense * 100 : 0;
                                  final isTouched = i == _touchedIndex;
                                  return PieChartSectionData(
                                    color: AppTheme.categoryColor(cat),
                                    value: val,
                                    title: isTouched ? '${pct.toStringAsFixed(1)}%' : '',
                                    radius: isTouched ? 62 : 52,
                                    titleStyle: TextStyle(fontSize: 11,
                                        fontWeight: FontWeight.w700, color: Colors.white),
                                  );
                                }).toList(),
                              )),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: catExp.entries.map((entry) {
                                final pct = expense > 0 ? entry.value / expense * 100 : 0;
                                return Padding(
                                  padding: EdgeInsets.symmetric(vertical: 3),
                                  child: Row(children: [
                                    Container(width: 8, height: 8,
                                      decoration: BoxDecoration(
                                        color: AppTheme.categoryColor(entry.key),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Expanded(child: Text(
                                      '${entry.key}\n${pct.toStringAsFixed(1)}%',
                                      style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                                    )),
                                  ]),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 14),

                    // Category bar rows
                    ...sortedCats.map((entry) {
                      final pct = expense > 0 ? entry.value / expense : 0.0;
                      final color = AppTheme.categoryColor(entry.key);
                      return Container(
                        margin: EdgeInsets.only(bottom: 8),
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
                              blurRadius: 6, offset: Offset(0, 2))],
                        ),
                        child: Column(
                          children: [
                            Row(children: [
                              Icon(AppTheme.categoryIcon(entry.key), color: color, size: 16),
                              SizedBox(width: 8),
                              Text(entry.key,
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              Spacer(),
                              Text('₹${entry.value.toStringAsFixed(2)}',
                                  style: TextStyle(fontWeight: FontWeight.w700,
                                      color: color, fontSize: 13)),
                            ]),
                            SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 4,
                                backgroundColor: Colors.grey.shade100,
                                valueColor: AlwaysStoppedAnimation(color),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),

            // ── TAB 2: BUDGET ──
            SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text('Budget Tracker',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                            color: AppTheme.navy)),
                    Spacer(),
                    Text('Tap to edit',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ]),
                  SizedBox(height: 16),

                  if (catExp.isEmpty)
                    Center(child: Text('No expense data yet.',
                        style: TextStyle(color: AppTheme.textSecondary)))
                  else
                    ...catExp.entries.map((entry) {
                      final cat = entry.key;
                      final spent = entry.value;
                      final budget = budgets[cat] ?? 1000;
                      final pct = min(spent / budget, 1.0);
                      final isOver = spent > budget;

                      return GestureDetector(
                        onTap: () => _editBudget(cat),
                        child: Container(
                          margin: EdgeInsets.only(bottom: 12),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: isOver
                                ? Border.all(color: AppTheme.red.withOpacity(0.3))
                                : null,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                                blurRadius: 8, offset: Offset(0, 2))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    color: AppTheme.categoryColor(cat).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(AppTheme.categoryIcon(cat),
                                      color: AppTheme.categoryColor(cat), size: 18),
                                ),
                                SizedBox(width: 10),
                                Text(cat, style: TextStyle(fontWeight: FontWeight.w600,
                                    fontSize: 14, color: AppTheme.navy)),
                                Spacer(),
                                if (isOver)
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('Over Budget',
                                        style: TextStyle(color: AppTheme.red,
                                            fontSize: 11, fontWeight: FontWeight.w600)),
                                  )
                                else
                                  Icon(Icons.edit_outlined,
                                      size: 15, color: AppTheme.textSecondary),
                              ]),
                              SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 6,
                                  backgroundColor: Colors.grey.shade100,
                                  valueColor: AlwaysStoppedAnimation(
                                    isOver ? AppTheme.red : AppTheme.categoryColor(cat),
                                  ),
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('₹${spent.toStringAsFixed(0)} spent',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                          color: isOver ? AppTheme.red : AppTheme.textPrimary)),
                                  Text('Limit: ₹${budget.toStringAsFixed(0)}',
                                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, double amount, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              SizedBox(width: 8),
              Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ]),
            SizedBox(height: 8),
            Text('₹${amount.toStringAsFixed(2)}',
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}