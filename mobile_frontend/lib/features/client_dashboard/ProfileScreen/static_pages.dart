import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Notifications ──────────────────────────────────────────────────────────

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _pushEnabled = true;
  bool _emailEnabled = true;
  // Which sub-categories are checked (persisted to SharedPreferences)
  String? _pushCategory;
  String? _emailCategory;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushEnabled = prefs.getBool('notif_push_enabled') ?? true;
      _emailEnabled = prefs.getBool('notif_email_enabled') ?? true;
      _pushCategory = prefs.getString('notif_push_category') ?? 'chat';
      _emailCategory = prefs.getString('notif_email_category') ?? 'chat';
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_push_enabled', _pushEnabled);
    await prefs.setBool('notif_email_enabled', _emailEnabled);
    if (_pushCategory != null) {
      await prefs.setString('notif_push_category', _pushCategory!);
    }
    if (_emailCategory != null) {
      await prefs.setString('notif_email_category', _emailCategory!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _appBar(context, 'Notifications'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Push Notifications'),
            _toggleRow('Push Notifications', _pushEnabled, (v) {
              setState(() => _pushEnabled = v);
              _save();
            }),
            if (_pushEnabled) ...[
              const Padding(
                padding: EdgeInsets.only(left: 4, top: 8, bottom: 4),
                child: Text('Enable for',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
              _radioRow('Chat Messages', 'chat', _pushCategory, (v) {
                setState(() => _pushCategory = v);
                _save();
              }),
              _radioRow('Promotions', 'promo', _pushCategory, (v) {
                setState(() => _pushCategory = v);
                _save();
              }),
              _radioRow('App Updates', 'updates', _pushCategory, (v) {
                setState(() => _pushCategory = v);
                _save();
              }),
            ],
            const SizedBox(height: 24),
            _sectionHeader('Email Notifications'),
            _toggleRow('Email Notifications', _emailEnabled, (v) {
              setState(() => _emailEnabled = v);
              _save();
            }),
            if (_emailEnabled) ...[
              const Padding(
                padding: EdgeInsets.only(left: 4, top: 8, bottom: 4),
                child: Text('Enable for',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
              _radioRow('Chat Messages', 'chat', _emailCategory, (v) {
                setState(() => _emailCategory = v);
                _save();
              }),
              _radioRow('Promotions', 'promo', _emailCategory, (v) {
                setState(() => _emailCategory = v);
                _save();
              }),
              _radioRow('App Updates', 'updates', _emailCategory, (v) {
                setState(() => _emailCategory = v);
                _save();
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold)),
      );

  Widget _toggleRow(String label, bool value, ValueChanged<bool> onChanged) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFFF7A33),
          ),
        ],
      );

  Widget _radioRow(
    String label,
    String value,
    String? groupValue,
    void Function(String) onChanged,
  ) =>
      Row(
        children: [
          Radio<String>(
            value: value,
            groupValue: groupValue,
            onChanged: (v) => onChanged(v!),
            activeColor: const Color(0xFFFF7A33),
          ),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      );
}

// ── Privacy Policy ─────────────────────────────────────────────────────────

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _appBar(context, 'Privacy Policy'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last updated July 12th 2026',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              'Lorem ipsum dolor sit amet consectetur. Aliquet in eget amet tempus varius vestibulum amet viverra. '
              'Aliquet malesuada et auctor viverra at leo. Duis eget vitae iaculis aliquet tincidunt justo etiam. '
              'In eget pellentesque pellentesque risus aliquam magna odio faucibus. Massa vel arcu dictum donec '
              'a at et lacus. Sit nec eget eros mi pellentesque vitae. Bibendum erat urna egestas nunc varius '
              'viverra amet scelerisque erat. Sagittis nam venenatis consectetur blandit purus ut ipsum urna. '
              'Felis sollicitudin urna mauris in sapien lacus velit. Egestas enim sapien eget enim varius cras '
              'at id varius. Egestas suscipit turpis non purus sed.\n\n'
              'Nascetur aliquam lorem egestas proin. Nullam ac nec morbi mauris tempor nunc amet.\n\n'
              'Non fermentum maecenas penatibus purus non ultrices aliquam purus. Fames sodales massa non enim '
              'amet malesuada tellus. Vel viverra eu aliquam in volutpat massa ipsum gravida magna.\n\n'
              'Condimentum dictum elit a laoreet at aliquam mattis in odio. Pharetra vel ultrices orci massa '
              'mattis. Vestibulum maecenas aliquet varius tempus bibendum dolor. Id urna in elementum sit viverra '
              'habitasse eu nisl. Nec consequat adipiscing egestas id in porttitor id. Scelerisque feugiat in '
              'tempus amet blandit. Posuere proin pellentesque elit pellentesque massa eu.\n\n'
              'Sed cursus duis nibh velit hac posuere hendrerit. Duis in quis nunc suscipit. Ornare feugiat '
              'pulvinar in tristique mattis. In facilisis condimentum volutpat consectetur at semper adipiscing '
              'aenean. Fermentum nec quis vulputate sit. Viverra.',
              style: TextStyle(fontSize: 13, height: 1.6, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Terms & Conditions ─────────────────────────────────────────────────────

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _appBar(context, 'Terms & Conditions'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last updated July 12th 2026',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              'Lorem ipsum dolor sit amet consectetur. Aliquet in eget amet tempus varius vestibulum amet viverra. '
              'Aliquet malesuada et auctor viverra at leo. Duis eget vitae iaculis aliquet tincidunt justo etiam. '
              'In eget pellentesque pellentesque risus aliquam magna odio faucibus. Massa vel arcu dictum donec '
              'a at et lacus. Sit nec eget eros mi pellentesque vitae. Bibendum erat urna egestas nunc varius '
              'viverra amet scelerisque erat. Sagittis nam venenatis consectetur blandit purus ut ipsum urna. '
              'Felis sollicitudin urna mauris in sapien lacus velit. Egestas enim sapien eget enim varius cras '
              'at id varius. Egestas suscipit turpis non purus sed.\n\n'
              'Nascetur aliquam lorem egestas proin. Nullam ac nec morbi mauris tempor nunc amet.\n\n'
              'Non fermentum maecenas penatibus purus non ultrices aliquam purus. Fames sodales massa non enim '
              'amet malesuada tellus. Vel viverra eu aliquam in volutpat massa ipsum gravida magna.\n\n'
              'Condimentum dictum elit a laoreet at aliquam mattis in odio. Pharetra vel ultrices orci massa '
              'mattis. Vestibulum maecenas aliquet varius tempus bibendum dolor. Id urna in elementum sit viverra '
              'habitasse eu nisl. Nec consequat adipiscing egestas id in porttitor id. Scelerisque feugiat in '
              'tempus amet blandit. Posuere proin pellentesque elit pellentesque massa eu.\n\n'
              'Sed cursus duis nibh velit hac posuere hendrerit. Duis in quis nunc suscipit. Ornare feugiat '
              'pulvinar in tristique mattis. In facilisis condimentum volutpat consectetur at semper adipiscing '
              'aenean. Fermentum nec quis vulputate sit. Viverra.',
              style: TextStyle(fontSize: 13, height: 1.6, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Help & Support ─────────────────────────────────────────────────────────

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _appBar(context, 'Help & Support'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _faqTile('How do I book a photographer?',
              'Browse photographers on the home screen, view their profile and rate card, then tap "Book Now" to create a session.'),
          _faqTile('How do I cancel a booking?',
              'Go to Bookings, find your session, and tap the cancel option. Cancellation policies vary by photographer.'),
          _faqTile('How do I message a photographer?',
              'Open a photographer\'s profile and tap "Message" to start a conversation.'),
          _faqTile('How do I update my profile?',
              'Go to Profile → Personal Information to update your name, phone, and location.'),
          _faqTile('How do I change my password?',
              'Go to Profile → Password & Security and enter your current and new passwords.'),
          const SizedBox(height: 20),
          const Text('Still need help?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          const Text('Email us at support@photobookhq.com',
              style: TextStyle(color: Color(0xFFFF7A33), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _faqTile(String question, String answer) => ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(question,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500)),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(answer,
                style: const TextStyle(
                    fontSize: 13, color: Colors.black54, height: 1.5)),
          ),
        ],
      );
}

// ── About PhotoBook ────────────────────────────────────────────────────────

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _appBar(context, 'About PhotoBook'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What Is PhotoBook',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF7A33)),
            ),
            const SizedBox(height: 10),
            const Text(
              'Lorem ipsum dolor sit amet consectetur. Aliquet in eget amet tempus varius vestibulum amet viverra. '
              'Aliquet malesuada et auctor viverra at leo. Duis eget vitae iaculis aliquet tincidunt justo etiam. '
              'In eget pellentesque pellentesque risus aliquam magna odio faucibus. Massa vel arcu dictum donec '
              'a at et lacus. Sit nec eget eros mi pellentesque vitae. Bibendum erat urna egestas nunc varius '
              'viverra amet scelerisque erat. Sagittis nam venenatis consectetur blandit purus ut ipsum urna. '
              'Felis sollicitudin urna mauris in sapien lacus.',
              style: TextStyle(fontSize: 13, height: 1.6, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            const Text(
              'Our Strengths',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF7A33)),
            ),
            const SizedBox(height: 10),
            const Text(
              'Lorem ipsum dolor sit amet consectetur. Aliquet in eget amet tempus varius vestibulum amet viverra. '
              'Aliquet malesuada et auctor viverra at leo. Duis eget vitae iaculis aliquet tincidunt justo etiam. '
              'In eget pellentesque pellentesque risus aliquam magna odio faucibus. Massa vel arcu dictum donec '
              'a at et lacus. Sit nec eget eros mi pellentesque vitae. Bibendum erat urna egestas nunc varius '
              'viverra amet scelerisque erat. Sagittis nam venenatis consectetur blandit purus ut ipsum urna. '
              'Felis sollicitudin urna mauris in sapien lacus.',
              style: TextStyle(fontSize: 13, height: 1.6, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            const Text(
              'Our Values',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF7A33)),
            ),
            const SizedBox(height: 10),
            const Text(
              'Lorem ipsum dolor sit amet consectetur. Aliquet in eget amet tempus varius vestibulum amet viverra. '
              'Aliquet malesuada et auctor viverra at leo. Duis eget vitae iaculis aliquet tincidunt justo etiam. '
              'In eget pellentesque pellentesque risus aliquam magna odio faucibus. Massa vel arcu dictum donec '
              'a at et lacus. Sit nec eget eros mi pellentesque vitae. Bibendum erat urna egestas nunc varius '
              'viverra amet scelerisque erat. Sagittis nam venenatis consectetur blandit purus ut ipsum urna. '
              'Felis sollicitudin urna mauris in sapien lacus.',
              style: TextStyle(fontSize: 13, height: 1.6, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared AppBar helper ───────────────────────────────────────────────────

PreferredSizeWidget _appBar(BuildContext context, String title) => AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        title,
        style: const TextStyle(
            color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
