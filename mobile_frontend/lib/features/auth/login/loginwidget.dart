import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile_frontend/app/authservice.dart';
import 'package:mobile_frontend/app/buttons.dart';
import 'package:mobile_frontend/features/auth/passwordreset/passwordresetscreen.dart';
import 'package:mobile_frontend/features/auth/signup/signUpScreen.dart';
import 'package:mobile_frontend/features/dashboard/bottom_nav_bar.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _showPassword = false;
  bool isLoading = false;

  final AuthService _authService = AuthService();

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final success = await _authService.login(email, password);

    setState(() => isLoading = false);

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => BottomTabs()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid credentials')));
    }
  }

  Future<void> _logInWithGoogle() async {
    setState(() => isLoading = true);
    try {
      final success = await _authService.googleLogin();
      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => BottomTabs()),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Google login failed')));
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _logInWithFacebook() {
    // Facebook SignIn
    print('Facebook Login');
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
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
            obscureText: !_showPassword,
            validator: (value) => value == null || value.length < 6
                ? 'Password must be at least 6 characters'
                : null,
          ),

          Row(
            children: [
              Checkbox(
                fillColor: MaterialStateProperty.resolveWith<Color>((
                  Set<WidgetState> states,
                ) {
                  if (states.contains(WidgetState.disabled)) {
                    return Colors.white.withOpacity(.32);
                  }
                  return Colors.white;
                }),
                checkColor: Colors.black,
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

          const SizedBox(height: 5),

          // Continue button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: CustomButton(onPressed: _handleLogin, text: 'Continue'),
          ),

          const SizedBox(height: 24),

          Text('Forgot Password? We’ve got you covered!'),
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => PasswordResetPage()),
              );
            },
            child: Text(
              'Click here to reset password',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF181818),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Dont have an account?'),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => SignUpPage()),
                  );
                },
                child: Text(
                  'Sign Up',
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
              onPressed: _logInWithGoogle,
              style: OutlinedButton.styleFrom(
                backgroundColor: Color(0xFFEEEEEE),
                side: BorderSide(color: Color(0xFFEEEEEE)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: SvgPicture.asset('assets/googleicon.svg', height: 20),
              label: const Text(
                'Login with Google',
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
              onPressed: _logInWithFacebook,
              style: OutlinedButton.styleFrom(
                backgroundColor: Color(0xFFEEEEEE),
                side: BorderSide(color: Color(0xFFEEEEEE)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: SvgPicture.asset('assets/facebookicon.svg', height: 20),
              label: const Text(
                'Login with Facebook',
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
