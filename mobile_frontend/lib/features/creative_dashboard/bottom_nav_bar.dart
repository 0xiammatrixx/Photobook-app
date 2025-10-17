import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mobile_frontend/features/creative_dashboard/AddPortfolioPage/addportfoliopage.dart';
import 'package:mobile_frontend/features/creative_dashboard/BookingsPage/bookingspage.dart';
import 'package:mobile_frontend/features/creative_dashboard/ChatPage/chatpage.dart';
import 'package:mobile_frontend/features/creative_dashboard/HomePage/screen/homepage.dart';
import 'package:mobile_frontend/features/creative_dashboard/ProfilePage/profilepage.dart';

class CreativeBottomTabs extends StatefulWidget {
  const CreativeBottomTabs({super.key});

  @override
  State<CreativeBottomTabs> createState() => _CreativeBottomTabsState();
}

class _CreativeBottomTabsState extends State<CreativeBottomTabs> {
  int _selectedIndex = 0;
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // 👇 force rebuild only Home when selected
          CreativeHomePage(key: ValueKey("home-$_selectedIndex")),
          const CreativeBookingsPage(),
          const AddPortfolioPage(),
          const CreativeChatPage(),
          const CreativeProfilePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFFFF7A33),
        unselectedItemColor: Colors.black,
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
              'assets/bookings_icon.svg',
              width: 24,
              height: 24,
              color: Colors.black,
            ),
            activeIcon: SvgPicture.asset(
              "assets/bookings_icon.svg",
              width: 24,
              height: 24,
              color: Color(0xFFFF7A33),
            ),
            label: "Bookings",
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset('assets/+.svg', width: 24, height: 24),
            label: "Add",
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
