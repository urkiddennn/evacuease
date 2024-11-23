import 'package:evacuease/Views/Screens/Main/Home_screen.dart';
import 'package:evacuease/Views/Screens/Main/location_screen.dart';
import 'package:evacuease/Views/Screens/Main/notification_screen.dart';
import 'package:evacuease/Views/Screens/Main/user_screen.dart';
import 'package:evacuease/main_screen.dart';
import 'package:flutter/material.dart';
//import 'package:evacuease/Views/Screens/Introduction/First_screen.dart';
//import 'package:evacuease/Views/Screens/loading_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),

      initialRoute: '/', // Starting route
      routes: {
        '/': (context) => MainScreen(), // Starting route
        '/Home_screen': (context) => HomeScreen(), // Home/Main Screen
        '/location_screen': (context) =>
            const LocationScreen(), // Example route
        '/loading_screen': (context) => const NotificationScreen(),
        '/user_screen': (context) => const UserScreen(),
      },
    );
  }
}
