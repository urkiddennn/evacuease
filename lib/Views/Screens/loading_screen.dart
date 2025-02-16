import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:evacuease/Controllers/auth_provider/auth_provider.dart'; // Import the AuthProvider
import 'package:evacuease/routes/route_names.dart'; // Import RouteNames
import 'package:evacuease/Views/Screens/Introduction/first_screen.dart'; // Import FirstScreen
import 'package:evacuease/main_screen.dart'; // Import MainScreen

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
    // Simulate a delay for loading
    await Future.delayed(const Duration(seconds: 3));

    // Access the AuthProvider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Check if the user is already logged in
    await authProvider.checkLoginStatus();

    // Navigate based on login status
    if (authProvider.isLoggedIn) {
      // If logged in, navigate to the MainScreen
      Navigator.pushReplacementNamed(context, RouteNames.mainScreen);
    } else {
      // If not logged in, navigate to the FirstScreen (Introduction)
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
