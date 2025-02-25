import 'package:evacuease/Views/Screens/main/home_screen.dart';
import 'package:evacuease/Views/Screens/main/location_screen.dart';
import 'package:evacuease/Views/Screens/main/notification_screen.dart';
import 'package:evacuease/Views/Screens/main/user_screen.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex; // Add parameter for initial page index

  const MainScreen({super.key, this.initialIndex = 0}); // Default to 0 (Home)

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentPageIndex; // Use late to initialize in initState

  final List<Widget> _pages = [
    HomeScreen(),
    LocationScreen(),
    NotificationScreen(),
    UserScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentPageIndex = widget.initialIndex; // Set initial index from parameter
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentPageIndex, // Display only the selected page
        children: _pages, // Keep all pages in memory
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentPageIndex, // Set the currently selected tab
        onTap: (index) {
          setState(() {
            _currentPageIndex = index; // Update selected tab index
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
        selectedItemColor: Colors.red, // Color for selected tab
        unselectedItemColor: Colors.grey, // Color for unselected tabs
        showUnselectedLabels: true, // Show labels for unselected tabs
      ),
    );
  }
}
