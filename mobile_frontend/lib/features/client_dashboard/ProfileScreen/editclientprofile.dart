import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:mobile_frontend/features/client_dashboard/ProfileScreen/profile.dart';

class EditClientProfilePage extends StatefulWidget {
  const EditClientProfilePage({super.key});

  @override
  State<EditClientProfilePage> createState() => _EditClientProfilePageState();
}

class _EditClientProfilePageState extends State<EditClientProfilePage> {
  final _formKey = GlobalKey<FormState>();

  // mock profile data (replace with backend data)
  String name = "Tolu Makinde";
  File? profileImage; // local file for new image

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Edit Profile",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                // TODO: send updated data to backend
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => ClientProfileScreen()),
                );
              }
            },
            child: const Text(
              "Save",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// --- Profile Picture Upload ---
              Center(
                child: GestureDetector(
                  onTap: () {
                    // TODO: pick new image
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Opacity(
                          opacity: 0.7, // less opaque
                          child: SvgPicture.asset(
                            "assets/timmonprofile.svg",
                            width: 117,
                            height: 103,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Container(
                        width: 117,
                        height: 103,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.black.withOpacity(0.3),
                        ),
                        child: const Icon(
                          Icons.camera_alt, // or Icons.edit
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                "Phone Number",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: IntlPhoneField(
                    decoration: const InputDecoration(
                      hintText: "Enter phone number",
                      border: OutlineInputBorder(),
                    ),
                    initialCountryCode: 'NG',
                    onSaved: (phone) {
                      final rawNumber = phone?.completeNumber ?? "";
                      // assign rawNumber to your model / form data
                    },
                    validator: (phone) {
                      if (phone == null || phone.number.isEmpty) {
                        return "Enter a phone number";
                      }
                      return null;
                    },
                  ),
                ),
              ),

              /// --- Save Button (fallback if not using AppBar save) ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      // TODO: push to backend
                      Navigator.pop(context);
                    }
                  },
                  child: const Text(
                    "Save Changes",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
