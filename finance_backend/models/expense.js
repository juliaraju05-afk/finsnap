const mongoose = require("mongoose");

const expenseSchema = new mongoose.Schema({
  userEmail: String,
  title: String,
  amount: Number,
  category: String,
  date: String,
  note: String,
  type: String,
});

module.exports = mongoose.model("Expense", expenseSchema);