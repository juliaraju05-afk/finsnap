import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'main.dart'; // for loggedInEmail
import 'package:finsnap/app_colors.dart';

class AddExpenseScreen extends StatefulWidget {
  @override
  _AddExpenseScreenState createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen>
    with SingleTickerProviderStateMixin {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String _type = "debit";
  String _category = "Others";
  DateTime _date = DateTime.now();

  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    _slideAnim = Tween<Offset>(begin: Offset(0, 0.05), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  // ==========================
  // ✅ SEND TO BACKEND
  // ==========================
  Future<void> sendToBackend(Map expense) async {
    try {
      final url = Uri.parse("http://10.0.2.2:5000/add-expense");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(expense),
      );

      print("BACKEND STATUS: ${response.statusCode}");
      print("BACKEND BODY: ${response.body}");
    } catch (e) {
      print("BACKEND ERROR: $e");
    }
  }

  // ==========================
  // ✅ SUBMIT FUNCTION
  // ==========================
  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty ||
        _amountCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill in title and amount")),
      );
      return;
    }

    final amount = double.tryParse(_amountCtrl.text.trim());

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Enter valid amount")),
      );
      return;
    }

    final expense = {
      'userEmail': loggedInEmail,
      'title': _titleCtrl.text.trim(),
      'amount': amount,
      'category': _category,
      'date': _date.toIso8601String().split('T')[0],
      'note': _noteCtrl.text.trim(),
      'type': _type,
    };

    // ✅ SEND DATA
    await sendToBackend(expense);

    // ✅ GO BACK
    Navigator.pop(context, expense);
  }

  String _monthName(int m) =>
      ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul",
        "Aug", "Sep", "Oct", "Nov", "Dec"][m];

  @override
  Widget build(BuildContext context) {
    Color accentColor =
        _type == 'debit' ? AppColors.expense : AppColors.income;

    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        title: Text("New Transaction"),
        centerTitle: true,
      ),
      body: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [

              // AMOUNT
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Amount"),
              ),

              SizedBox(height: 10),

              // TITLE
              TextField(
                controller: _titleCtrl,
                decoration: InputDecoration(labelText: "Title"),
              ),

              SizedBox(height: 10),

              // NOTE
              TextField(
                controller: _noteCtrl,
                decoration: InputDecoration(labelText: "Note"),
              ),

              SizedBox(height: 20),

              ElevatedButton(
                onPressed: _submit,
                child: Text("Save Expense"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}