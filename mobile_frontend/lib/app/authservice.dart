import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:5000/api/auth';

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

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      await _saveAuthData(data['token'], data['user']);
      return data['user']; // return user map
    } else {
      print('Login failed: ${res.body}');
      return null;
    }
  }

  /// Signup with name + email + password
  Future<Map<String, dynamic>?> signup(
    String name,
    String email,
    String password,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': 'client',
      }),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      await _saveAuthData(data['token'], data['user']);
      return data['user'];
    } else {
      print('Signup failed: ${res.body}');
      return null;
    }
  }

  /// Google Sign-In
  Future<Map<String, dynamic>?> googleLogin() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null;

      final auth = await account.authentication;
      final accessToken = auth.accessToken;
      if (accessToken == null) return null;

      final res = await http.post(
        Uri.parse('$baseUrl/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'access_token': accessToken}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await _saveAuthData(data['token'], data['user']);
        return data['user'];
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

    final res = await http.put(
      Uri.parse('$baseUrl/update-business'), // <-- backend endpoint
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'businessName': businessName}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      // Save locally
      await _saveAuthData(token, data['user']);
      return data['user'];
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
}
