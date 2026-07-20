import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BankAccountPage extends StatefulWidget {
  const BankAccountPage({super.key});

  @override
  State<BankAccountPage> createState() => _BankAccountPageState();
}

class _BankAccountPageState extends State<BankAccountPage> {
  // Mock saved account — null means not set yet
  Map<String, String>? _savedAccount = {
    'bankName': 'Access Bank',
    'accountNumber': '0123456789',
    'accountName': 'Timmon Photography',
    'status': 'Verified',
  };
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back, size: 20, color: Colors.black),
          ),
        ),
        title: const Text('Bank Account',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _editing || _savedAccount == null
            ? _EditView(
                existing: _savedAccount,
                onSaved: (account) {
                  setState(() {
                    _savedAccount = account;
                    _editing = false;
                  });
                },
                onCancel: () => setState(() => _editing = false),
              )
            : _ViewMode(
                account: _savedAccount!,
                onEdit: () => setState(() => _editing = true),
              ),
      ),
    );
  }
}

// ── View mode ────────────────────────────────────────────────────────────────

class _ViewMode extends StatelessWidget {
  final Map<String, String> account;
  final VoidCallback onEdit;

  const _ViewMode({required this.account, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text('ACCOUNT DETAILS',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500,
                        letterSpacing: 0.8)),
              ),
              _row('Bank Name', account['bankName'] ?? ''),
              _divider(),
              _row('Account Number', account['accountNumber'] ?? ''),
              _divider(),
              _row('Account Name', account['accountName'] ?? ''),
              _divider(),
              _row('Status', account['status'] ?? '', valueColor: const Color(0xFF047418)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7A33),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: onEdit,
            child: const Text('Edit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            Text(value,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500, color: valueColor ?? Colors.black87)),
          ],
        ),
      );

  Widget _divider() => Divider(height: 1, color: Colors.grey.shade200);
}

// ── Edit mode ────────────────────────────────────────────────────────────────

class _EditView extends StatefulWidget {
  final Map<String, String>? existing;
  final Function(Map<String, String>) onSaved;
  final VoidCallback onCancel;

  const _EditView({this.existing, required this.onSaved, required this.onCancel});

  @override
  State<_EditView> createState() => _EditViewState();
}

class _EditViewState extends State<_EditView> {
  late TextEditingController _accountNumberCtrl;
  late TextEditingController _bankNameCtrl;
  late TextEditingController _accountNameCtrl;
  bool _loading = false;
  bool _verified = false;

  @override
  void initState() {
    super.initState();
    _accountNumberCtrl = TextEditingController(text: widget.existing?['accountNumber'] ?? '');
    _bankNameCtrl = TextEditingController(text: widget.existing?['bankName'] ?? '');
    _accountNameCtrl = TextEditingController(text: widget.existing?['accountName'] ?? '');
  }

  @override
  void dispose() {
    _accountNumberCtrl.dispose();
    _bankNameCtrl.dispose();
    _accountNameCtrl.dispose();
    super.dispose();
  }

  // Simulate account name lookup
  Future<void> _lookupAccountName() async {
    final number = _accountNumberCtrl.text.trim();
    final bank = _bankNameCtrl.text.trim();
    if (number.length < 10 || bank.isEmpty) return;

    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1)); // TODO: call real API
    setState(() {
      _accountNameCtrl.text = 'Timmon Photography'; // mock result
      _verified = false; // needs OTP to confirm
      _loading = false;
    });
  }

  void _confirmWithOTP() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _OTPVerificationPage(
          onVerified: () {
            widget.onSaved({
              'bankName': _bankNameCtrl.text.trim(),
              'accountNumber': _accountNumberCtrl.text.trim(),
              'accountName': _accountNameCtrl.text.trim(),
              'status': 'Verified',
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Account Number'),
        TextField(
          controller: _accountNumberCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
          onChanged: (_) => _lookupAccountName(),
          decoration: _dec('0123456789'),
        ),
        const SizedBox(height: 16),

        _label('Bank Name'),
        TextField(
          controller: _bankNameCtrl,
          onChanged: (_) => _lookupAccountName(),
          decoration: _dec('Access Bank'),
        ),
        const SizedBox(height: 16),

        _label('Account Name'),
        Stack(
          alignment: Alignment.centerRight,
          children: [
            TextField(
              controller: _accountNameCtrl,
              enabled: false,
              decoration: _dec('Jade Collins'),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF7A33)),
                ),
              ),
          ],
        ),
        if (_accountNameCtrl.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Verify that this matches your registered name or business name',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7A33),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _accountNameCtrl.text.isEmpty ? null : _confirmWithOTP,
            child: const Text('Confirm with OTP and Save',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: widget.onCancel,
            child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
        ),
      ],
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      );

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFFF7A33))),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      );
}

// ── OTP Page ─────────────────────────────────────────────────────────────────

class _OTPVerificationPage extends StatefulWidget {
  final VoidCallback onVerified;
  const _OTPVerificationPage({required this.onVerified});

  @override
  State<_OTPVerificationPage> createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<_OTPVerificationPage> {
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  bool _loading = false;

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _onDigitEntered(int index, String value) {
    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }
    if (index == 3 && value.isNotEmpty) {
      _verify();
    }
  }

  Future<void> _verify() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length < 4) return;

    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1)); // TODO: verify with backend
    setState(() => _loading = false);

    if (mounted) {
      Navigator.pop(context); // close OTP page
      widget.onVerified();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back, size: 20, color: Colors.black),
          ),
        ),
        title: const Text('Verify Via OTP',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Account Verification', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Enter the verification code we just sent to your phone number.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 32),

            // OTP boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _focusNodes[i].hasFocus ? const Color(0xFFFF7A33) : Colors.grey.shade300,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: _controllers[i],
                  focusNode: _focusNodes[i],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                  ),
                  onChanged: (v) => _onDigitEntered(i, v),
                ),
              )),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A33),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _loading ? null : _verify,
                child: _loading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Confirm OTP',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}