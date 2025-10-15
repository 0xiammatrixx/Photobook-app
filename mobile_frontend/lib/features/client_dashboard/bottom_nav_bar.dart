import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mobile_frontend/features/client_dashboard/ChatScreen/chat.dart';
import 'package:mobile_frontend/features/client_dashboard/HomeScreen/home.dart';
import 'package:mobile_frontend/features/client_dashboard/HubScreen/hub.dart';
import 'package:mobile_frontend/features/client_dashboard/ProfileScreen/profile.dart';

class BottomTabs extends StatefulWidget {
  const BottomTabs({super.key});

  @override
  State<BottomTabs> createState() => _BottomTabsState();
}

class _BottomTabsState extends State<BottomTabs> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    HubScreen(),
    ChatScreen(),
    ClientProfileScreen(),
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
        selectedItemColor: Color(0xFFFF7A33),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/home_icon.svg',
              width: 24,
              height: 24,
              color: Colors.black,
            ),
            activeIcon: SvgPicture.asset(
              "assets/home_icon.svg",
              width: 24,
              height: 24,
              color: Color(0xFFFF7A33),
            ),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/hub_icon.svg',
              width: 24,
              height: 24,
              color: Colors.black,
            ),
            activeIcon: SvgPicture.asset(
              "assets/hub_icon.svg",
              width: 24,
              height: 24,
              color: Color(0xFFFF7A33),
            ),
            label: "Hub",
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/chat_icon.svg',
              width: 24,
              height: 24,
              color: Colors.black,
            ),
            activeIcon: SvgPicture.asset(
              "assets/chat_icon.svg",
              width: 24,
              height: 24,
              color: Color(0xFFFF7A33),
            ),
            label: "Chat",
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/profile_icon.svg',
              width: 24,
              height: 24,
              color: Colors.black,
            ),
            activeIcon: SvgPicture.asset(
              "assets/profile_icon.svg",
              width: 24,
              height: 24,
              color: Color(0xFFFF7A33),
            ),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
