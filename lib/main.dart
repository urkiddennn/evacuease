import 'package:flutter/material.dart';
import 'package:evacuease/routes/route_generator.dart';
import 'package:evacuease/routes/route_names.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: RouteNames.loading,
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}
