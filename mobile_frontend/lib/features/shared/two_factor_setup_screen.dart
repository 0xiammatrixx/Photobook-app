import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_frontend/app/buttons.dart';
import 'package:mobile_frontend/app/skeleton.dart';
import 'package:mobile_frontend/services/authservice.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TwoFactorSetupScreen extends StatefulWidget {
  final String token;
  const TwoFactorSetupScreen({super.key, required this.token});

  @override
  State<TwoFactorSetupScreen> createState() => _TwoFactorSetupScreenState();
}

class _TwoFactorSetupScreenState extends State<TwoFactorSetupScreen> {
  int _step = 0; // 0 = loading, 1 = show QR + backup codes, 2 = confirm
  String _secret = '';
  String _qrCodeUrl = '';
  List<String> _backupCodes = [];
  String? _error;
  bool _loading = false;
  final _totpCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSetup();
  }

  Future<void> _loadSetup() async {
    final data = await AuthService().setup2FA(widget.token);
    if (!mounted) return;
    if (data == null) {
      setState(() => _error = 'Failed to initialize 2FA setup.');
      return;
    }

    final secret = (data['secret'] ?? '').toString();
    final rawUrl = (data['qrCodeUrl'] ?? '').toString();
    _secret = secret;

    // If the backend returns a sane otpauth:// URL (under 500 chars), use it.
    // Otherwise build one from the secret, which is the standard format
    // authenticator apps expect: otpauth://totp/Issuer:Account?secret=XXX&issuer=Issuer
    if (rawUrl.isNotEmpty && rawUrl.length < 500 && rawUrl.startsWith('otpauth://')) {
      _qrCodeUrl = rawUrl;
    } else {
      if (rawUrl.isNotEmpty) {
        // ignore: avoid_print
        print('⚠️ qrCodeUrl is ${rawUrl.length} chars — building otpauth URI from secret');
      }
      _qrCodeUrl = 'otpauth://totp/PhotoBook?secret=$secret&issuer=PhotoBook';
    }

    setState(() {
      _backupCodes = List<String>.from(data['backupCodes'] ?? []);
      _step = 1;
    });
  }

  Future<void> _confirm() async {
    final code = _totpCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Enter the 6-digit code from your authenticator app.');
      return;
    }
    setState(() { _loading = true; _error = null; });

    final ok = await AuthService().confirm2FA(
      token: widget.token,
      totpToken: code,
      secret: _secret,
      backupCodes: _backupCodes,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Two-factor authentication enabled!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // return `true` = 2FA was enabled
    } else {
      setState(() => _error = 'Invalid code. Please try again.');
    }
  }

  @override
  void dispose() {
    _totpCtrl.dispose();
    super.dispose();
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
          'Two-Factor Authentication',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: _step == 0 ? _buildLoading() : _step == 1 ? _buildSetup() : _buildLoading(),
    );
  }

  Widget _buildLoading() {
    return SkeletonPulse(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SkeletonLine(width: 200, height: 16),
            SizedBox(height: 28),
            Center(child: SkeletonBox(width: 200, height: 200, radius: 12)),
            SizedBox(height: 28),
            SkeletonLine(height: 13),
            SizedBox(height: 8),
            SkeletonLine(height: 13),
            SizedBox(height: 8),
            SkeletonLine(width: 160, height: 13),
          ],
        ),
      ),
    );
  }

  Widget _buildQrCode() {
    if (_qrCodeUrl.isEmpty) {
      return const SizedBox(
        width: 200,
        height: 200,
        child: Center(
          child: Text('No QR data', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    // Safety cap — otpauth:// URLs are always under 200 chars. If somehow
    // the data is still too large, show the secret as text instead.
    if (_qrCodeUrl.length > 300) {
      return const SizedBox(
        width: 200,
        height: 200,
        child: Center(
          child: Icon(Icons.qr_code_2, size: 80, color: Colors.grey),
        ),
      );
    }

    return QrImageView(
      data: _qrCodeUrl,
      version: QrVersions.auto,
      size: 200,
      backgroundColor: Colors.white,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Color(0xFFFF7A33),
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Colors.black,
      ),
    );
  }

  Widget _buildSetup() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Step 1: Scan QR Code',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Open your authenticator app (Google Authenticator, Authy, etc.) and scan this QR code.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // QR code
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _buildQrCode(),
            ),
          ),
          const SizedBox(height: 12),

          // Manual secret
          Center(
            child: GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: _secret));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Secret copied to clipboard')),
                );
              },
              child: Text(
                'Or enter manually: $_secret',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 32),

          const Text(
            'Step 2: Save Backup Codes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Save these backup codes in a safe place. You can use them to sign in if you lose access to your authenticator app.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                ..._backupCodes.map((code) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            code,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: code));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Code copied')),
                              );
                            },
                            child: const Icon(Icons.copy, size: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 12),

          CustomButton(
            text: 'Copy All Codes',
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: _backupCodes.join('\n')),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All backup codes copied')),
              );
            },
          ),
          const SizedBox(height: 32),

          const Text(
            'Step 3: Verify Setup',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter the 6-digit code from your authenticator app to confirm.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 12),

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
            onPressed: _loading ? () {} : () { _confirm(); },
            text: _loading ? 'Verifying...' : 'Enable 2FA',
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
