import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'features/auto_entry_handler.dart';

class HomeScreen extends StatefulWidget {
  final String email;

  const HomeScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> expenses = [];
  final AutoEntryHandler autoHandler = AutoEntryHandler();

  static const String baseUrl = "http://10.56.219.136:5000";

  // ✅ INIT
  @override
  void initState() {
    super.initState();
    fetchExpenses();
    autoHandler.init(
      onAutoAdd: (data) {
        addTransactionDirect(
          amount: data['amount'],
          type: data['type'],
          category: data['category'],
        );
        _showSnack("Auto-added ₹${data['amount']}");
      },
      onAskUser: (data) {
        _showPreviewDialog(data);
      },
    );
  }

  // ✅ FETCH FROM MONGODB
  Future<void> fetchExpenses() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/expenses/${widget.email}"),
      );

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          expenses = data.map((e) => {
            "title": e["title"] ?? "Auto Transaction",
            "amount": e["amount"] is int
                ? e["amount"]
                : (e["amount"] as num).toInt(),
            "type": e["type"],
            "category": e["category"] ?? "Others",
            "date": e["date"] ?? DateTime.now().toString(),
          }).toList();
        });
        print("✅ Fetched ${expenses.length} expenses");
      } else {
        print("❌ Fetch failed: ${res.statusCode}");
      }
    } catch (e) {
      print("❌ Fetch error: $e");
    }
  }

  // ✅ SAVE TO MONGODB
  Future<void> saveToBackend(Map<String, dynamic> expense) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/add-expense"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userEmail": widget.email,
          "title": expense["title"],
          "amount": expense["amount"],
          "type": expense["type"],
          "category": expense["category"],
          "date": expense["date"],
        }),
      );

      if (res.statusCode == 200) {
        print("✅ Saved to MongoDB");
      } else {
        print("❌ Save failed: ${res.statusCode} — ${res.body}");
      }
    } catch (e) {
      print("❌ Save error: $e");
    }
  }

  // ✅ DIRECT ADD (SMS)
  void addTransactionDirect({
    required double amount,
    required String type,
    required String category,
    String title = "Auto Transaction",
  }) {
    final entry = {
      "title": title,
      "amount": amount.toInt(),
      "type": type,
      "category": category,
      "date": DateTime.now().toString(),
    };

    setState(() {
      expenses.add(entry);
    });

    saveToBackend(entry);
  }

  // ✅ MANUAL ADD (UI)
  void addTransaction() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();

    String selectedType = "expense";
    String selectedCategory = "Food";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Add Transaction",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 15),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(labelText: "Title"),
                  ),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: "Amount"),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ChoiceChip(
                        label: Text("Expense"),
                        selected: selectedType == "expense",
                        onSelected: (_) =>
                            setModalState(() => selectedType = "expense"),
                      ),
                      ChoiceChip(
                        label: Text("Income"),
                        selected: selectedType == "income",
                        onSelected: (_) =>
                            setModalState(() => selectedType = "income"),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: ["Food", "Travel", "Shopping", "Bills", "Salary"]
                        .map((cat) => ChoiceChip(
                              label: Text(cat),
                              selected: selectedCategory == cat,
                              onSelected: (_) =>
                                  setModalState(() => selectedCategory = cat),
                            ))
                        .toList(),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (titleController.text.isEmpty ||
                          amountController.text.isEmpty) return;

                      final entry = {
                        "title": titleController.text,
                        "amount": int.parse(amountController.text),
                        "type": selectedType,
                        "category": selectedCategory,
                        "date": DateTime.now().toString(),
                      };

                      setState(() {
                        expenses.add(entry);
                      });

                      Navigator.pop(context);

                      await saveToBackend(entry);
                      _showSnack("✅ Saved to cloud");
                    },
                    child: Text("Add"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ✅ SNACKBAR
  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ✅ CONFIRMATION DIALOG
  void _showPreviewDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Confirm Transaction"),
        content: Text("₹${data['amount']} detected. Add?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Ignore"),
          ),
          ElevatedButton(
            onPressed: () {
              addTransactionDirect(
                amount: data['amount'],
                type: data['type'],
                category: data['category'],
              );
              Navigator.pop(context);
            },
            child: Text("Add"),
          ),
        ],
      ),
    );
  }

  // ✅ EXPORT CSV
  Future<void> exportCSV() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = "${dir.path}/expenses.csv";
      final file = File(path);

      String data = "Title,Amount,Type,Category,Date\n";
      for (var e in expenses) {
        data +=
            "${e['title']},${e['amount']},${e['type']},${e['category'] ?? 'Others'},${e['date'] ?? ''}\n";
      }

      await file.writeAsString(data);
      await Share.shareXFiles([XFile(path)], text: "My Expense Report");
    } catch (e) {
      print("❌ Export error: $e");
    }
  }

  // ✅ TOTAL BALANCE
  int get totalBalance {
    int total = 0;
    for (var e in expenses) {
      if (e['type'] == 'income') {
        total += e['amount'] as int;
      } else {
        total -= e['amount'] as int;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text(
          "Welcome ${widget.email}",
          style: TextStyle(fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchExpenses,
          ),
          IconButton(
            icon: Icon(Icons.download),
            onPressed: exportCSV,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.blueAccent],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Total Balance",
                    style: TextStyle(color: Colors.white70)),
                SizedBox(height: 8),
                Text(
                  "₹$totalBalance",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: expenses.isEmpty
                ? Center(child: Text("No transactions yet"))
                : ListView.builder(
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      final e = expenses[index];
                      return Card(
                        margin: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: e['type'] == 'income'
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            child: Icon(
                              e['type'] == 'income'
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: e['type'] == 'income'
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          title: Text(e['title'],
                              style:
                                  TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(e['category']),
                          trailing: Text(
                            "₹${e['amount']}",
                            style: TextStyle(
                              color: e['type'] == 'income'
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addTransaction,
        child: Icon(Icons.add),
      ),
    );
  }
}