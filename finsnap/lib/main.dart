// main.dart
// FinSnap — Production-grade fintech UI
// Design: Dark navy base (#0D1B2A), amber accent (#F5A623), soft white typography
// Key improvements:
//   - Glassmorphism summary card with gradient overlay
//   - AnimatedSwitcher for balance transitions
//   - Staggered list entry animations
//   - Reusable AppTheme constants
//   - Category color + icon system
//   - Swipe-to-delete with confirmation snackbar + undo

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_expense_screen.dart';
import 'edit_expense_screen.dart';
import 'stats_screen.dart';
import 'app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(FinSnapApp());
}

class FinSnapApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FinSnap',
      theme: AppTheme.lightTheme,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List expenses = [];
  String selectedMonth = "All";
  String selectedType = "All";

  late AnimationController _balanceAnimController;
  late Animation<double> _balanceFadeAnim;

  final List<String> months = [
    "All","Jan","Feb","Mar","Apr","May","Jun",
    "Jul","Aug","Sep","Oct","Nov","Dec"
  ];

  @override
  void initState() {
    super.initState();
    _balanceAnimController = AnimationController(
      vsync: this, duration: Duration(milliseconds: 600),
    );
    _balanceFadeAnim = CurvedAnimation(
      parent: _balanceAnimController, curve: Curves.easeOut,
    );
    loadExpenses();
  }

  @override
  void dispose() {
    _balanceAnimController.dispose();
    super.dispose();
  }

  Future<void> loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('expenses');
    if (data != null) {
      final decoded = jsonDecode(data) as List;
      setState(() {
        expenses = decoded.map((item) => {
          'title': item['title'],
          'amount': (item['amount'] as num).toDouble(),
          'category': item['category'] ?? 'Others',
          'date': item['date'] ?? '',
          'note': item['note'] ?? '',
          'type': item['type'] ?? 'debit',
        }).toList();
      });
      _balanceAnimController.forward(from: 0);
    }
  }

  Future<void> saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('expenses', jsonEncode(expenses));
  }

  void addExpense(Map expense) {
    setState(() => expenses.add(expense));
    saveExpenses();
    _balanceAnimController.forward(from: 0);
  }

  void deleteExpense(int index) {
    final deleted = Map.from(expenses[index]);
    setState(() => expenses.removeAt(index));
    saveExpenses();
    _balanceAnimController.forward(from: 0);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.navy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text('"${deleted['title']}" removed',
            style: TextStyle(color: Colors.white)),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: AppTheme.amber,
          onPressed: () {
            setState(() => expenses.insert(index, deleted));
            saveExpenses();
            _balanceAnimController.forward(from: 0);
          },
        ),
      ),
    );
  }

  void editExpense(int index, Map updated) {
    setState(() => expenses[index] = updated);
    saveExpenses();
    _balanceAnimController.forward(from: 0);
  }

  double getIncome() => expenses
      .where((e) => e['type'] == 'credit')
      .fold(0.0, (s, e) => s + (e['amount'] as double));

  double getExpenseTotal() => expenses
      .where((e) => e['type'] == 'debit')
      .fold(0.0, (s, e) => s + (e['amount'] as double));

  List getFiltered() {
    return expenses.where((e) {
      if (selectedType == 'Income' && e['type'] != 'credit') return false;
      if (selectedType == 'Expense' && e['type'] != 'debit') return false;
      if (selectedMonth != 'All') {
        int mi = months.indexOf(selectedMonth);
        try {
          if (DateTime.parse(e['date']).month != mi) return false;
        } catch (_) { return false; }
      }
      return true;
    }).toList();
  }

  Map<String, List> groupByCategory(List items) {
    final Map<String, List> grouped = {};
    for (var e in items) {
      final cat = e['category'] ?? 'Others';
      grouped.putIfAbsent(cat, () => []).add(e);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = getFiltered();
    final grouped = groupByCategory(filtered);
    final income = getIncome();
    final expense = getExpenseTotal();
    final balance = income - expense;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: [

          // ── Collapsing Header ──
          SliverAppBar(
            expandedHeight: 220,
            collapsedHeight: 60,
            pinned: true,
            backgroundColor: AppTheme.navy,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _SummaryCard(
                income: income,
                expense: expense,
                balance: balance,
                animation: _balanceFadeAnim,
              ),
            ),
            title: Text('FinSnap',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                )),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.bar_chart_rounded, color: Colors.white),
                onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => StatsScreen(expenses: expenses))),
              ),
            ],
          ),

          // ── Filter Pills ──
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  // Type filter
                  Row(
                    children: ['All', 'Income', 'Expense'].map((type) {
                      final selected = selectedType == type;
                      return Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: _FilterChip(
                          label: type,
                          selected: selected,
                          onTap: () => setState(() => selectedType = type),
                          selectedColor: type == 'Income'
                              ? AppTheme.green
                              : type == 'Expense'
                                  ? AppTheme.red
                                  : AppTheme.amber,
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 10),
                  // Month filter
                  SizedBox(
                    height: 34,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: months.length,
                      itemBuilder: (_, i) {
                        final m = months[i];
                        final selected = selectedMonth == m;
                        return Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: _FilterChip(
                            label: m,
                            selected: selected,
                            onTap: () => setState(() => selectedMonth = m),
                            selectedColor: AppTheme.amber,
                            small: true,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Empty state ──
          if (filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 56, color: Colors.grey.shade300),
                    SizedBox(height: 12),
                    Text('No transactions yet',
                        style: TextStyle(color: Colors.grey, fontSize: 15)),
                  ],
                ),
              ),
            ),

          // ── Transaction Groups ──
          ...grouped.entries.map((entry) {
            final cat = entry.key;
            final items = entry.value;
            final catTotal = items.fold(0.0, (s, e) => s + (e['amount'] as double));

            return SliverMainAxisGroup(slivers: [
              // Category header
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: AppTheme.categoryColor(cat),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(cat,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                            letterSpacing: 0.5,
                          )),
                      Spacer(),
                      Text('₹${catTotal.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.categoryColor(cat),
                          )),
                    ],
                  ),
                ),
              ),

              // Transaction items
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final e = items[i];
                    final idx = expenses.indexOf(e);
                    return _TransactionTile(
                      expense: e,
                      onEdit: () async {
                        final result = await Navigator.push(context,
                          MaterialPageRoute(builder: (_) => EditExpenseScreen(
                            expense: Map<String, dynamic>.from(e),
                            index: idx,
                          )));
                        if (result != null) editExpense(result['index'], result['expense']);
                      },
                      onDelete: () => deleteExpense(idx),
                    );
                  },
                  childCount: items.length,
                ),
              ),
            ]);
          }).toList(),

          SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),

      floatingActionButton: _AddButton(
        onPressed: () async {
          final result = await Navigator.push(context,
            MaterialPageRoute(builder: (_) => AddExpenseScreen()));
          if (result != null) addExpense(result);
        },
      ),
    );
  }
}

// ── Summary Card Widget ──
class _SummaryCard extends StatelessWidget {
  final double income, expense, balance;
  final Animation<double> animation;

  const _SummaryCard({
    required this.income,
    required this.expense,
    required this.balance,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.navy, Color(0xFF1A3550)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 50, 24, 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Balance',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w500,
                  )),
              SizedBox(height: 6),
              FadeTransition(
                opacity: animation,
                child: Text(
                  '₹${balance.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: balance < 0 ? AppTheme.red : Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  _MiniStat(label: 'Income', amount: income, color: AppTheme.green),
                  SizedBox(width: 24),
                  Container(width: 1, height: 32, color: Colors.white12),
                  SizedBox(width: 24),
                  _MiniStat(label: 'Expense', amount: expense, color: AppTheme.red),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _MiniStat({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            SizedBox(width: 5),
            Text(label, style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        SizedBox(height: 4),
        Text('₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            )),
      ],
    );
  }
}

// ── Filter Chip Widget ──
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;
  final bool small;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.selectedColor,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: small ? 12 : 16,
          vertical: small ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: selected ? selectedColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? selectedColor : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: selected ? [
            BoxShadow(
              color: selectedColor.withOpacity(0.25),
              blurRadius: 8,
              offset: Offset(0, 3),
            )
          ] : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: small ? 12 : 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}

// ── Transaction Tile Widget ──
class _TransactionTile extends StatelessWidget {
  final Map expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TransactionTile({
    required this.expense,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isCredit = expense['type'] == 'credit';

    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.red.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onEdit,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: Offset(0, 2),
              )
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.categoryColor(expense['category']).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    AppTheme.categoryIcon(expense['category']),
                    color: AppTheme.categoryColor(expense['category']),
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                // Title + date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(expense['title'],
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppTheme.navy,
                          )),
                      SizedBox(height: 3),
                      Text(expense['date'] ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                          )),
                    ],
                  ),
                ),
                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isCredit ? '+' : '-'}₹${(expense['amount'] as double).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isCredit ? AppTheme.green : AppTheme.red,
                      ),
                    ),
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isCredit
                            ? AppTheme.green.withOpacity(0.1)
                            : AppTheme.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isCredit ? 'IN' : 'OUT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isCredit ? AppTheme.green : AppTheme.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── FAB Widget ──
class _AddButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _AddButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.amber, Color(0xFFE8920A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.amber.withOpacity(0.4),
              blurRadius: 16,
              offset: Offset(0, 6),
            )
          ],
        ),
        child: Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}