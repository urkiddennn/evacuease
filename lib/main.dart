import 'package:evacuease/Controllers/auth_provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:evacuease/routes/route_generator.dart'; // Import RouteGenerator
import 'package:evacuease/routes/route_names.dart'; // Import RouteNames

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthProvider(),
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
