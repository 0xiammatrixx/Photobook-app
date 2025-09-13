import 'package:flutter/material.dart';
import 'package:mobile_frontend/app/splashscreen/splashscreen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_frontend/features/auth/login/loginscreen.dart';
import 'package:mobile_frontend/features/auth/passwordreset/passwordmail.dart';
import 'package:mobile_frontend/features/auth/signup/SignUpScreen.dart';
import 'package:mobile_frontend/features/auth/verificationscreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

  runApp(MyApp(seenOnboarding: seenOnboarding));
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
      home: MailSent(), //seenOnboarding ? SignUpPage() : OnboardingPage(),
    );
  }
}


