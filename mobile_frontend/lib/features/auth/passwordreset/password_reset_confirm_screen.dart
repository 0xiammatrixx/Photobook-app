import 'package:flutter/material.dart';
import 'package:mobile_frontend/app/buttons.dart';
import 'package:mobile_frontend/features/auth/login/loginscreen.dart';
import 'package:mobile_frontend/features/auth/passwordreset/resetsuccessful.dart';
import 'package:mobile_frontend/services/authservice.dart';

class PasswordResetConfirmScreen extends StatefulWidget {
  final String email;
  const PasswordResetConfirmScreen({super.key, required this.email});

  @override
  State<PasswordResetConfirmScreen> createState() =>
      _PasswordResetConfirmScreenState();
}

class _PasswordResetConfirmScreenState extends State<PasswordResetConfirmScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();
  bool _showPassword = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final result = await AuthService().confirmPasswordReset(
      email: widget.email,
      code: _codeCtrl.text.trim(),
      newPassword: _newPwCtrl.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    switch (result) {
      case PasswordResetResult.success:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ResetSuccessful()),
          (route) => false,
        );
      case PasswordResetResult.invalidCode:
        setState(() => _error = 'Invalid or expired code. Please try again.');
      case PasswordResetResult.userNotFound:
        setState(() => _error = 'Account not found.');
      case PasswordResetResult.error:
        setState(() => _error = 'Something went wrong. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Reset Password',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-digit code sent to ${widget.email}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Verification code
              TextFormField(
                controller: _codeCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'Verification Code',
                  hintText: '000000',
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFFF7A33)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.trim().length != 6) ? 'Enter the 6-digit code' : null,
              ),
              const SizedBox(height: 16),

              // New password
              TextFormField(
                controller: _newPwCtrl,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFFF7A33)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter a new password';
                  if (v.length < 6) return 'At least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirm password
              TextFormField(
                controller: _confirmPwCtrl,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFFF7A33)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) {
                  if (v != _newPwCtrl.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 4),

              Row(
                children: [
                  Checkbox(
                    value: _showPassword,
                    onChanged: (v) => setState(() => _showPassword = v ?? false),
                  ),
                  const Text('Show Password'),
                ],
              ),
              const SizedBox(height: 8),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),

              CustomButton(
                onPressed: _loading ? () {} : () { _submit(); },
                text: _loading ? 'Resetting...' : 'Reset Password',
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Remembered?"),
                  TextButton(
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                    ),
                    child: const Text(
                      'Login instead',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
