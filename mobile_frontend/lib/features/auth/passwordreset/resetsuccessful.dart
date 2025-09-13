import 'package:flutter/material.dart';
import 'package:mobile_frontend/app/buttons.dart';
import 'package:mobile_frontend/features/auth/login/loginscreen.dart';

class ResetSuccessful extends StatelessWidget {
  const ResetSuccessful({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              SizedBox(height: 50),
              Image.asset('assets/resetsuccessful.png'),
              SizedBox(height: 20),
              Text('Password Reset Successful', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
              SizedBox(height: 25),
              Text(
                'Your password has been successfully changed, head back to login',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
              ),
              SizedBox(height: 15),
              CustomButton(
                text: 'Go back to login',
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => LoginPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
