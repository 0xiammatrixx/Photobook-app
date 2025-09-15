import 'package:flutter/material.dart';
import 'package:mobile_frontend/app/authservice.dart';
import 'package:mobile_frontend/features/auth/login/loginscreen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await AuthService().logout();

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Logged in/signed in successfully"),
            SizedBox(height: 30),
            SizedBox(
              width: 150,
              child: ElevatedButton(
                onPressed: () => _logout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAA0A0A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular((15)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: Text('Logout', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
