import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_frontend/app/skeleton.dart';
import 'package:mobile_frontend/providers/user_provider.dart';
import 'package:mobile_frontend/services/payout_service.dart';
import 'package:provider/provider.dart';

const _orange = Color(0xFFFF7A33);
const _green = Color(0xFF047418);

class BankAccountPage extends StatefulWidget {
  const BankAccountPage({super.key});

  @override
  State<BankAccountPage> createState() => _BankAccountPageState();
}

class _BankAccountPageState extends State<BankAccountPage> {
  Map<String, String>? _savedAccount;
  bool _loadingAccount = true;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  Future<void> _loadAccount() async {
    final token = context.read<UserProvider>().token;
    if (token == null) {
      setState(() => _loadingAccount = false);
      return;
    }
    final account = await PayoutService().getBankAccount(token: token);
    if (!mounted) return;
    setState(() {
      _savedAccount = account == null
          ? null
          : {
              'bankName':
                  (account['bankName'] ?? account['bank_name'] ?? '').toString(),
              'accountNumber':
                  (account['accountNumberMasked'] ??
                          account['account_number_masked'] ??
                          '')
                      .toString(),
              'accountName':
                  (account['accountName'] ?? account['account_name'] ?? '')
                      .toString(),
              'status':
                  (account['isVerified'] == true) ? 'Verified' : 'Pending',
            };
      _loadingAccount = false;
    });
  }

  Future<void> _deleteAccount() async {
    final token = context.read<UserProvider>().token;
    if (token == null) return;
    final ok = await PayoutService().deleteBankAccount(token: token);
    if (!mounted) return;
    if (ok) {
      setState(() => _savedAccount = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bank account removed')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not remove bank account')),
      );
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
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, size: 20, color: Colors.black),
          ),
        ),
        title: const Text(
          'Bank Account',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: _loadingAccount
          ? SkeletonPulse(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonLine(width: 160, height: 16),
                    SizedBox(height: 28),
                    SkeletonLine(height: 13),
                    SizedBox(height: 8),
                    SkeletonLine(height: 13),
                    SizedBox(height: 28),
                    SkeletonLine(height: 13),
                    SizedBox(height: 8),
                    SkeletonLine(height: 13),
                    SizedBox(height: 28),
                    SkeletonBox(height: 48, radius: 12),
                  ],
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(20),
              child: _editing || _savedAccount == null
                  ? _EditView(
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
                      onDelete: _deleteAccount,
                    ),
            ),
    );
  }
}

// ── View mode ────────────────────────────────────────────────────────────────

class _ViewMode extends StatelessWidget {
  final Map<String, String> account;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ViewMode({
    required this.account,
    required this.onEdit,
    required this.onDelete,
  });

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
                child: Text(
                  'ACCOUNT DETAILS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              _row('Bank Name', account['bankName'] ?? ''),
              _divider(),
              _row('Account Number', account['accountNumber'] ?? ''),
              _divider(),
              _row('Account Name', account['accountName'] ?? ''),
              _divider(),
              _row('Status', account['status'] ?? '', valueColor: _green),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _orange,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: onEdit,
            child: const Text(
              'Edit',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: onDelete,
            child: const Text(
              'Remove account',
              style: TextStyle(color: Colors.red),
            ),
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
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ],
        ),
      );

  Widget _divider() => Divider(height: 1, color: Colors.grey.shade200);
}

// ── Edit mode ────────────────────────────────────────────────────────────────

class _EditView extends StatefulWidget {
  final Function(Map<String, String>) onSaved;
  final VoidCallback onCancel;

  const _EditView({required this.onSaved, required this.onCancel});

  @override
  State<_EditView> createState() => _EditViewState();
}

class _EditViewState extends State<_EditView> {
  final _accountNumberCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();

  List<Map<String, dynamic>> _banks = [];
  String? _selectedBankCode;
  String? _selectedBankName;
  bool _loadingBanks = false;
  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadBanks();
  }

  @override
  void dispose() {
    _accountNumberCtrl.dispose();
    _accountNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBanks() async {
    final token = context.read<UserProvider>().token;
    if (token == null) return;
    setState(() => _loadingBanks = true);
    final banks = await PayoutService().getBanks(token: token);
    if (!mounted) return;
    setState(() {
      _banks = banks;
      _loadingBanks = false;
    });
  }

  Future<void> _lookupAccountName() async {
    final number = _accountNumberCtrl.text.trim();
    if (number.length < 10 || _selectedBankCode == null) return;
    final token = context.read<UserProvider>().token;
    if (token == null) return;
    setState(() => _loading = true);
    try {
      final name = await PayoutService().verifyAccount(
        token: token,
        accountNumber: number,
        bankCode: _selectedBankCode!,
      );
      if (!mounted) return;
      setState(() {
        _accountNameCtrl.text = name ?? '';
        _loading = false;
      });
      if (name == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not resolve account')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not resolve account: $e')),
      );
    }
  }

  Future<void> _save() async {
    final token = context.read<UserProvider>().token;
    if (token == null || _selectedBankCode == null) return;
    final number = _accountNumberCtrl.text.trim();
    final name = _accountNameCtrl.text.trim();
    if (number.length < 10 || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter an account number and resolve the name'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final result = await PayoutService().saveBankAccount(
      token: token,
      bankCode: _selectedBankCode!,
      accountNumber: number,
      accountName: name,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.success) {
      widget.onSaved({
        'bankName': _selectedBankName ?? '',
        'accountNumber': number,
        'accountName': name,
        'status': 'Verified',
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
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
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          onChanged: (_) => _lookupAccountName(),
          decoration: _dec('0123456789'),
        ),
        const SizedBox(height: 16),

        _label('Bank Name'),
        DropdownButtonFormField<String>(
          initialValue: _selectedBankCode,
          hint: const Text('Select Bank'),
          isExpanded: true,
          decoration: _dec(''),
          items: _loadingBanks
              ? [
                  const DropdownMenuItem<String>(
                    value: 'loading',
                    child: Text('Loading banks...'),
                  ),
                ]
              : _banks
                  .map(
                    (b) => DropdownMenuItem<String>(
                      value: b['code']?.toString(),
                      child: Text(b['name']?.toString() ?? ''),
                    ),
                  )
                  .toList(),
          onChanged: _loadingBanks
              ? null
              : (code) {
                  setState(() {
                    _selectedBankCode = code;
                    _selectedBankName = _banks
                        .firstWhere(
                          (b) => b['code']?.toString() == code,
                          orElse: () => {},
                        )['name']
                        ?.toString();
                  });
                  _lookupAccountName();
                },
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
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _orange,
                  ),
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
              backgroundColor: _orange,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed:
                (_accountNameCtrl.text.isEmpty || _saving) ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Save Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
        child: Text(
          text,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      );

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _orange),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      );
}
