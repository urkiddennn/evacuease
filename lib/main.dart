import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:evacuease/Controllers/auth_provider/auth_provider.dart'; // Updated import
import 'package:evacuease/routes/route_generator.dart'; // Import RouteGenerator
import 'package:evacuease/routes/route_names.dart'; // Import RouteNames
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print("Initializing Firebase...");
  await Firebase.initializeApp();
  print("Firebase initialized successfully!");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          AuthProviders(), // Use the updated AuthProviders class
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'EvacuEase',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
          useMaterial3: true,
        ),
        initialRoute: RouteNames.loading, // Set initial route
        onGenerateRoute: RouteGenerator.generateRoute, // Use RouteGenerator
      ),
    );
  }
}
