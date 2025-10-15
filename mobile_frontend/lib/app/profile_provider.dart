import 'package:flutter/material.dart';

class ProfileProvider extends ChangeNotifier {
  Map<String, dynamic>? _profile;

  Map<String, dynamic>? get profile => _profile;

  void setProfile(Map<String, dynamic> profile) {
    _profile = profile;
    notifyListeners();
  }

  void updateProfileFields(Map<String, dynamic> updates) {
    if (_profile != null) {
      _profile = {..._profile!, ...updates};
      notifyListeners();
    }
  }

  void clearProfile() {
    _profile = null;
    notifyListeners();
  }
}
