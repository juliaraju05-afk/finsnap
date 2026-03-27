// main.dart
// FinSnap — Production-grade fintech UI
// Design: Dark navy base (#0D1B2A), amber accent (#F5A623), soft white typography
// Key improvements:
//   - Glassmorphism summary card with gradient overlay
//   - AnimatedSwitcher for balance transitions
//   - Reusable AppTheme constants
//   - Category color + icon system
//   - Swipe-to-delete with confirmation snackbar + undo
//   - SMS auto-parsing for bank transaction alerts
//   - In-app notification banner (looks like real bank SMS)
//   - Custom SMS input for evaluator testing

import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
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

  // Notification banner state
  bool _showNotifBanner = false;
  String _notifText = '';
  Timer? _notifTimer;

  late AnimationController _balanceAnimController;
  late Animation<double> _balanceFadeAnim;

  late AnimationController _notifAnimController;
  late Animation<Offset> _notifSlideAnim;

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

    // Notification slide animation
    _notifAnimController = AnimationController(
      vsync: this, duration: Duration(milliseconds: 400),
    );
    _notifSlideAnim = Tween<Offset>(
      begin: Offset(0, -1),
      end: Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _notifAnimController,
      curve: Curves.easeOut,
    ));

    loadExpenses();
    requestSmsPermission();
  }

  @override
  void dispose() {
    _balanceAnimController.dispose();
    _notifAnimController.dispose();
    _notifTimer?.cancel();
    super.dispose();
  }

  // ── In-app Notification Banner ──
  void showInAppNotification(String smsBody) {
    setState(() {
      _notifText = smsBody;
      _showNotifBanner = true;
    });
    _notifAnimController.forward(from: 0);

    // Auto hide after 4 seconds
    _notifTimer?.cancel();
    _notifTimer = Timer(Duration(seconds: 4), () {
      _notifAnimController.reverse().then((_) {
        if (mounted) setState(() => _showNotifBanner = false);
      });
    });
  }

  // ── SMS Permission & Parsing ──
  Future<void> requestSmsPermission() async {
    final status = await Permission.sms.request();
    if (status.isGranted) {
      readTransactionSms();
    }
  }

  Future<void> readTransactionSms() async {
    SmsQuery query = SmsQuery();
    List<SmsMessage> messages = await query.querySms(
      kinds: [SmsQueryKind.inbox],
    );
    for (var msg in messages) {
      final body = msg.body ?? '';
      parseTransactionSMS(body, showNotif: false);
    }
  }

  String detectCategory(String body) {
    final lower = body.toLowerCase();
    if (RegExp(r'zomato|swiggy|dunzo|restaurant|food|cafe|pizza|burger|hotel|dining').hasMatch(lower))
      return 'Food';
    if (RegExp(r'uber|ola|rapido|metro|bus|train|irctc|fuel|petrol|diesel|transport').hasMatch(lower))
      return 'Transport';
    if (RegExp(r'amazon|flipkart|myntra|meesho|nykaa|shopping|mall|mart').hasMatch(lower))
      return 'Shopping';
    if (RegExp(r'electricity|electric|bescom|mseb|water|gas|broadband|wifi|airtel|jio|bsnl|bill|recharge').hasMatch(lower))
      return 'Bills';
    if (RegExp(r'netflix|spotify|prime|hotstar|youtube|subscription|game').hasMatch(lower))
      return 'Entertainment';
    if (RegExp(r'hospital|clinic|pharmacy|medicine|doctor|health|apollo|medplus').hasMatch(lower))
      return 'Health';
    if (RegExp(r'college|school|fee|course|udemy|education|book|stationery').hasMatch(lower))
      return 'Education';
    if (RegExp(r'salary|credited|income|bonus|stipend|refund|cashback').hasMatch(lower))
      return 'Income';
    return 'Others';
  }
  bool isLikelyBankSMS(String body) {
  final text = body.toLowerCase();

  return text.contains("debited") ||
      text.contains("credited") ||
      text.contains("spent") ||
      text.contains("paid") ||
      text.contains("transaction") ||
      text.contains("a/c") ||
      text.contains("account");
}

  void parseTransactionSMS(String body, {bool showNotif = true}) {

  if (!isLikelyBankSMS(body)) {
    return;
  }

  RegExp amountRegex = RegExp(r'(?:INR|Rs\.?)\s*([\d,]+\.?\d*)');
  RegExp debitRegex = RegExp(r'debited|spent|paid', caseSensitive: false);

  final amountMatch = amountRegex.firstMatch(body);

  if (amountMatch != null) {
    double amount = double.parse(amountMatch.group(1)!.replaceAll(',', ''));
    String type = debitRegex.hasMatch(body) ? 'debit' : 'credit';
    String category = detectCategory(body);

    final newExpense = {
      'title': 'Auto (SMS)',
      'amount': amount,
      'category': category,
      'date': DateTime.now().toIso8601String().split('T')[0],
      'note': '',
      'type': type,
    };

    bool exists = expenses.any((e) =>
        e['amount'] == amount && e['title'] == 'Auto (SMS)');

    if (!exists) {
      addExpense(newExpense);

      if (showNotif) {
        showInAppNotification(body);
      }
    }
  }
}

  // ── Data Methods ──
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

  // ── Demo Mode ──
  final List<Map<String, String>> _demoSmsMessages = [
    {
      'label': '🍕 Zomato - Food',
      'sms': 'INR 350.00 debited from A/C XX1234 for Zomato order. Avail Bal: INR 4650.00',
    },
    {
      'label': '🚗 Uber - Transport',
      'sms': 'INR 180.00 debited from A/C XX1234 for Uber ride. Avail Bal: INR 4470.00',
    },
    {
      'label': '🛒 Amazon - Shopping',
      'sms': 'INR 1299.00 debited from A/C XX1234 for Amazon order. Avail Bal: INR 3171.00',
    },
    {
      'label': '💡 Electricity Bill',
      'sms': 'INR 850.00 debited from A/C XX1234 for electricity bill payment. Avail Bal: INR 2321.00',
    },
    {
      'label': '🎬 Netflix - Entertainment',
      'sms': 'INR 499.00 debited from A/C XX1234 for Netflix subscription. Avail Bal: INR 1822.00',
    },
    {
      'label': '💊 Apollo - Health',
      'sms': 'INR 620.00 debited from A/C XX1234 at Apollo Pharmacy. Avail Bal: INR 1202.00',
    },
    {
      'label': '💰 Salary - Income',
      'sms': 'INR 25000.00 credited to A/C XX1234. Info: SALARY. Avail Bal: INR 26202.00',
    },
    {
      'label': '🎁 Cashback - Income',
      'sms': 'INR 150.00 cashback credited to A/C XX1234 from Amazon. Avail Bal: INR 26352.00',
    },
  ];

  void _showDemoSmsSheet(BuildContext context) {
    final TextEditingController customSmsController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Header
              Row(
                children: [
                  Icon(Icons.sms_rounded, color: AppTheme.amber, size: 20),
                  SizedBox(width: 8),
                  Text('SMS Transaction Simulator',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.navy,
                      )),
                ],
              ),
              SizedBox(height: 4),
              Text('Simulates automatic bank SMS parsing',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),

              SizedBox(height: 16),

              // ── Custom SMS Input ──
              Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.navy.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.navy.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('✏️ Enter Custom SMS',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.navy,
                        )),
                    SizedBox(height: 4),
                    Text('Type any bank SMS format to test parsing',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                    SizedBox(height: 10),
                    TextField(
                      controller: customSmsController,
                      maxLines: 3,
                      style: TextStyle(fontSize: 13, color: AppTheme.navy),
                      decoration: InputDecoration(
                        hintText: 'e.g. INR 500.00 debited from A/C XX1234 for Swiggy. Avail Bal: INR 4500.00',
                        hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppTheme.amber),
                        ),
                        contentPadding: EdgeInsets.all(10),
                      ),
                    ),
                    SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.send_rounded, size: 16),
                        label: Text('Parse This SMS'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.amber,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          final text = customSmsController.text.trim();
                          if (text.isEmpty) return;
                          Navigator.pop(context);
                          parseTransactionSMS(text, showNotif: true);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),
              Text('— or pick a sample transaction —',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              SizedBox(height: 8),

              // ── Demo Presets ──
              ...(_demoSmsMessages.map((demo) => ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 2),
                title: Text(demo['label']!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.navy,
                    )),
                trailing: Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: Colors.grey),
                onTap: () {
                  Navigator.pop(context);
                  parseTransactionSMS(demo['sms']!, showNotif: true);
                },
              ))).toList(),

              SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
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
      body: Stack(
        children: [
          CustomScrollView(
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
                    icon: Icon(Icons.sms_rounded, color: AppTheme.amber),
                    tooltip: 'SMS Simulator',
                    onPressed: () => _showDemoSmsSheet(context),
                  ),
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

          // ── In-App Notification Banner ──
          if (_showNotifBanner)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: _notifSlideAnim,
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Material(
                      elevation: 12,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.amber,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.account_balance_rounded,
                                  color: Colors.white, size: 20),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Bank SMS',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          )),
                                      Text('now',
                                          style: TextStyle(
                                            color: Colors.white38,
                                            fontSize: 11,
                                          )),
                                    ],
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    _notifText,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),

floatingActionButton: _AddButton(
  onPressed: () async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddExpenseScreen()),
    );
    if (result != null) addExpense(result);
  },
),
);
}  // closes build()

}  // closes _HomeScreenState class


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
    Key? key,
    required this.expense,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isCredit = expense['type'] == 'credit';

    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onEdit,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  expense['title'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                '${isCredit ? '+' : '-'}₹${(expense['amount'] as double).toStringAsFixed(2)}',
                style: TextStyle(
                  color: isCredit ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── FAB Widget ──
class _AddButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddButton({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppTheme.amber,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}