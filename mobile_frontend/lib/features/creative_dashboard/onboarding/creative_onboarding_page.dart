import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_frontend/features/creative_dashboard/AddPortfolioPage/addportfoliopage.dart';
import 'package:mobile_frontend/providers/user_provider.dart';
import 'package:mobile_frontend/services/payout_service.dart';
import 'package:mobile_frontend/services/profileservice.dart';
import 'package:provider/provider.dart';

const _orange = Color(0xFFFF7A33);
const _green = Color(0xFF047418);

/// Post-signup creative onboarding wizard (4 steps):
///   1. Professional Information
///   2. Location
///   3. Portfolio & Packages
///   4. Payment & Review
class CreativeOnboardingPage extends StatefulWidget {
  /// Which of the 4 steps are already complete (true = skip). Completed steps
  /// are omitted from the wizard entirely.
  final List<bool> completed;

  const CreativeOnboardingPage({
    super.key,
    this.completed = const [false, false, false, false],
  });

  @override
  State<CreativeOnboardingPage> createState() => _CreativeOnboardingPageState();
}

class _CreativeOnboardingPageState extends State<CreativeOnboardingPage> {
  int _step = 0;
  bool _saving = false;
  late final List<int> _remaining; // original indices of incomplete steps

  static const _stepTitles = [
    'Professional Information',
    'Location',
    'Portfolio & Packages',
    'Payment & Review',
  ];

  // Step 1 — professional info
  final _businessNameCtrl = TextEditingController();
  final _displayTitleCtrl = TextEditingController();
  final _aboutMeCtrl = TextEditingController();
  final Set<String> _roles = {};

  // Step 2 — location
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  String? _state = 'Abuja';
  String? _serviceArea = 'Abuja and surrounding areas';

  // Step 4 — bank
  final _accountNumberCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();
  List<Map<String, dynamic>> _banks = [];
  String? _bankCode;

  static const _states = [
    'Abuja',
    'Lagos',
    'Kano',
    'Rivers',
    'Oyo',
    'Kaduna',
    'Enugu',
    'Ogun',
  ];

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _displayTitleCtrl.dispose();
    _aboutMeCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _accountNumberCtrl.dispose();
    _accountNameCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _remaining = [
      for (var i = 0; i < _stepTitles.length; i++)
        if (!(widget.completed.length > i && widget.completed[i])) i,
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBanks());
  }

  Future<void> _loadBanks() async {
    final token = context.read<UserProvider>().token;
    if (token == null) return;
    try {
      final banks = await PayoutService().getBanks(token: token);
      if (mounted) setState(() => _banks = banks);
    } catch (_) {}
  }

  void _toggleRole(String role) {
    setState(() {
      _roles.contains(role) ? _roles.remove(role) : _roles.add(role);
    });
  }

  Future<void> _next() async {
    if (_step < _remaining.length - 1) {
      setState(() => _step++);
    } else {
      await _submit();
    }
  }

  Future<void> _submit() async {
    final token = context.read<UserProvider>().token;
    if (token == null) return;

    setState(() => _saving = true);
    try {
      // Only persist the fields for steps that are actually shown. Completed
      // steps are skipped from the wizard — writing them again with empty
      // controllers would wipe the user's existing data.
      if (_remaining.contains(0)) {
        // Save professional info (roles become tags the booking form reads).
        final tags = <String>[..._roles];
        await ProfilePortfolioService().updateCreativeProfile(
          token: token,
          businessName: _businessNameCtrl.text.trim(),
          displayName: _displayTitleCtrl.text.trim(),
          aboutMe: _aboutMeCtrl.text.trim(),
          tags: tags,
        );
      }

      // Save bank account (step 4).
      if (_remaining.contains(3) && _accountNumberCtrl.text.trim().isNotEmpty) {
        await PayoutService().saveBankAccount(
          token: token,
          bankCode: _bankCode ?? '',
          accountNumber: _accountNumberCtrl.text.trim(),
          accountName: _accountNameCtrl.text.trim(),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Onboarding complete 🎉')));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildStepContent(int originalIndex) {
    switch (originalIndex) {
      case 0:
        return _buildProfessionalInfo();
      case 1:
        return _buildLocation();
      case 2:
        return _buildPortfolio();
      case 3:
        return _buildPayment();
      default:
        return const SizedBox.shrink();
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
      body: SafeArea(
        child: Column(
          children: [
            _ProgressHeader(
              step: _step,
              titles: [for (final i in _remaining) _stepTitles[i]],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: _remaining.isEmpty
                    ? const SizedBox.shrink()
                    : _buildStepContent(_remaining[_step]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _step == _remaining.length - 1
                              ? 'Submit & Complete'
                              : 'Continue',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Professional Information',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Tell clients who you are and what you offer.',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        _field(_businessNameCtrl, 'Business Name'),
        const SizedBox(height: 14),
        _field(_displayTitleCtrl, 'Display Title (e.g. Wedding Photographer)'),
        const SizedBox(height: 18),
        const Text(
          'What services do you offer?',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 4),
        _roleCheckbox('Photographer', 'photographer'),
        _roleCheckbox('Videographer', 'videographer'),
        _roleCheckbox('Content Creator', 'content_creator'),
        const SizedBox(height: 18),
        Text(
          'About Me',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _aboutMeCtrl,
          maxLines: 5,
          maxLength: 500,
          decoration: const InputDecoration(
            hintText: 'Write a short bio about yourself...',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildLocation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Add your locations so clients near you can find you easily.',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        const Text(
          'Studio / Business Address',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 8),
        _field(_addressCtrl, 'Enter your address'),
        const SizedBox(height: 14),
        _dropdown(
          label: 'State',
          value: _state,
          items: _states,
          onChanged: (v) => setState(() => _state = v),
        ),
        const SizedBox(height: 14),
        _field(_cityCtrl, 'City/Area'),
        const SizedBox(height: 14),
        _dropdown(
          label: 'Service Area',
          value: _serviceArea,
          items: const [
            'Abuja and surrounding areas',
            'Within my state',
            'Nationwide',
          ],
          onChanged: (v) => setState(() => _serviceArea = v),
        ),
        const SizedBox(height: 8),
        Text(
          'Set your service area so nearby clients can discover and book you.',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildPortfolio() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Portfolio & Packages',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Showcase your work and set your packages so clients know what to expect.',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        const Text(
          'Portfolio Highlights',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddPortfolioPage()),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _orange),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.add, color: _orange),
            label: const Text(
              'Add your best work',
              style: TextStyle(color: _orange),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Rate Card',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          'Set up your packages and pricing from your profile so clients can see your rates.',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildPayment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment & Review',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Add your payment details and review your information before going live.',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        _field(
          _accountNumberCtrl,
          'Account Number',
          keyboardType: TextInputType.number,
          formatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _bankCode,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Bank Name'),
          hint: const Text('Select Bank'),
          items: _banks
              .map(
                (b) => DropdownMenuItem<String>(
                  value: b['code']?.toString(),
                  child: Text(b['name']?.toString() ?? ''),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _bankCode = v),
        ),
        const SizedBox(height: 14),
        _field(_accountNameCtrl, 'Account Name'),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F9F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _green.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Review Your Information',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 10),
              _reviewRow('Professional Information', _roles.isNotEmpty),
              _reviewRow('Location', _addressCtrl.text.isNotEmpty),
              _reviewRow('Portfolio & Packages', true),
              _reviewRow(
                'Payment & Review',
                _accountNumberCtrl.text.isNotEmpty,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reviewRow(String label, bool done) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: _green,
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _roleCheckbox(String label, String role) {
    return Row(
      children: [
        Checkbox(
          value: _roles.contains(role),
          onChanged: (_) => _toggleRole(role),
        ),
        Text(label),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String hint, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      decoration: InputDecoration(
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: items
          .map((s) => DropdownMenuItem<String>(value: s, child: Text(s)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final int step;
  final List<String> titles;

  const _ProgressHeader({required this.step, required this.titles});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          for (var i = 0; i < titles.length; i++) ...[
            Expanded(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: i <= step ? _orange : Colors.grey[300],
                    child: i < step
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: i == step
                                  ? Colors.white
                                  : Colors.grey[600],
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    titles[i].split(' ').first,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: i == step
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: i <= step ? Colors.black : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (i != titles.length - 1)
              Container(
                width: 20,
                height: 2,
                margin: const EdgeInsets.only(bottom: 22),
                color: i < step ? _orange : Colors.grey[300],
              ),
          ],
        ],
      ),
    );
  }
}
