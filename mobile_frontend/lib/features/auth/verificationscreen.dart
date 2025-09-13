import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

class VerificationPage extends StatelessWidget {
  const VerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                'Verification',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Enter the 6 digit code sent to your registered mail',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black, fontSize: 14),
              ),
              SizedBox(height: 40),

              VerificationForm()
            ],
          ),
        ),
      ),
    );
  }
}

class VerificationForm extends StatefulWidget {
  const VerificationForm({super.key});

  @override
  State<VerificationForm> createState() => _VerificationFormState();
}

class _VerificationFormState extends State<VerificationForm> {
  void _verifyCode(String code) {
    // Call  backend verification logic
    print('Verifying code: $code');
    // e.g. AuthService.verifyEmailCode(code);
  }

  @override
  Widget build(BuildContext context) {
    return Pinput(
      length: 6,
      showCursor: true,
      onCompleted: (pin) => _verifyCode(pin),
      defaultPinTheme: PinTheme(
        width: 50,
        height: 60,
        textStyle: const TextStyle(fontSize: 24, color: Colors.black),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
