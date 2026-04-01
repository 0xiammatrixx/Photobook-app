import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  Map<String, dynamic>? _user;
  String? _token;

  Map<String, dynamic>? get user => _user;
  String? get token => _token;
  String? get id => _user?['_id'];
  String? get name => _user?['name'];
  String? get email => _user?['email'];
  String? get role => _user?['role'];

  /// Load from SharedPreferences
  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    final tokenStr = prefs.getString('token');
    
    if (userStr != null) {
      _user = jsonDecode(userStr);
      print('📱 User loaded: ${_user?['_id']}, role: ${_user?['role']}');
    }
    if (tokenStr != null) {
      _token = tokenStr;
      print('🔑 Token loaded: ${_token?.substring(0, 20)}...');
    }
    notifyListeners();
  }

  /// Save user and token separately
  Future<void> setUser(Map<String, dynamic> user, String token) async {
    _user = user;
    _token = token;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user));
    await prefs.setString('token', token);
    
    print('💾 User saved: ${user['_id']}');
    notifyListeners();
  }

  // void updateFromProfile(Map<String, dynamic> updatedFields) {
  //   if (_user != null) {
  //     _user = {..._user!, ...updatedFields};
  //     notifyListeners();
  //   }
  // }

  void updateBasicInfo(Map<String, dynamic> updates) {
    if (_user != null) {
      _user = {..._user!, ...updates};
      notifyListeners();
    }
  }

  /// Clear on logout
  Future<void> clearUser() async {
    _user = null;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('token');
    notifyListeners();
  }
}