import 'package:flutter/material.dart';
import 'package:mobile_frontend/app/buttons.dart';
import 'package:mobile_frontend/services/authservice.dart';

class TwoFactorVerifyScreen extends StatefulWidget {
  /// The temporary token returned by the login endpoint when 2FA is required.
  final String tempToken;

  /// Called when 2FA verification succeeds — passes back the real auth token + user.
  final void Function(Map<String, dynamic> data) onVerified;

  const TwoFactorVerifyScreen({
    super.key,
    required this.tempToken,
    required this.onVerified,
  });

  @override
  State<TwoFactorVerifyScreen> createState() => _TwoFactorVerifyScreenState();
}

class _TwoFactorVerifyScreenState extends State<TwoFactorVerifyScreen> {
  final _totpCtrl = TextEditingController();
  final _backupCtrl = TextEditingController();
  bool _useBackup = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _totpCtrl.dispose();
    _backupCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final hasTotp = _totpCtrl.text.trim().length == 6;
    final hasBackup = _backupCtrl.text.trim().isNotEmpty;

    if (!_useBackup && !hasTotp) {
      setState(() => _error = 'Enter the 6-digit code from your authenticator app.');
      return;
    }
    if (_useBackup && !hasBackup) {
      setState(() => _error = 'Enter a backup code.');
      return;
    }

    setState(() { _loading = true; _error = null; });

    final data = await AuthService().verify2FA(
      token: _useBackup ? _backupCtrl.text.trim() : _totpCtrl.text.trim(),
      backupCode: _useBackup ? _backupCtrl.text.trim() : null,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (data != null) {
      widget.onVerified(data);
    } else {
      setState(() => _error = 'Invalid code. Please try again.');
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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            Icon(Icons.lock_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            const Text(
              'Two-Factor Authentication',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter the verification code from your authenticator app to continue.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            if (!_useBackup) ...[
              // TOTP input
              TextFormField(
                controller: _totpCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: InputDecoration(
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
              ),
            ] else ...[
              // Backup code input
              TextFormField(
                controller: _backupCtrl,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, letterSpacing: 2),
                decoration: InputDecoration(
                  hintText: 'Enter backup code',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFFF7A33)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),

            TextButton(
              onPressed: () => setState(() {
                _useBackup = !_useBackup;
                _error = null;
              }),
              child: Text(
                _useBackup
                    ? 'Use authenticator app instead'
                    : 'Use a backup code instead',
                style: const TextStyle(
                  color: Color(0xFFFF7A33),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),

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
              onPressed: _loading ? () {} : () { _verify(); },
              text: _loading ? 'Verifying...' : 'Verify',
            ),
          ],
        ),
      ),
    );
  }
}
