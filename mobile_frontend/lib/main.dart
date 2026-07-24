import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_frontend/providers/call_provider.dart';
import 'package:mobile_frontend/providers/chat_provider.dart';
import 'package:mobile_frontend/providers/search_provider.dart';
import 'package:mobile_frontend/providers/sessions_provider.dart';
import 'package:mobile_frontend/features/shared/call_screen.dart';
import 'providers/booking_provider.dart';
import 'package:mobile_frontend/services/profileservice.dart';
import 'features/client_dashboard/bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/profile_provider.dart';
import 'providers/ratecard_provider.dart';
import 'providers/user_provider.dart';
import 'features/auth/login/loginscreen.dart';
import 'features/auth/roleSelection.dart';
import 'features/creative_dashboard/bottom_nav_bar.dart';
import 'services/authservice.dart';
import 'app/splashscreen/splashscreen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

  final userProvider = UserProvider();
  await userProvider.loadUser();

  bool tokenValid = false;
  if (userProvider.token != null) {
    try {
      final profileService = ProfilePortfolioService();
      await profileService.getProfile(token: userProvider.token!);
      tokenValid = true;
    } catch (e) {
      await AuthService().logout();
      await userProvider.loadUser();
      tokenValid = false;
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: userProvider),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => RateCardProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => SessionsProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => CallProvider()),
      ],
      child: MyApp(
        initialUser: tokenValid ? userProvider.user : null,
        seenOnboarding: seenOnboarding,
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  final Map<String, dynamic>? initialUser;
  final bool seenOnboarding;

  const MyApp({
    super.key,
    required this.initialUser,
    required this.seenOnboarding,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final callProvider = context.read<CallProvider>();
      final chatProvider = context.read<ChatProvider>();
      callProvider.registerSignaling();
      callProvider.onIncomingCall = () {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const CallScreen()),
        );
      };
      callProvider.resolvePeerInfo = (userId) {
        for (final conv in chatProvider.conversations) {
          final participants = List<dynamic>.from(conv['participants'] ?? []);
          for (final p in participants) {
            if (p is Map && p['id'] == userId) {
              return {
                'name': (p['businessName'] ?? p['displayName'] ?? p['name'])
                    ?.toString(),
                'avatarUrl': p['profilePhotoUrl']?.toString(),
              };
            }
          }
        }
        return null;
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'PhotoBook',
      theme: ThemeData(
        textTheme: GoogleFonts.quicksandTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: _getStartPage(),
    );
  }

  Widget _getStartPage() {
    if (!widget.seenOnboarding) {
      return OnboardingPage();
    }
    if (widget.initialUser == null) {
      return LoginPage();
    }
    final role = widget.initialUser!['role']?.toString().toLowerCase();

    if (role == 'photographer') {
      return const CreativeBottomTabs();
    } else if (role == 'client') {
      return const BottomTabs();
    } else {
      return const RoleSelectionPage();
    }
  }
}