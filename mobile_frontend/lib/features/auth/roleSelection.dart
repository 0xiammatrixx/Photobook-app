import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_frontend/features/auth/businessName.dart';
import 'package:mobile_frontend/features/client_dashboard/bottom_nav_bar.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  String? _selectedRole;
  bool _loading = false;

  // call backend PATCH /role
  Future<void> _updateRoleAndProceed() async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a role first")),
      );
      return;
    }
    setState(() => _loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      String roleForBackend;
      if (_selectedRole == "Creative") {
        roleForBackend = "photographer";
      } else {
        roleForBackend = _selectedRole!.toLowerCase();
      }

      final response = await http.patch(
        Uri.parse("http://10.0.2.2:5000/api/auth/role"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode({"role": roleForBackend}),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        if (mounted) {
          if (roleForBackend == "photographer") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => BusinessNamePage()),
          );
        } else if(roleForBackend == "client"){
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => BottomTabs()),
          );
        }
        
        }
      } else {
        final err = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed: ${err['message'] ?? 'Unknown error'}"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Who am I?",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF181818),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Select the account use",
                  style: TextStyle(color: Color(0xFF181818), fontSize: 14),
                ),
                const SizedBox(height: 30),

                GestureDetector(
                  onTap: () => setState(() => _selectedRole = "Client"),
                  child: _roleButton("Client"),
                ),
                GestureDetector(
                  onTap: () => setState(() => _selectedRole = "Creative"),
                  child: _roleButton("Creative"),
                ),
                ElevatedButton(
                  onPressed: (_selectedRole == null || _loading)
                      ? null
                      : _updateRoleAndProceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A33),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Join",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleButton(String role) {
    return Container(
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.only(bottom: 15),
      width: double.infinity,
      decoration: BoxDecoration(
        color: _selectedRole == role ? Color(0xFFFF7A33) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black26),
      ),
      child: Text(
        role,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _selectedRole == role ? Colors.white : Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
