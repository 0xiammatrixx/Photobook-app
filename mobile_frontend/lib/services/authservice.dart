import 'dart:convert';
import 'dart:io' show Platform;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'https://api.photobookhq.com/api/auth';

  /// Last error message from a failed auth call (for showing in the UI).
  String? lastError;

  /// Extract a human-readable message from a JSON error body.
  static String? messageFromBody(String body) {
    try {
      final decoded = jsonDecode(body);
      final msg = decoded['message'] ?? decoded['error'];
      return (msg is String && msg.trim().isNotEmpty) ? msg : null;
    } catch (_) {
      return null;
    }
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // On Android, `clientId` makes the SDK return an ID token (aud = web
    // client). On iOS we leave it unset so it uses the iOS GIDClientID from
    // Info.plist (aud = iOS client) — the backend verifies against both.
    clientId: Platform.isIOS
        ? null
        : '841792367578-3dnk4at4nbm0pvtpeh0aakeqlefcm8ba.apps.googleusercontent.com',
    serverClientId:
        '841792367578-3dnk4at4nbm0pvtpeh0aakeqlefcm8ba.apps.googleusercontent.com',
  );

  /// Save token + user locally
  Future<void> saveAuthData(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user', jsonEncode(user));
  }

  /// Login with email + password.
  /// Returns [LoginSuccess] with user data, [LoginRequires2FA] if 2FA is
  /// needed, or null on invalid credentials.
  Future<LoginResult?> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = jsonDecode(res.body);

      // 2FA required — backend returns temp token, no user yet
      if (data['requires2FA'] == true || data['tempToken'] != null) {
        return LoginRequires2FA(tempToken: data['tempToken'] ?? data['token']);
      }

      final user = data['user'];
      user['token'] = data['token'];
      await saveAuthData(data['token'], data['user']);
      return LoginSuccess(user: data['user'], token: data['token']);
    } else {
      print('Login failed: ${res.body}');
      return null;
    }
  }

  /// Returns null on success (account created, already exists, or created
  /// but the verification email failed). Returns an error message otherwise.
  Future<String?> signup(String name, String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/signup'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"name": name, "email": email, "password": password}),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return null;
      } else if (res.statusCode == 400) {
        final msg = messageFromBody(res.body) ?? '';
        // Account created but the verification email failed — treat as success
        // so the user can resend from the verification screen.
        if (msg.contains('email') || msg.contains('Failed to send')) {
          print(
            "⚠️ Account created but email failed. Redirecting to verify...",
          );
          return null;
        }
        print("❌ Signup failed (400): ${res.body}");
        return msg.isNotEmpty ? msg : 'Signup failed. Please try again.';
      } else if (res.statusCode == 409) {
        print("⚠️ Email already exists");
        return null; // already registered, go to verification to resend
      } else {
        print("❌ Signup failed (${res.statusCode}): ${res.body}");
        return messageFromBody(res.body) ??
            'Signup failed (${res.statusCode}). Please try again.';
      }
    } catch (e) {
      print("❌ Signup request error: $e");
      return 'Network error. Please check your connection and try again.';
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

      // Native Google sign-in returns a verifiable ID token (JWT). Because
      // serverClientId is configured, a one-time server auth code is also
      // available for the backend to exchange. Send both + the profile as a
      // convenience, so the backend can verify the token securely.
      final auth = await account.authentication;
      final idToken = auth.idToken;
      final serverAuthCode = auth.serverAuthCode;

      final profile = {
        "id": account.id,
        "email": account.email,
        "name": account.displayName,
        "photoUrl": account.photoUrl,
      };

      print(
        '📤 Google sign-in: idToken=${idToken != null}, '
        'serverAuthCode=${serverAuthCode != null}',
      );

      final res = await http.post(
        Uri.parse('$baseUrl/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (idToken != null) 'idToken': idToken,
          if (serverAuthCode != null) 'serverAuthCode': serverAuthCode,
          'profile': profile,
        }),
      );

      print("📥 Google login response: ${res.statusCode} ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        await saveAuthData(data['token'], data['user']);
        lastError = null;
        return data; // ✅ return full data so caller can read role
      } else {
        print('Google login failed: ${res.body}');
        lastError = messageFromBody(res.body) ??
            'Google sign-in failed (${res.statusCode}). Please try again.';
        return null;
      }
    } catch (e) {
      print('Google sign in error: $e');
      lastError = 'Google sign-in failed. Please try again.';
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

  // ──────────────────────────────────────────────
  //  Password Reset
  // ──────────────────────────────────────────────

  /// POST /api/auth/password-reset/request
  Future<PasswordResetResult> requestPasswordReset(String email) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/password-reset/request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      if (res.statusCode == 200) return PasswordResetResult.success;
      if (res.statusCode == 404) return PasswordResetResult.userNotFound;
      return PasswordResetResult.error;
    } catch (e) {
      print('❌ requestPasswordReset error: $e');
      return PasswordResetResult.error;
    }
  }

  /// POST /api/auth/password-reset/confirm
  Future<PasswordResetResult> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/password-reset/confirm'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code,
          'newPassword': newPassword,
        }),
      );
      if (res.statusCode == 200) return PasswordResetResult.success;
      if (res.statusCode == 400) return PasswordResetResult.invalidCode;
      if (res.statusCode == 404) return PasswordResetResult.userNotFound;
      return PasswordResetResult.error;
    } catch (e) {
      print('❌ confirmPasswordReset error: $e');
      return PasswordResetResult.error;
    }
  }

  /// PATCH /api/auth/change-password — change password while authenticated.
  Future<({bool success, String message})> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final res = await http.patch(
        Uri.parse('$baseUrl/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmNewPassword': newPassword,
        }),
      );
      print('🔑 changePassword [${res.statusCode}]: ${res.body}');
      if (res.statusCode == 200 || res.statusCode == 201) {
        return (success: true, message: 'Password changed successfully');
      }
      // Try to extract the backend's error message
      String msg = 'Failed to change password.';
      try {
        final body = jsonDecode(res.body);
        msg = body['message'] ?? body['error'] ?? msg;
      } catch (_) {}
      return (success: false, message: msg);
    } catch (e) {
      print('❌ changePassword error: $e');
      return (success: false, message: 'Network error. Please try again.');
    }
  }

  // ──────────────────────────────────────────────
  //  2FA
  // ──────────────────────────────────────────────

  /// POST /api/auth/2fa/setup — returns { secret, qrCodeUrl, backupCodes }
  Future<Map<String, dynamic>?> setup2FA(String token) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/2fa/setup'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
      print('❌ setup2FA failed [${res.statusCode}]: ${res.body}');
      return null;
    } catch (e) {
      print('❌ setup2FA error: $e');
      return null;
    }
  }

  /// POST /api/auth/2fa/confirm
  Future<bool> confirm2FA({
    required String token,
    required String totpToken,
    required String secret,
    required List<String> backupCodes,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/2fa/confirm'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'token': totpToken,
          'secret': secret,
          'backupCodes': backupCodes,
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('❌ confirm2FA error: $e');
      return false;
    }
  }

  /// DELETE /api/auth/2fa/disable
  Future<bool> disable2FA(String token) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/2fa/disable'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return res.statusCode == 200;
    } catch (e) {
      print('❌ disable2FA error: $e');
      return false;
    }
  }

  /// POST /api/auth/2fa/verify — used during login
  Future<Map<String, dynamic>?> verify2FA({
    required String token,
    String? backupCode,
  }) async {
    try {
      final body = <String, dynamic>{'token': token};
      if (backupCode != null) body['backupCode'] = backupCode;

      final res = await http.post(
        Uri.parse('$baseUrl/2fa/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
      print('❌ verify2FA failed [${res.statusCode}]: ${res.body}');
      return null;
    } catch (e) {
      print('❌ verify2FA error: $e');
      return null;
    }
  }
}

enum PasswordResetResult { success, invalidCode, userNotFound, error }

// ── Login result types ──
sealed class LoginResult {}

class LoginSuccess extends LoginResult {
  final Map<String, dynamic> user;
  final String token;
  LoginSuccess({required this.user, required this.token});
}

class LoginRequires2FA extends LoginResult {
  final String tempToken;
  LoginRequires2FA({required this.tempToken});
}
