import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'https://api.photobookhq.com/api/auth';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        '586439540009-ele8av8d6u8sm24unkr5edu74vfhiip9.apps.googleusercontent.com',
  );

  /// Save token + user locally
  Future<void> _saveAuthData(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user', jsonEncode(user));
  }

  /// Login with email + password
  Future<Map<String, dynamic>?> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = jsonDecode(res.body);
      final user = data['user'];
      user['token'] = data['token'];
      await _saveAuthData(data['token'], data['user']);
      return data['user']; // return user map
    } else {
      print('Login failed: ${res.body}');
      return null;
    }
  }

  Future<bool> signup(String name, String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/signup'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"name": name, "email": email, "password": password}),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return true;
      } else if (res.statusCode == 400) {
        final body = jsonDecode(res.body);
        // Account created but email failed — treat as success, resend will handle it
        if (body['message'].toString().contains('email') ||
            body['message'].toString().contains('Failed to send')) {
          print(
            "⚠️ Account created but email failed. Redirecting to verify...",
          );
          return true; // navigate to verification so user can resend
        }
        print("❌ Signup failed (400): ${res.body}");
        return false;
      } else if (res.statusCode == 409) {
        print("⚠️ Email already exists");
        return true; // already registered, go to verification to resend
      } else {
        print("❌ Signup failed (${res.statusCode}): ${res.body}");
        return false;
      }
    } catch (e) {
      print("❌ Signup request error: $e");
      return false;
    }
  }

  Future<bool> verifyEmail(String email, String code) async {
    final res = await http.post(
      Uri.parse('$baseUrl/verify-email'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "code": code}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      await prefs.setString('user', jsonEncode(data['user']));
      return true;
    } else {
      print("Verify email failed [${res.statusCode}]: ${res.body}");
      return false;
    }
  }

  Future<bool> resendVerification(String email) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/verify-email/resend'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return true;
      } else {
        print("❌ Resend failed: ${res.body}");
        return false;
      }
    } catch (e) {
      print("❌ Resend error: $e");
      return false;
    }
  }

  /// Google Sign-In
  Future<Map<String, dynamic>?> googleLogin() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null;

      // Send the full profile object the backend expects
      final profile = {
        "id": account.id,
        "email": account.email,
        "name": account.displayName,
        "photoUrl": account.photoUrl,
      };

      print("📤 Google profile: $profile");

      final res = await http.post(
        Uri.parse('$baseUrl/auth/google'), // ✅ fixed URL
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'profile': profile}),
      );

      print("📥 Google login response: ${res.statusCode} ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        await _saveAuthData(data['token'], data['user']);
        return data; // ✅ return full data so caller can read role
      } else {
        print('Google login failed: ${res.body}');
        return null;
      }
    } catch (e) {
      print('Google sign in error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateBusinessName(String businessName) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return null;

    final res = await http.patch(
      Uri.parse('https://api.photobookhq.com/api/profiles/photographer'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'businessName': businessName}),
    );

    print("Business name response: ${res.statusCode} ${res.body}");

    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = jsonDecode(res.body);
      final profile = data['profile'];
      if (profile != null && profile is Map<String, dynamic>) {
        return profile;
      }
      return null;
    } else {
      print("Update business name failed: ${res.body}");
      return null;
    }
  }

  /// Get saved user data
  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr == null) return null;
    return jsonDecode(userStr);
  }

  /// Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    // await _googleSignIn.signOut();
  }

  Future<bool> deleteAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userJson = prefs.getString('user');
    final userId = jsonDecode(
      userJson!,
    )['id']; // or '_id' depending on your API

    final res = await http.delete(
      Uri.parse('https://api.photobookhq.com/api/users/me'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"userId": userId}),
    );

    if (res.statusCode == 200) {
      await prefs.clear(); // wipe token + user data
      return true;
    } else {
      print("Delete account failed [${res.statusCode}]: ${res.body}");
      return false;
    }
  }
}
