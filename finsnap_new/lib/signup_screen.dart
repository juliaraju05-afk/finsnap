import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SignUpScreen extends StatelessWidget {

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,

      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(25),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                Icon(Icons.person_add, size: 80, color: Colors.blue),

                SizedBox(height: 10),

                Text(
                  "Create Account",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),

                SizedBox(height: 30),

                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                SizedBox(height: 20),

                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {

                      if (emailController.text.isEmpty ||
                          passwordController.text.isEmpty) {

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Enter email and password")),
                        );
                        return;
                      }

                      try {
                        final response = await http.post(
                          Uri.parse("http://10.0.2.2:5000/signup"),
                          headers: {"Content-Type": "application/json"},
                          body: jsonEncode({
                            "email": emailController.text,
                            "password": passwordController.text,
                          }),
                        );

                        print("SIGNUP STATUS: ${response.statusCode}");

                        if (response.statusCode == 200) {

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Signup successful")),
                          );

                          Navigator.pop(context); // back to login

                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Signup failed")),
                          );
                        }

                      } catch (e) {

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Server error")),
                        );
                      }
                    },
                    child: Text("Sign Up", style: TextStyle(fontSize: 18)),
                  ),
                ),

                SizedBox(height: 20),

                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("Already have an account? Login"),
                )

              ],
            ),
          ),
        ),
      ),
    );
  }
}