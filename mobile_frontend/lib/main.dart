import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_frontend/app/profile_provider.dart';
import 'package:mobile_frontend/app/splashscreen/splashscreen.dart';
import 'package:mobile_frontend/features/client_dashboard/bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile_frontend/app/ratecard_provider.dart';
import 'package:mobile_frontend/app/user_provider.dart';
import 'package:mobile_frontend/features/auth/login/loginscreen.dart';
import 'package:mobile_frontend/features/auth/signup/signUpScreen.dart';
import 'package:mobile_frontend/features/auth/roleSelection.dart';
import 'package:mobile_frontend/features/auth/passwordreset/newpasswordpage.dart';
import 'package:mobile_frontend/features/auth/passwordreset/passwordmail.dart';
import 'package:mobile_frontend/features/auth/passwordreset/resetsuccessful.dart';
import 'package:mobile_frontend/features/auth/verificationscreen.dart';
import 'package:mobile_frontend/features/creative_dashboard/bottom_nav_bar.dart';
import 'package:mobile_frontend/services/authservice.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

  final authService = AuthService();
  final savedUser = await authService.getUser();

  final userProvider = UserProvider();
  await userProvider.loadUser();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: userProvider),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => RateCardProvider()),
      ],
      child: MyApp(
        initialUser: savedUser,
        seenOnboarding: seenOnboarding,
        
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Map<String, dynamic>? initialUser;
  final bool seenOnboarding;

  const MyApp({
    super.key,
    required this.initialUser,
    required this.seenOnboarding,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
    if (!seenOnboarding) {
      return OnboardingPage();
    }
    if (initialUser == null) {
      return LoginPage();
    }
    final role = initialUser!['role']?.toString().toLowerCase();

    if (role == 'photographer') {
      return const CreativeBottomTabs(); 
    } else if (role == 'client') {
      return const BottomTabs();
    } else {
      return const RoleSelectionPage();
    }
  }
}
