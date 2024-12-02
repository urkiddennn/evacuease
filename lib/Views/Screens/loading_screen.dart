import 'package:evacuease/Views/Screens/Introduction/First_screen.dart';
import 'package:flutter/material.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    // Simulate a delay for loading
    Future.delayed(const Duration(seconds: 3), () {
      // Navigate to the Getting Started screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const FirstScreen()),
      );
    });
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
