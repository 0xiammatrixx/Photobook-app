import 'package:flutter/material.dart';
import 'package:mobile_frontend/features/auth/login/loginscreen.dart';
import 'package:mobile_frontend/features/auth/passwordreset/passwordresetscreen.dart';
import 'package:mobile_frontend/features/shared/two_factor_setup_screen.dart';
import 'package:mobile_frontend/providers/user_provider.dart';
import 'package:mobile_frontend/services/authservice.dart';
import 'package:provider/provider.dart';

class PasswordSecurityPage extends StatefulWidget {
  const PasswordSecurityPage({super.key});

  @override
  State<PasswordSecurityPage> createState() => _PasswordSecurityPageState();
}

class _PasswordSecurityPageState extends State<PasswordSecurityPage> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _loading = false;
  String? _errorText;

  bool _2faEnabled = false;
  bool _2faLoading = true;

  @override
  void initState() {
    super.initState();
    _load2FAStatus();
  }

  Future<void> _load2FAStatus() async {
    // Check if user has 2FA enabled from stored user data.
    // The backend should include a `twoFactorEnabled` flag on the user object.
    final user = context.read<UserProvider>().user;
    setState(() {
      _2faEnabled = user?['twoFactorEnabled'] == true ||
          user?['twoFactorAuthentication'] == true;
      _2faLoading = false;
    });
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_newCtrl.text != _confirmCtrl.text) {
      setState(() => _errorText = 'Passwords do not match');
      return;
    }
    if (_currentCtrl.text.isEmpty || _newCtrl.text.isEmpty) {
      setState(() => _errorText = 'All fields are required');
      return;
    }
    if (_newCtrl.text.length < 6) {
      setState(() => _errorText = 'Password must be at least 6 characters');
      return;
    }

    setState(() { _loading = true; _errorText = null; });

    final token = context.read<UserProvider>().token ?? '';
    final result = await AuthService().changePassword(
      token: token,
      currentPassword: _currentCtrl.text,
      newPassword: _newCtrl.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      _currentCtrl.clear();
      _newCtrl.clear();
      _confirmCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() => _errorText = result.message);
    }
  }

  Future<void> _toggle2FA() async {
    final token = context.read<UserProvider>().token ?? '';
    if (_2faEnabled) {
      // Disable
      final ok = await AuthService().disable2FA(token);
      if (!mounted) return;
      if (ok) {
        setState(() => _2faEnabled = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Two-factor authentication disabled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      // Navigate to setup
      final enabled = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => TwoFactorSetupScreen(token: token),
        ),
      );
      if (enabled == true && mounted) {
        setState(() => _2faEnabled = true);
      }
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
            'Are you sure? This action is permanent and cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await AuthService().deleteAccount();
              if (success && context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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
        title: const Text(
          'Password & Security',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Current Password',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            _passwordField(
              controller: _currentCtrl,
              show: _showCurrent,
              onToggle: () =>
                  setState(() => _showCurrent = !_showCurrent),
              hint: 'Enter current password',
            ),
            if (_errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(_errorText!,
                    style: const TextStyle(
                        color: Colors.red, fontSize: 12)),
              ),
            const SizedBox(height: 16),

            const Text('New Password',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            _passwordField(
              controller: _newCtrl,
              show: _showNew,
              onToggle: () =>
                  setState(() => _showNew = !_showNew),
            ),
            const SizedBox(height: 16),

            const Text('Confirm Password',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            _passwordField(
              controller: _confirmCtrl,
              show: _showConfirm,
              onToggle: () =>
                  setState(() => _showConfirm = !_showConfirm),
            ),
            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PasswordResetPage(),
                    ),
                  );
                },
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                      color: Color(0xFF047418),
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A33),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _loading ? null : _changePassword,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Change Password',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),

            const Text('Others',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // 2FA row
            _2faLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A33)))
                : ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Two-factor authentication',
                        style: TextStyle(fontSize: 14)),
                    subtitle: Text(
                      _2faEnabled
                          ? 'Enabled — your account is protected with an extra layer of security.'
                          : 'Protect your PhotoBook account with an extra layer of security. '
                              'When enabled, you\'ll enter a verification code whenever you sign in on a new device.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    trailing: Switch(
                      value: _2faEnabled,
                      activeColor: const Color(0xFFFF7A33),
                      onChanged: (_) => _toggle2FA(),
                    ),
                  ),
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 12),

            // Delete account
            GestureDetector(
              onTap: () => _confirmDelete(context),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.red, width: 1.5),
                    ),
                    child: const Icon(Icons.close,
                        color: Colors.red, size: 14),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Delete Account',
                    style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required bool show,
    required VoidCallback onToggle,
    String? hint,
  }) =>
      TextField(
        controller: controller,
        obscureText: !show,
        decoration: InputDecoration(
          hintText: hint,
          suffixIcon: IconButton(
            icon: Icon(
              show ? Icons.visibility_off_outlined : Icons.remove_red_eye_outlined,
              color: Colors.grey,
              size: 20,
            ),
            onPressed: onToggle,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFFF7A33)),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      );
}
