import 'package:evacuease/Models/home_model.dart';
import 'package:evacuease/Views/Screens/main/risk_area_screen.dart';
import 'package:evacuease/Views/Screens/main/hazard_rank_screen.dart';
import 'package:flutter/material.dart';
import 'package:evacuease/Views/Screens/main/home_screen.dart';
import 'package:evacuease/Views/Screens/main/location_screen.dart';
import 'package:evacuease/Views/Screens/main/notification_screen.dart';
import 'package:evacuease/Views/Screens/main/user_screen.dart';
import 'package:evacuease/Views/Screens/loading_screen.dart';
import 'package:evacuease/Views/Screens/Introduction/first_screen.dart';
import 'package:evacuease/Views/Screens/authentication_screen/signin_screen.dart';
import '../Views/Screens/authentication_screen/Signup_screen.dart';
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
      case RouteNames.signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      case RouteNames.mainScreen:
        return MaterialPageRoute(builder: (_) => const MainScreen());
      case RouteNames.homeScreen:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case RouteNames.locationScreen:
        return MaterialPageRoute(builder: (_) => const LocationScreen());
      case RouteNames.notificationScreen:
        return MaterialPageRoute(builder: (_) => const NotificationScreen());
      case RouteNames.userScreen:
        return MaterialPageRoute(builder: (_) => const UserScreen());
      case RouteNames.riskArea:
        return MaterialPageRoute(builder: (_) => const RiskAreaScreen());
      case RouteNames.hazardRank:
        final args = settings.arguments;
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) => HazardRankScreen(hazardType: args),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Error: No hazard type provided'),
            ),
          ),
        );
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
