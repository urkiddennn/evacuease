import 'package:flutter/material.dart';
import 'package:evacuease/Views/Screens/main/home_screen.dart';
import 'package:evacuease/Views/Screens/main/location_screen.dart';
import 'package:evacuease/Views/Screens/main/notification_screen.dart';
import 'package:evacuease/Views/Screens/main/user_screen.dart';
import 'package:evacuease/Views/Screens/loading_screen.dart';
import 'package:evacuease/Views/Screens/Introduction/first_screen.dart'; // Add this import
import 'package:evacuease/Views/Screens/authentication_screen/signin_screen.dart'; // Add this import
import 'package:evacuease/main_screen.dart';
import 'route_names.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.loading:
        return MaterialPageRoute(builder: (_) => const LoadingScreen());
      case RouteNames.firstScreen:
        return MaterialPageRoute(builder: (_) => const FirstScreen());
      case RouteNames.signin:
        return MaterialPageRoute(builder: (_) => const SigninScreen());
      case RouteNames.mainScreen:
        return MaterialPageRoute(builder: (_) => MainScreen());
      case RouteNames.homeScreen:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case RouteNames.locationScreen:
        return MaterialPageRoute(builder: (_) => const LocationScreen());
      case RouteNames.notificationScreen:
        return MaterialPageRoute(builder: (_) => const NotificationScreen());
      case RouteNames.userScreen:
        return MaterialPageRoute(builder: (_) => const UserScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
