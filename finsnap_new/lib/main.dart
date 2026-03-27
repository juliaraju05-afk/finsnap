import 'package:flutter/material.dart';
import 'package:finsnap/login_screen.dart';
void main() {
  runApp(FinSnapApp());
}

class FinSnapApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FinSnap',
      home: LoginScreen(),
    );
  }
}