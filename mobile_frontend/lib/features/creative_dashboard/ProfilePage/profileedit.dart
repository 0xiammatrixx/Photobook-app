import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_frontend/providers/profile_provider.dart';
import 'package:mobile_frontend/providers/user_provider.dart';
import 'package:mobile_frontend/services/profileservice.dart';
import 'package:provider/provider.dart';
import 'dart:io';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  List<String> _categories = [];
  final TextEditingController _categoryController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _profileService = ProfilePortfolioService();

  String businessName = "";
  String displayName = "";
  String aboutMe = "";
  File? profileImage;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  void _addCategory(String value) {
    final text = value.trim();
    if (text.isNotEmpty && !_categories.contains(text)) {
      setState(() => _categories.add(text));
    }
    _categoryController.clear();
  }

  void _removeCategory(String cat) {
    setState(() => _categories.remove(cat));
  }

  Future<void> _loadCurrentProfile() async {
    try {
      final profileProvider = Provider.of<ProfileProvider>(
        context,
        listen: false,
      );
      final profile = profileProvider.profile;

      if (profile != null) {
        setState(() {
          businessName = profile['basic']?['businessName'] ?? '';
          displayName = profile['basic']?['displayTitle'] ?? '';
          aboutMe = profile['creativeDetails']?['aboutMe'] ?? '';
          _categories = List<String>.from(
            profile['basic']?['tags'] ?? // ✅ was 'categories'
                profile['creativeDetails']?['tags'] ??
                [],
          );
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _loading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final profileProvider = Provider.of<ProfileProvider>(
        context,
        listen: false,
      );
      final token = userProvider.token;

      if (token == null) throw Exception('Not authenticated');

      final success = await _profileService.updateCreativeProfile(
        token: token,
        businessName: businessName,
        displayName: displayName,
        aboutMe: aboutMe,
        tags: _categories,
      );

      if (success) {
        userProvider.updateBasicInfo({
          "businessName": businessName,
          "displayTitle": displayName,
          "tags": _categories,
        });

        profileProvider.updateProfileFields({
          "basic": {"businessName": businessName, "displayTitle": displayName, "tags": _categories,},
          "creativeDetails": {"aboutMe": aboutMe},
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Profile updated successfully!")),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Update failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => profileImage = File(picked.path));

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final profileProvider = Provider.of<ProfileProvider>(
        context,
        listen: false,
      );
      print("🖼️ Picked image path: ${picked.path}");
      print("🔑 Token before upload: ${userProvider.token}");
      final url = await _profileService.uploadAvatar(
        token: userProvider.token!,
        filePath: picked.path,
      );

      await _profileService.updateCreativeProfile(
        token: userProvider.token!,
        profilePhotoUrl: url, // ✅ now sent to the right endpoint
      );

      userProvider.updateBasicInfo({"avatarUrl": url});
      profileProvider.updateProfileFields({
        "basic": {"avatarUrl": url},
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("✅ Avatar updated!")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Upload failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
            onPressed: _loading ? null : _saveProfile,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF7A33)),
                  )
                : const Text(
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
                  onTap: _pickAvatar,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: profileImage != null
                            ? Image.file(
                                profileImage!,
                                width: 117,
                                height: 103,
                                fit: BoxFit.cover,
                              )
                            : Opacity(
                                opacity: 0.7,
                                child: Image.asset(
                                  "assets/profileplaceholder.png",
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
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              /// --- Business Name ---
              const Text(
                "Business Name",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextFormField(
                initialValue: businessName,
                onSaved: (val) => businessName = val ?? "",
                validator: (val) =>
                    val == null || val.isEmpty ? "Enter business name" : null,
                decoration: const InputDecoration(
                  hintText: "e.g., Timmon Photography",
                ),
              ),
              const SizedBox(height: 16),

              /// --- Display Name ---
              const Text(
                "Display Name / Profession",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextFormField(
                initialValue: displayName,
                onSaved: (val) => displayName = val ?? "",
                decoration: const InputDecoration(
                  hintText: "e.g., Corporate Photographer",
                ),
              ),
              const SizedBox(height: 16),

              /// --- About Me ---
              const Text(
                "About Me",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextFormField(
                initialValue: aboutMe,
                maxLines: 5,
                onSaved: (val) => aboutMe = val ?? "",
                decoration: const InputDecoration(
                  hintText: "Tell clients about yourself...",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              ///Tags
              const Text("Tags", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final cat in _categories)
                      Chip(
                        label: Text(cat),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () => _removeCategory(cat),
                        backgroundColor: const Color(
                          0xFFFF7A33,
                        ).withOpacity(0.1),
                        labelStyle: const TextStyle(color: Colors.black),
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(color: Color(0xFFFF7A33)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: TextField(
                        controller: _categoryController,
                        onSubmitted: _addCategory,
                        decoration: const InputDecoration(
                          hintText: "Add tag...",
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              /// --- Save Button ---
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
                  onPressed: _loading ? null : _saveProfile,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Color(0xFFFF7A33),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
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
