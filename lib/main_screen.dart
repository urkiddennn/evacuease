import 'package:evacuease/Views/Screens/Main/Home_screen.dart';
import 'package:evacuease/Views/Screens/Main/location_screen.dart';
import 'package:evacuease/Views/Screens/Main/notification_screen.dart';
import 'package:evacuease/Views/Screens/Main/user_screen.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentPageIndex = 0;

  final List<Widget> _pages = [
    HomeScreen(),
    LocationScreen(),
    NotificationScreen(),
    UserScreen()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Page content
          IndexedStack(
            index: _currentPageIndex, // Display the selected page
            children: _pages, // Keep all pages in memory for smooth transitions
          ),

          // Persistent BottomNavigationBar
          Align(
            alignment: Alignment.bottomCenter, // Stick to the bottom
            child: Container(
              color: Colors.white, // Optional background color for clarity
              child: BottomNavigationBar(
                currentIndex:
                    _currentPageIndex, // Set the currently selected tab
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
            ),
          ),
        ],
      ),
    );
  }
}
