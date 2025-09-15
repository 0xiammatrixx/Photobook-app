import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:3000/api/auth';

   final GoogleSignIn _googleSignIn = GoogleSignIn(
     serverClientId: '586439540009-ele8av8d6u8sm24unkr5edu74vfhiip9.apps.googleusercontent.com',
   );

  /// Save token + user locally
  Future<void> _saveAuthData(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user', jsonEncode(user));
  }

  /// Login with email + password
  Future<bool> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      await _saveAuthData(data['token'], data['user']);
      return true;
    } else {
      print('Login failed: ${res.body}');
      return false;
    }
  }

  /// Signup with name + email + password
  Future<bool> signup(String name, String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password, 'role': 'client'}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      await _saveAuthData(data['token'], data['user']);
      return true;
    } else {
      print('Signup failed: ${res.body}');
      return false;
    }
  }

  /// Google Sign-In
  Future<bool> googleLogin() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false;

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) return false;

      final res = await http.post(
        Uri.parse('$baseUrl/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'access_token': idToken}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await _saveAuthData(data['token'], data['user']);
        return true;
      } else {
        print('Google login failed: ${res.body}');
        return false;
      }
    } catch (e) {
      print('Google sign in error: $e');
      return false;
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
    //await _googleSignIn.signOut();
  }
}
