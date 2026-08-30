import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mobile_frontend/features/client_dashboard/BookingsScreen/client_bookings.dart';
import 'package:mobile_frontend/features/client_dashboard/ChatScreen/chat.dart';
import 'package:mobile_frontend/features/client_dashboard/HomeScreen/home.dart';
import 'package:mobile_frontend/features/client_dashboard/HubScreen/hub.dart';
import 'package:mobile_frontend/features/client_dashboard/ProfileScreen/profile.dart';
import 'package:mobile_frontend/providers/chat_provider.dart';
import 'package:provider/provider.dart';

class BottomTabs extends StatefulWidget {
  /// Global tab controller so other screens (e.g. payment success) can
  /// switch tabs (0=Home, 1=Bookings, 2=Hub, 3=Chat, 4=Profile).
  static final ValueNotifier<int> tabIndex = ValueNotifier<int>(0);

  const BottomTabs({super.key});

  @override
  State<BottomTabs> createState() => _BottomTabsState();
}

class _BottomTabsState extends State<BottomTabs> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = BottomTabs.tabIndex.value;
    BottomTabs.tabIndex.addListener(_onExternalTab);
  }

  @override
  void dispose() {
    BottomTabs.tabIndex.removeListener(_onExternalTab);
    super.dispose();
  }

  void _onExternalTab() {
    if (mounted && _selectedIndex != BottomTabs.tabIndex.value) {
      setState(() => _selectedIndex = BottomTabs.tabIndex.value);
    }
  }

  final List<Widget> _pages = [
    HomeScreen(),
    ClientBookingsPage(),
    HubScreen(),
    ChatScreen(),
    ClientProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    BottomTabs.tabIndex.value = index;
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
              'assets/clientbooking.svg',
              width: 24,
              height: 24,
              color: Colors.black,
            ),
            activeIcon: SvgPicture.asset(
              'assets/clientbooking.svg',
              width: 24,
              height: 24,
              color: Color(0xFFFF7A33),
            ),
            label: 'Bookings',
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
