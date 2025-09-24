import 'package:flutter/material.dart';
import 'package:mobile_frontend/app/authservice.dart';
import 'package:mobile_frontend/features/creative_dashboard/bottom_nav_bar.dart';

class BusinessNamePage extends StatefulWidget {
  @override
  _BusinessNamePageState createState() => _BusinessNamePageState();
}

class _BusinessNamePageState extends State<BusinessNamePage> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _loading = false;

  final AuthService _authService = AuthService();

  Future<void> _saveBusinessName() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final user = await _authService.updateBusinessName(
      _controller.text.trim(),
    );

    setState(() => _loading = false);

    if (user != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => CreativeBottomTabs()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save business name')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Your Business Name")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: "Business Name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter your business name" : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _saveBusinessName,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Continue"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
