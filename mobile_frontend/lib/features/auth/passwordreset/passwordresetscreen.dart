import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mobile_frontend/app/buttons.dart';
import 'package:mobile_frontend/features/auth/login/loginscreen.dart';
import 'package:mobile_frontend/features/auth/passwordreset/password_reset_confirm_screen.dart';
import 'package:mobile_frontend/services/authservice.dart';

class PasswordResetPage extends StatelessWidget {
  const PasswordResetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                SizedBox(height: 80),
                SizedBox(
                  height: 170,
                  width: 215,
                  child: Stack(
                    children: [
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: SvgPicture.asset('assets/forgotlock.svg'),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        child: SvgPicture.asset('assets/speechbubble.svg'),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 50),
                Text(
                  'Forgot Password',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Enter the verified email address used when creating this account',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                ForgotPasswordForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordForm extends StatefulWidget {
  const ForgotPasswordForm({super.key});

  @override
  State<ForgotPasswordForm> createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends State<ForgotPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final result = await AuthService()
        .requestPasswordReset(_emailController.text.trim());

    if (!mounted) return;
    setState(() => _loading = false);

    switch (result) {
      case PasswordResetResult.success:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PasswordResetConfirmScreen(
              email: _emailController.text.trim(),
            ),
          ),
        );
      case PasswordResetResult.userNotFound:
        setState(() => _error = 'No account found with that email.');
      case PasswordResetResult.error:
        setState(() => _error = 'Something went wrong. Please try again.');
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email Address',
              hintText: 'example@email.com',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFFF7A33)),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email address';
              }
              if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w]{2,}$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: 16),

          // Send code button
          CustomButton(
            onPressed: _loading ? () {} : () { _submit(); },
            text: _loading ? 'Sending...' : 'Send Reset Code',
          ),
          SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Never mind!'),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => LoginPage()),
                  );
                },
                child: Text('Login instead', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
