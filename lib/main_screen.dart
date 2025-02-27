import 'package:evacuease/Views/Screens/main/home_screen.dart';
import 'package:evacuease/Views/Screens/main/location_screen.dart';
import 'package:evacuease/Views/Screens/main/notification_screen.dart';
import 'package:evacuease/Views/Screens/main/user_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:evacuease/Controllers/auth_provider/auth_provider.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentPageIndex;

  final List<Widget> _pages = [
    const HomeScreen(),
    const LocationScreen(),
    const NotificationScreen(),
    const UserScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentPageIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentPageIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentPageIndex,
        onTap: (index) {
          setState(() {
            _currentPageIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: "Location",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: "Notification",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "User",
          ),
        ],
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
    );
  }
}
