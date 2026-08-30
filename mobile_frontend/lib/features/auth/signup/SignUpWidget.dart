import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile_frontend/features/client_dashboard/bottom_nav_bar.dart';
import 'package:mobile_frontend/features/creative_dashboard/bottom_nav_bar.dart';
import 'package:mobile_frontend/providers/user_provider.dart';
import 'package:mobile_frontend/services/authservice.dart';
import 'package:mobile_frontend/services/push_notification_service.dart';
import 'package:mobile_frontend/app/buttons.dart';
import 'package:mobile_frontend/features/auth/login/loginscreen.dart';
import 'package:mobile_frontend/features/auth/roleSelection.dart';
import 'package:mobile_frontend/features/auth/verificationscreen.dart';
import 'package:provider/provider.dart';
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

  bool _showPassword = false;
  bool isLoading = false;

  final AuthService _authService = AuthService();

  Future<void> _handleSignUp() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => isLoading = true);

  final success = await _authService.signup(
    _nameController.text.trim(),
    _emailController.text.trim(),
    _passwordController.text.trim(),
  );

  setState(() => isLoading = false);

  if (!mounted) return;                                                                                                                                                                                                                                                                                                                                                                                                          

  if (success) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => VerificationPage(email: _emailController.text.trim()),//email: _emailController.text.trim() in the brackets for verification page
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Signup failed. Please try again.')),
    );
  }
}


  Future<void> _signInWithGoogle() async {
  setState(() => isLoading = true);
  try {
    final data = await _authService.googleLogin();
    if (!mounted) return;

    if (data != null) {
      final user = data['user'];
      final token = data['token'];
      Provider.of<UserProvider>(context, listen: false).setUser(user, token);
      PushNotificationService().registerCurrentToken();

      final role = user['role']?.toString().toLowerCase();

      Widget nextPage;
      // No role = new user, needs to pick
      if (role == null || role.isEmpty || role == 'null') {
        nextPage = RoleSelectionPage(); // ✅ first time
      } else if (role == 'photographer') {
        nextPage = CreativeBottomTabs(); // ✅ returning creative
      } else {
        nextPage = BottomTabs(); // ✅ returning client
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => nextPage),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google sign in failed')),
      );
    }
  } finally {
    if (mounted) setState(() => isLoading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            cursorColor: Colors.black,
            cursorRadius: Radius.zero,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              labelStyle: TextStyle(color: Colors.black),
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
            cursorColor: Colors.black,
            cursorRadius: Radius.zero,
            decoration: const InputDecoration(
              labelText: 'Email address',
              labelStyle: TextStyle(color: Colors.black),
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
            cursorColor: Colors.black,
            cursorRadius: Radius.zero,
            decoration: const InputDecoration(
              labelText: 'Password',
              labelStyle: TextStyle(color: Colors.black),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFFF7A33)),
              ),
            ),
            obscureText: !_showPassword,
            validator: (value) => value == null || value.length < 6
                ? 'Password must be at least 6 characters'
                : null,
          ),

          Row(
            children: [
              Checkbox(
                value: _showPassword,
                onChanged: (value) {
                  setState(() {
                    _showPassword = value ?? false;
                  });
                },
              ),
              const Text('Show password'),
            ],
          ),

          const SizedBox(height: 24),

          // Continue button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: CustomButton(
              onPressed: _handleSignUp,
              text: 'Continue',
              loading: isLoading,
            ),
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
                      if (await canLaunchUrl(url)) {
                        launchUrl(url, mode: LaunchMode.externalApplication);
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
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Already have an account?'),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => LoginPage()),
                  );
                },
                child: Text(
                  'Login',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF181818),
                  ),
                ),
              ),
            ],
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
              onPressed: isLoading ? null : _signInWithGoogle,
              style: OutlinedButton.styleFrom(
                backgroundColor: Color(0xFFEEEEEE),
                disabledBackgroundColor: Color(0xFFEEEEEE),
                side: BorderSide(color: Color(0xFFEEEEEE)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF181818),
                      ),
                    )
                  : SvgPicture.asset('assets/googleicon.svg', height: 20),
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
        ],
      ),
    );
  }
}
