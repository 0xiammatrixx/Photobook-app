import 'package:flutter/material.dart';
import 'package:mobile_frontend/features/dashboard/BookScreen/book.dart';
import 'package:mobile_frontend/features/dashboard/ChatScreen/chat.dart';
import 'package:mobile_frontend/features/dashboard/HomeScreen/home.dart';
import 'package:mobile_frontend/features/dashboard/HubScreen/hub.dart';
import 'package:mobile_frontend/features/dashboard/ProfileScreen/profile.dart';

class BottomTabs extends StatefulWidget {
  const BottomTabs({super.key});

  @override
  State<BottomTabs> createState() => _BottomTabsState();
}

class _BottomTabsState extends State<BottomTabs> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    BookScreen(),
    HubScreen(),
    ChatScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: "Book"),
          BottomNavigationBarItem(icon: Icon(Icons.movie_filter_outlined), label: "Hub"),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: "Chat"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
        ],
      ),
    );
  }
}
