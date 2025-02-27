import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:evacuease/routes/route_names.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Simulate a delay for loading (optional, can remove if not needed)
    await Future.delayed(const Duration(seconds: 3));

    // Check Firebase authentication state directly
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // If user is logged in, navigate to MainScreen
      Navigator.pushReplacementNamed(context, RouteNames.mainScreen);
    } else {
      // If not logged in, navigate to FirstScreen (Introduction)
      Navigator.pushReplacementNamed(context, RouteNames.firstScreen);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.red[700], // Red background
        child: Stack(
          children: [
            Positioned(
              top: -20,
              right: -50,
              child: Image.asset(
                'assets/icons/severe-weather.png',
                width: 200,
              ),
            ),
            Positioned(
              bottom: -20,
              left: -50,
              child: Image.asset(
                'assets/icons/severe-weather.png',
                width: 200,
              ),
            ),
            Center(
              child: Text(
                'EvacuEase',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
