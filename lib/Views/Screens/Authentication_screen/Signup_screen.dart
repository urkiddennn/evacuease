import 'package:evacuease/main_screen.dart';
import 'package:flutter/material.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String? selectedRole; // Variable to hold the selected role
    final List<String> roles = [
      'Telaje',
      'Bagong Lungsod',
      'Dagokdok'
    ]; // List of roles
    bool agreeToTerms = false; // Variable to track agreement to terms

    return Scaffold(
      appBar: AppBar(
        title: Text("Sign Up"),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Sign Up New Account",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            Text(
              "I agree to the term & conditions",
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 30),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Name',
                    filled: true,
                    fillColor: Colors.grey[300],
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: Colors.red, width: 2.0),
                    ),
                  ),
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 10),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Email',
                    filled: true,
                    fillColor: Colors.grey[300],
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: Colors.red, width: 2.0),
                    ),
                  ),
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 10),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Password',
                    filled: true,
                    fillColor: Colors.grey[300],
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: Colors.red, width: 2.0),
                    ),
                  ),
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 10),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Number',
                    filled: true,
                    fillColor: Colors.grey[300],
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: Colors.red, width: 2.0),
                    ),
                  ),
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 10),
                // DropdownButton for selecting role

                SizedBox(height: 10),
                // Radio button for agreeing to terms and conditions
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Radio<bool>(
                      value: true,
                      groupValue: agreeToTerms,
                      onChanged: (bool? value) {
                        if (value != null) {
                          agreeToTerms = value; // Update agreement status
                        }
                      },
                    ),
                    Text("I agree to the terms and conditions"),
                  ],
                ),
                SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  height: 55,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => MainScreen()));

                      // Navigate to Sign Up screen
                    },
                    child: Text(
                      'Sign Up',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                // You can add a submit button or any other widgets here
              ],
            ),
          ],
        ),
      ),
    );
  }
}
