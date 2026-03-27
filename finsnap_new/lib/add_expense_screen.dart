import 'package:flutter/material.dart';

class AddExpenseScreen extends StatefulWidget {
  final String email;

  AddExpenseScreen({required this.email});

  @override
  _AddExpenseScreenState createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {

  final TextEditingController titleController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  String type = "debit";
  String selectedCategory = "Food";

  // Expense categories
  List expenseCategories = [
    {"name": "Food", "icon": Icons.fastfood},
    {"name": "Travel", "icon": Icons.directions_car},
    {"name": "Shopping", "icon": Icons.shopping_bag},
    {"name": "Bills", "icon": Icons.receipt},
    {"name": "Entertainment", "icon": Icons.movie},
    {"name": "Health", "icon": Icons.favorite},
    {"name": "Others", "icon": Icons.category},
  ];

  // Income categories
  List incomeCategories = [
    {"name": "Salary", "icon": Icons.account_balance_wallet},
    {"name": "Freelance", "icon": Icons.laptop},
    {"name": "Business", "icon": Icons.store},
    {"name": "Gift", "icon": Icons.card_giftcard},
    {"name": "Others", "icon": Icons.category},
  ];

  @override
  Widget build(BuildContext context) {

    final currentCategories =
        type == "debit" ? expenseCategories : incomeCategories;

    return Scaffold(
      backgroundColor: Color(0xFF0B1D2A),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Add Transaction"),
      ),

      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [

            // ===== TITLE =====
            TextField(
              controller: titleController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Title",
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
              ),
            ),

            SizedBox(height: 15),

            // ===== AMOUNT =====
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Amount",
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
              ),
            ),

            SizedBox(height: 20),

            // ===== TYPE SELECT =====
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [

                ChoiceChip(
                  label: Text("Expense"),
                  selected: type == "debit",
                  onSelected: (_) {
                    setState(() {
                      type = "debit";
                      selectedCategory = "Food"; // reset
                    });
                  },
                ),

                ChoiceChip(
                  label: Text("Income"),
                  selected: type == "credit",
                  onSelected: (_) {
                    setState(() {
                      type = "credit";
                      selectedCategory = "Salary"; // reset
                    });
                  },
                ),
              ],
            ),

            SizedBox(height: 25),

            // ===== CATEGORY TITLE =====
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Category",
                style: TextStyle(color: Colors.white70),
              ),
            ),

            SizedBox(height: 10),

            // ===== CATEGORY UI =====
            Container(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: currentCategories.length,
                itemBuilder: (context, index) {

                  final cat = currentCategories[index];
                  bool isSelected = selectedCategory == cat['name'];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategory = cat['name'];
                      });
                    },

                    child: Container(
                      width: 85,
                      margin: EdgeInsets.symmetric(horizontal: 8),

                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.orange
                            : Color(0xFF132A3A),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 5,
                          )
                        ],
                      ),

                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                          Icon(
                            cat['icon'],
                            color: isSelected
                                ? Colors.white
                                : Colors.grey,
                          ),

                          SizedBox(height: 5),

                          Text(
                            cat['name'],
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey,
                              fontSize: 12,
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 30),

            // ===== ADD BUTTON =====
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: Size(double.infinity, 50),
              ),
              onPressed: () {

                if (titleController.text.isEmpty ||
                    amountController.text.isEmpty) {
                  return;
                }

                final newExpense = {
                  "title": titleController.text,
                  "amount": double.parse(amountController.text),
                  "type": type,
                  "category": selectedCategory,
                };

                Navigator.pop(context, newExpense);
              },
              child: Text("Add Transaction"),
            )
          ],
        ),
      ),
    );
  }
}