import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

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
              child: Image.asset('assets/icons/severe-weather.png',
              width: 200,)
            ),
            Positioned(
              bottom: -20,
              left: -50,
              child: Image.asset('assets/icons/severe-weather.png',
              width: 200,)
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
