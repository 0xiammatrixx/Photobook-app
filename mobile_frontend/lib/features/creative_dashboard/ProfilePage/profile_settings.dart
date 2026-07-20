import 'package:flutter/material.dart';
import 'package:mobile_frontend/features/auth/login/loginscreen.dart';
import 'package:mobile_frontend/features/client_dashboard/ProfileScreen/password_security_page.dart';
import 'package:mobile_frontend/features/client_dashboard/ProfileScreen/static_pages.dart';
import 'package:mobile_frontend/features/creative_dashboard/ProfilePage/bank_account_page.dart';
import 'package:mobile_frontend/features/creative_dashboard/ProfilePage/business_info_page.dart';
import 'package:mobile_frontend/services/authservice.dart';

class CreativeSettingsPage extends StatelessWidget {
  const CreativeSettingsPage({super.key});

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
          'Settings',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Account ──
            const Text('Account', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFFF7A33))),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.person_outline,
              label: 'Business Information',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessInfoPage())),
            ),
            _SettingsTile(
              icon: Icons.lock_outline,
              label: 'Password & Security',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PasswordSecurityPage())),
            ),
            _SettingsTile(
              icon: Icons.notifications_none,
              label: 'Notifications',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage())),
            ),

            const SizedBox(height: 20),

            // ── Payments ──
            const Text('Payments', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFFF7A33))),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.account_balance_outlined,
              label: 'Bank Account',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BankAccountPage())),
            ),
            _SettingsTile(
              icon: Icons.credit_card_outlined,
              label: 'Payout/Earnings',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coming soon')),
                );
              },
            ),

            const SizedBox(height: 20),

            // ── Support ──
            const Text('Support', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFFF7A33))),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.headset_mic_outlined,
              label: 'Help & Support',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportPage())),
            ),
            _SettingsTile(
              icon: Icons.shield_outlined,
              label: 'Privacy Policy',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyPage())),
            ),
            _SettingsTile(
              icon: Icons.description_outlined,
              label: 'Terms & Conditions',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsPage())),
            ),

            const SizedBox(height: 32),

            // ── Logout ──
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.red.withOpacity(0.05),
                ),
                onPressed: () async {
                  await AuthService().logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SettingsTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: Colors.black87, size: 22),
          title: Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87)),
          trailing: const Icon(Icons.chevron_right, color: Colors.black38, size: 20),
          onTap: onTap,
        ),
        Divider(height: 1, color: Colors.grey.shade200),
      ],
    );
  }
}