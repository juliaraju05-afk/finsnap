import 'package:flutter/material.dart';
import 'main.dart' show AppColors;

class AddExpenseScreen extends StatefulWidget {
  @override
  _AddExpenseScreenState createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> with SingleTickerProviderStateMixin {
  final _titleCtrl  = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl   = TextEditingController();
  String _type = "debit";
  String _category = "Others";
  DateTime _date = DateTime.now();

  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  final _debitCats = [
    {'name': 'Food',          'icon': Icons.restaurant_rounded,     'color': Color(0xFFFF8C42)},
    {'name': 'Transport',     'icon': Icons.directions_car_rounded, 'color': Color(0xFF4ECDC4)},
    {'name': 'Shopping',      'icon': Icons.shopping_bag_rounded,   'color': Color(0xFFFF6B9D)},
    {'name': 'Entertainment', 'icon': Icons.movie_rounded,          'color': Color(0xFFA78BFA)},
    {'name': 'Bills',         'icon': Icons.receipt_long_rounded,   'color': Color(0xFFFF6B6B)},
    {'name': 'Health',        'icon': Icons.favorite_rounded,       'color': Color(0xFF3DDC84)},
    {'name': 'Others',        'icon': Icons.category_rounded,       'color': Color(0xFF8A8FA8)},
  ];

  final _creditCats = [
    {'name': 'Salary',     'icon': Icons.work_rounded,          'color': Color(0xFF3DDC84)},
    {'name': 'Freelance',  'icon': Icons.laptop_rounded,        'color': Color(0xFF60A5FA)},
    {'name': 'Investment', 'icon': Icons.trending_up_rounded,   'color': Color(0xFFF5C542)},
    {'name': 'Refund',     'icon': Icons.replay_rounded,        'color': Color(0xFF34D399)},
    {'name': 'Gift',       'icon': Icons.card_giftcard_rounded, 'color': Color(0xFFF472B6)},
    {'name': 'Others',     'icon': Icons.category_rounded,      'color': Color(0xFF8A8FA8)},
  ];

  List get _cats => _type == 'debit' ? _debitCats : _creditCats;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    _slideAnim = Tween<Offset>(begin: Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _slideCtrl.forward();
  }

  @override
  void dispose() { _slideCtrl.dispose(); super.dispose(); }

  void _submit() {
    if (_titleCtrl.text.trim().isEmpty || _amountCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.expense.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Text("Please fill in title and amount", style: TextStyle(color: Colors.white)),
      ));
      return;
    }
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.expense.withOpacity(0.9),
        content: Text("Enter a valid amount", style: TextStyle(color: Colors.white)),
      ));
      return;
    }
    Navigator.pop(context, {
      'title': _titleCtrl.text.trim(), 'amount': amount,
      'category': _category, 'date': _date.toIso8601String().split('T')[0],
      'note': _noteCtrl.text.trim(), 'type': _type,
    });
  }

  String _monthName(int m) => ["","Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"][m];

  @override
  Widget build(BuildContext context) {
    Color accentColor = _type == 'debit' ? AppColors.expense : AppColors.income;
    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(
        backgroundColor: AppColors.navy, elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.grey, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("New Transaction", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: true,
      ),
      body: SlideTransition(
        position: _slideAnim,
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Type toggle
            Container(
              height: 48, padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.navyCard, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(children: [
                _TypeBtn(label: "Expense", selected: _type == "debit", color: AppColors.expense,
                  icon: Icons.arrow_upward_rounded, onTap: () => setState(() { _type = "debit"; _category = "Others"; })),
                _TypeBtn(label: "Income", selected: _type == "credit", color: AppColors.income,
                  icon: Icons.arrow_downward_rounded, onTap: () => setState(() { _type = "credit"; _category = "Others"; })),
              ]),
            ),

            SizedBox(height: 24),

            _SectionLabel("Amount"),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: AppColors.navyCard, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider)),
              child: TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: "0.00", hintStyle: TextStyle(color: AppColors.grey, fontSize: 24, fontWeight: FontWeight.w300),
                  prefixIcon: Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Text("₹", style: TextStyle(color: accentColor, fontSize: 22, fontWeight: FontWeight.w700))),
                  prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                  border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                ),
              ),
            ),

            SizedBox(height: 16),
            _SectionLabel("Title"), SizedBox(height: 8),
            _DarkTextField(controller: _titleCtrl,
              hint: _type == 'debit' ? "e.g. Zomato, Petrol" : "e.g. Monthly Salary",
              icon: Icons.edit_rounded),

            SizedBox(height: 16),
            _SectionLabel("Note  (optional)"), SizedBox(height: 8),
            _DarkTextField(controller: _noteCtrl, hint: "Add a note...", icon: Icons.notes_rounded),

            SizedBox(height: 20),
            _SectionLabel("Category"), SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 4, shrinkWrap: true, physics: NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.9,
              children: _cats.map((cat) {
                bool sel = _category == cat['name'];
                Color c = cat['color'] as Color;
                return GestureDetector(
                  onTap: () => setState(() => _category = cat['name'] as String),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: sel ? c.withOpacity(0.15) : AppColors.navyCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: sel ? c : AppColors.divider, width: sel ? 1.5 : 1),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(cat['icon'] as IconData, color: sel ? c : AppColors.grey, size: 22),
                      SizedBox(height: 6),
                      Text(cat['name'] as String, style: TextStyle(
                        color: sel ? c : AppColors.grey, fontSize: 10,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                      ), textAlign: TextAlign.center),
                    ]),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: 20),
            _SectionLabel("Date"), SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context, initialDate: _date,
                  firstDate: DateTime(2020), lastDate: DateTime(2100),
                  builder: (ctx, child) => Theme(
                    data: ThemeData.dark().copyWith(colorScheme: ColorScheme.dark(
                      primary: AppColors.gold, surface: AppColors.navyCard)),
                    child: child!,
                  ),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: AppColors.navyCard, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider)),
                child: Row(children: [
                  Icon(Icons.calendar_today_rounded, color: AppColors.grey, size: 18),
                  SizedBox(width: 12),
                  Text("${_date.day} ${_monthName(_date.month)} ${_date.year}",
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                  Spacer(),
                  Icon(Icons.chevron_right_rounded, color: AppColors.grey, size: 20),
                ]),
              ),
            ),

            SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor, foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _submit,
                child: Text(_type == 'debit' ? "Save Expense" : "Save Income",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }
}

class _TypeBtn extends StatelessWidget {
  final String label; final bool selected; final Color color; final IconData icon; final VoidCallback onTap;
  const _TypeBtn({required this.label, required this.selected, required this.color, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(onTap: onTap,
      child: AnimatedContainer(duration: Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: selected ? Border.all(color: color.withOpacity(0.4)) : null,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 15, color: selected ? color : AppColors.grey),
          SizedBox(width: 6),
          Text(label, style: TextStyle(color: selected ? color : AppColors.grey,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400, fontSize: 13)),
        ]),
      ),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  final String text; const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: TextStyle(
    color: AppColors.grey, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5));
}

class _DarkTextField extends StatelessWidget {
  final TextEditingController controller; final String hint; final IconData icon;
  const _DarkTextField({required this.controller, required this.hint, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: AppColors.navyCard, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.divider)),
    child: TextField(controller: controller,
      style: TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: AppColors.grey, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.grey, size: 18),
        border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
  );
}