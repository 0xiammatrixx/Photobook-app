import 'package:flutter/material.dart';
import 'package:mobile_frontend/app/splashscreen/splashscreen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_frontend/app/user_provider.dart';
import 'package:mobile_frontend/features/auth/login/loginscreen.dart';
import 'package:mobile_frontend/features/auth/passwordreset/newpasswordpage.dart';
import 'package:mobile_frontend/features/auth/passwordreset/passwordmail.dart';
import 'package:mobile_frontend/features/auth/passwordreset/resetsuccessful.dart';
import 'package:mobile_frontend/features/auth/roleSelection.dart';
import 'package:mobile_frontend/features/auth/signup/signUpScreen.dart';
import 'package:mobile_frontend/features/auth/verificationscreen.dart';
import 'package:mobile_frontend/features/creative_dashboard/bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

  runApp(
  ChangeNotifierProvider(
      create: (_) => UserProvider()..loadUser(),

  child: MyApp(seenOnboarding: seenOnboarding),
  ),
  );
}

class MyApp extends StatelessWidget {
  final bool seenOnboarding;
  const MyApp({super.key, required this.seenOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PhotoBook',
      theme: ThemeData(
        textTheme: GoogleFonts.quicksandTextTheme(Theme.of(context).textTheme)
      ),
      home: CreativeBottomTabs(),//seenOnboarding ? LoginPage() : OnboardingPage(),
    );
  }
}


