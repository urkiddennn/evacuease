import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:evacuease/Controllers/auth_provider/auth_provider.dart';
import 'package:evacuease/Controllers/home_controller.dart';
import 'package:evacuease/routes/route_generator.dart';
import 'package:evacuease/routes/route_names.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:evacuease/Controllers/language.dart';

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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProviders()),
        ChangeNotifierProvider(create: (context) => Language()),
        Provider(
            create: (context) =>
                HomeController()), // Use Provider for HomeController
      ],
      child: SafeArea(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'EvacuEase',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
            useMaterial3: true,
          ),
          initialRoute: RouteNames.loading,
          onGenerateRoute: RouteGenerator.generateRoute,
        ),
      ),
    );
  }
}
