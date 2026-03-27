require("dotenv").config();

const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");

const User = require("./models/User");
const Expense = require("./models/Expense");

const app = express();

app.use(cors());
app.use(express.json());

// =======================
// ✅ CONNECT DB
// =======================
mongoose.connect(process.env.MONGO_URI)
.then(() => console.log("🔥 MongoDB Connected"))
.catch(err => console.log("DB ERROR:", err));

// =======================
// ✅ TEST ROUTE
// =======================
app.get("/", (req, res) => {
  res.send("Backend running 🚀");
});

// =======================
// ✅ SIGNUP
// =======================
app.post("/signup", async (req, res) => {
  try {
    const { email, password } = req.body;

    console.log("Signup request:", email, password);

    if (!email || !password) {
      return res.status(400).json({ message: "Missing fields" });
    }

    const exists = await User.findOne({ email });

    if (exists) {
      return res.status(400).json({ message: "User already exists" });
    }

    const user = new User({ email, password });
    await user.save();

    console.log("User saved!");

    res.json({ message: "Signup successful" });

  } catch (err) {
    console.log("Signup error:", err);
    res.status(500).json({ message: "Server error" });
  }
});

// =======================
// ✅ LOGIN
// =======================
app.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;

    console.log("Login request:", email, password);

    const user = await User.findOne({ email });

    if (!user) {
      return res.status(401).json({ message: "User not found" });
    }

    if (user.password !== password) {
      return res.status(401).json({ message: "Wrong password" });
    }

    console.log("Login success!");

    res.json({ message: "Login successful" });

  } catch (err) {
    console.log("Login error:", err);
    res.status(500).json({ message: "Server error" });
  }
});

// =======================
// ✅ ADD EXPENSE (FIXED)
// =======================
app.post("/add-expense", async (req, res) => {
  try {

    console.log("=================================");
    console.log("📦 FULL BODY:");
    console.log(JSON.stringify(req.body, null, 2));
    console.log("📧 EMAIL:", req.body.userEmail);
    console.log("=================================");

    if (!req.body.userEmail || req.body.userEmail === "") {
      return res.status(400).json({ message: "Email missing" });
    }

    const expense = new Expense(req.body);
    await expense.save();

    console.log("✅ Expense saved!");

    res.json({ message: "Expense saved" });

  } catch (err) {
    console.log("❌ Expense error:", err);
    res.status(500).json({ message: "Error saving expense" });
  }
});

// =======================
// ✅ GET EXPENSES
// =======================
app.get("/expenses/:email", async (req, res) => {
  try {
    const expenses = await Expense.find({
      userEmail: req.params.email
    });

    res.json(expenses);

  } catch (err) {
    res.status(500).json({ message: "Error fetching expenses" });
  }
});

// =======================
app.listen(5000, () => {
  console.log("🚀 Server running on port 5000");
});