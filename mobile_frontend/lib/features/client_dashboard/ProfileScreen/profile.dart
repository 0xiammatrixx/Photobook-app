import 'package:flutter/material.dart';
import 'package:mobile_frontend/features/client_dashboard/ProfileScreen/static_pages.dart';
import 'package:mobile_frontend/providers/user_provider.dart';
import 'package:mobile_frontend/services/authservice.dart';
import 'package:mobile_frontend/features/auth/login/loginscreen.dart';
import 'package:mobile_frontend/features/client_dashboard/ProfileScreen/personal_info_page.dart';
import 'package:mobile_frontend/features/client_dashboard/ProfileScreen/password_security_page.dart';
import 'package:provider/provider.dart';

class ClientProfileScreen extends StatelessWidget {
  ClientProfileScreen({super.key});
  final AuthService _authService = AuthService();

  Future<void> _logout(BuildContext context) async {
    await AuthService().logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
          "Are you sure? This action is permanent and cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await _authService.deleteAccount();
              if (success && context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Failed to delete account. Try again."),
                  ),
                );
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    final name = user?['name'] ?? 'Guest';
    final email = user?['email'] ?? '';

    final menuItems = [
      _MenuItem(
        icon: Icons.person_outline,
        label: 'Personal Information',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PersonalInfoPage()),
        ),
      ),
      _MenuItem(
        icon: Icons.lock_outline,
        label: 'Password & Security',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PasswordSecurityPage()),
        ),
      ),
      _MenuItem(
        icon: Icons.notifications_none,
        label: 'Notifications',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationsPage()),
        ),
      ),
      _MenuItem(
        icon: Icons.shield_outlined,
        label: 'Privacy Policy',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
        ),
      ),
      _MenuItem(
        icon: Icons.description_outlined,
        label: 'Terms & Conditions',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TermsPage()),
        ),
      ),
      _MenuItem(
        icon: Icons.headset_mic_outlined,
        label: 'Help & Support',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HelpSupportPage()),
        ),
      ),
      _MenuItem(
        icon: Icons.info_outline,
        label: 'About PhotoBook',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AboutPage()),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Orange header ──
          Container(
            width: double.infinity,
            color: const Color(0xFFFF7A33),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundColor: Colors.white24,
                            child: const Icon(
                              Icons.person,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Content ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Column(
                children: [
                  // Search bar
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search profile',
                      hintStyle: const TextStyle(
                          fontSize: 13, color: Colors.grey),
                      prefixIcon: const Icon(Icons.search,
                          color: Colors.grey, size: 20),
                      fillColor: Colors.grey.shade100,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Menu items
                  ...menuItems.map(
                    (item) => _MenuTile(item: item),
                  ),

                  const SizedBox(height: 16),

                  // Logout button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.red.withOpacity(0.05),
                      ),
                      onPressed: () => _logout(context),
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text(
                        'Logout',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuItem(
      {required this.icon, required this.label, required this.onTap});
}

class _MenuTile extends StatelessWidget {
  final _MenuItem item;
  const _MenuTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(item.icon, color: Colors.black87, size: 22),
          title: Text(
            item.label,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          trailing: const Icon(Icons.chevron_right,
              color: Colors.black38, size: 20),
          onTap: item.onTap,
        ),
        Divider(height: 1, color: Colors.grey.shade200),
      ],
    );
  }
}
