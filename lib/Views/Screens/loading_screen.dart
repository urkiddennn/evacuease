import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    await Future.delayed(const Duration(seconds: 3)); // Loading delay

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final bool hasSeenIntro = prefs.getBool('hasSeenIntro') ?? false;

    print(
        "Checking login status: isLoggedIn=$isLoggedIn, hasSeenIntro=$hasSeenIntro");

    if (isLoggedIn) {
      print("User is logged in, navigating to MainScreen");
      Navigator.pushReplacementNamed(context, RouteNames.mainScreen);
    } else if (!hasSeenIntro) {
      print("First use, navigating to FirstScreen");
      await prefs.setBool('hasSeenIntro', true);
      Navigator.pushReplacementNamed(context, RouteNames.firstScreen);
    } else {
      print("Not logged in and intro seen, navigating to SigninScreen");
      Navigator.pushReplacementNamed(context, RouteNames.signin);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.red[700],
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
