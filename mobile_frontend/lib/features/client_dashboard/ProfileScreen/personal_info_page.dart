import 'package:flutter/material.dart';
import 'package:mobile_frontend/providers/user_provider.dart';
import 'package:provider/provider.dart';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  bool _editing = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  String _location = 'Abuja';

  final List<String> _locations = [
    'Abuja', 'Lagos', 'Port Harcourt', 'Kano', 'Ibadan', 'Enugu',
  ];

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).user;
    _nameCtrl = TextEditingController(text: user?['name'] ?? '');
    _phoneCtrl = TextEditingController(text: user?['phone'] ?? '');
    _emailCtrl = TextEditingController(text: user?['email'] ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
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
          'Personal Information',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.grey.shade200,
                    child: const Icon(Icons.person,
                        size: 52, color: Colors.grey),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF7A33),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            _label('Full Name'),
            _field(controller: _nameCtrl, enabled: _editing),
            const SizedBox(height: 16),

            _label('Phone Number'),
            _field(
              controller: _phoneCtrl,
              enabled: _editing,
              keyboardType: TextInputType.phone,
              suffix: _editing
                  ? null
                  : _phoneCtrl.text.isEmpty
                      ? _verifyBadge('Verify via OTP', unverified: true)
                      : const Icon(Icons.check_circle,
                          color: Color(0xFF047418), size: 20),
              hint: '+234 90 123 456 78',
            ),
            if (!_editing && _phoneCtrl.text.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('Contact is unverified',
                    style: TextStyle(
                        color: Colors.red, fontSize: 12)),
              ),
            const SizedBox(height: 16),

            _label('Email Address'),
            _field(
              controller: _emailCtrl,
              enabled: false, // email not editable
              suffix: const Icon(Icons.check_circle,
                  color: Color(0xFF047418), size: 20),
            ),
            const SizedBox(height: 16),

            _label('Location'),
            _editing
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _location,
                        isExpanded: true,
                        items: _locations
                            .map((l) =>
                                DropdownMenuItem(value: l, child: Text(l)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _location = v ?? _location),
                      ),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_location,
                            style: const TextStyle(fontSize: 14)),
                        const Icon(Icons.keyboard_arrow_down,
                            color: Colors.grey),
                      ],
                    ),
                  ),
            const SizedBox(height: 32),

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
                onPressed: () {
                  if (_editing) {
                    // TODO: save to backend
                    setState(() => _editing = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Changes saved')),
                    );
                  } else {
                    setState(() => _editing = true);
                  }
                },
                child: Text(
                  _editing ? 'Save Changes' : 'Edit',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600)),
      );

  Widget _field({
    required TextEditingController controller,
    bool enabled = true,
    TextInputType? keyboardType,
    Widget? suffix,
    String? hint,
  }) =>
      TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          suffixIcon: suffix != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: suffix,
                )
              : null,
          suffixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
          filled: true,
          fillColor:
              enabled ? Colors.white : Colors.grey.shade50,
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
            borderSide: const BorderSide(color: Color(0xFFFF7A33)),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      );

  Widget _verifyBadge(String label, {bool unverified = false}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF047418),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      );
}
