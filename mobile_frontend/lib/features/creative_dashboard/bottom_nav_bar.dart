import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mobile_frontend/features/creative_dashboard/AddPortfolioPage/addportfoliopage.dart';
import 'package:mobile_frontend/features/creative_dashboard/BookingsPage/bookingspage.dart';
import 'package:mobile_frontend/features/creative_dashboard/ChatPage/chatpage.dart';
import 'package:mobile_frontend/features/creative_dashboard/HomePage/screen/homepage.dart';
import 'package:mobile_frontend/features/creative_dashboard/ProfilePage/profilepage.dart';
import 'package:mobile_frontend/providers/chat_provider.dart';
import 'package:provider/provider.dart';

class CreativeBottomTabs extends StatefulWidget {
  /// Global tab controller so other screens (e.g. notification deep-links) can
  /// switch tabs (0=Home, 1=Bookings, 2=Add Portfolio, 3=Chat, 4=Profile).
  static final ValueNotifier<int> tabIndex = ValueNotifier<int>(0);

  const CreativeBottomTabs({super.key});

  @override
  State<CreativeBottomTabs> createState() => _CreativeBottomTabsState();
}

class _CreativeBottomTabsState extends State<CreativeBottomTabs> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = CreativeBottomTabs.tabIndex.value;
    CreativeBottomTabs.tabIndex.addListener(_onExternalTab);
  }

  @override
  void dispose() {
    CreativeBottomTabs.tabIndex.removeListener(_onExternalTab);
    super.dispose();
  }

  void _onExternalTab() {
    if (mounted && _selectedIndex != CreativeBottomTabs.tabIndex.value) {
      setState(() => _selectedIndex = CreativeBottomTabs.tabIndex.value);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    CreativeBottomTabs.tabIndex.value = index;
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
            icon: Consumer<ChatProvider>(
              builder: (context, chatProvider, _) {
                final unread = chatProvider.totalUnread;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SvgPicture.asset(
                      'assets/chat_icon.svg',
                      width: 24,
                      height: 24,
                      color: Colors.black,
                    ),
                    if (unread > 0)
                      Positioned(
                        top: -4,
                        right: -6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF7A33),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            unread > 99 ? '99+' : '$unread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            activeIcon: SvgPicture.asset(
              'assets/chat_icon.svg',
              width: 24,
              height: 24,
              color: Color(0xFFFF7A33),
            ),
            label: 'Chat',
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
