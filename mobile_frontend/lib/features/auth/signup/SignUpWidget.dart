import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile_frontend/app/buttons.dart';
import 'package:url_launcher/url_launcher.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _handleSignUp() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Backend logic
      print('Signing up with: $name, $email, $password');
    }
  }

  void _signInWithGoogle() {
    // Google SignIn
    print('Google Sign-In');
  }

  void _signInWithFacebook() {
    // Facebook SignIn
    print('Facebook Sign-In');
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFFF7A33)),
              ),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Enter your name' : null,
          ),
          const SizedBox(height: 16),

          // Email
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email address',
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFFF7A33)),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Enter your email';
              if (!value.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFFF7A33)),
              ),
            ),
            obscureText: true,
            validator: (value) => value == null || value.length < 6
                ? 'Password must be at least 6 characters'
                : null,
          ),

          const SizedBox(height: 24),

          // Continue button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: CustomButton(onPressed: _handleSignUp, text: 'Continue'),
          ),

          const SizedBox(height: 24),

          RichText(
            text: TextSpan(
              text: 'By clicking continue, you agree to our ',
              style: TextStyle(
                color: Color(0xFF181818),
                fontWeight: FontWeight.w400,
              ),
              children: [
                TextSpan(
                  text: 'Terms of Service',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF181818),
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async {
                      final url = Uri.parse("https://example.com/terms");
                      if (await canLaunchUrl(url, )) {
                        launchUrl(url, mode: LaunchMode.externalApplication,);
                      }
                      print("Terms of Service clicked");
                    },
                ),
                TextSpan(
                  text: ' and ',
                  style: TextStyle(
                    color: Color(0xFF181818),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF181818),
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async {
                      final url = Uri.parse("https://example.com/privacy");
                      if (await canLaunchUrl(url)) {
                        launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                      print("Privacy Policy clicked");
                    },
                ),
                TextSpan(text: '.'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // OR divider
          Row(
            children: const [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('or'),
              ),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 24),

          // Google button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _signInWithGoogle,
              style: OutlinedButton.styleFrom(
                backgroundColor: Color(0xFFEEEEEE),
                side: BorderSide(color: Color(0xFFEEEEEE)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: SvgPicture.asset('assets/googleicon.svg', height: 20),
              label: const Text(
                'Continue with Google',
                style: TextStyle(
                  color: Color(0xFF181818),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Facebook button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _signInWithFacebook,
              style: OutlinedButton.styleFrom(
                backgroundColor: Color(0xFFEEEEEE),
                side: BorderSide(color: Color(0xFFEEEEEE)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: SvgPicture.asset('assets/facebookicon.svg', height: 20),
              label: const Text(
                'Continue with Facebook',
                style: TextStyle(
                  color: Color(0xFF181818),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
