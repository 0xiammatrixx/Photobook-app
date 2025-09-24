import 'package:flutter/material.dart';
import 'package:mobile_frontend/app/authservice.dart';
import 'package:mobile_frontend/features/auth/roleSelection.dart';
import 'package:pinput/pinput.dart';

class VerificationPage extends StatelessWidget {
  final String email;
  const VerificationPage({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 264,
                  child: Column(
                    children: [
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
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                VerificationForm(email: email),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class VerificationForm extends StatefulWidget {
  final String email;
  const VerificationForm({super.key, required this.email});

  @override
  State<VerificationForm> createState() => _VerificationFormState();
}

class _VerificationFormState extends State<VerificationForm> {
  final AuthService _authService = AuthService();
  final TextEditingController _pinController = TextEditingController();

  Future<void> _verifyCode(String code) async {
    final verified = await _authService.verifyEmail(widget.email, code);

    if (!mounted) return;

    if (verified) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => RoleSelectionPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid code. Please try again.')),
      );
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Pinput(
          controller: _pinController,
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
        ),
        TextButton(
          onPressed: () async {
            final success = await _authService.resendVerification(widget.email);
            if (success) {
              _pinController.clear();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Verification code resent!')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to resend code')),
              );
            }
          },
          child: const Text(
            "Resend Code",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
