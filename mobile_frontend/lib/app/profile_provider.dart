import 'package:flutter/material.dart';

class ProfileProvider extends ChangeNotifier {
  Map<String, dynamic>? _profile;

  Map<String, dynamic>? get profile => _profile;

  /// Set the entire profile (e.g., from backend)
  void setProfile(Map<String, dynamic> profile) {
    _profile = profile;
    notifyListeners();
  }

  /// Update specific fields inside the profile
  void updateProfileFields(Map<String, dynamic> updates) {
    if (_profile != null) {
      _profile = {..._profile!, ...updates};
      notifyListeners();
    }
  }

  /// Add a new portfolio item
  void addPortfolioItem(Map<String, dynamic> newItem) {
    if (_profile == null) return;

    final creative = Map<String, dynamic>.from(_profile?['creativeDetails'] ?? {});
    final portfolio = List<Map<String, dynamic>>.from(creative['portfolio'] ?? []);

    portfolio.insert(0, newItem);
    creative['portfolio'] = portfolio;
    _profile!['creativeDetails'] = creative;

    notifyListeners();
  }

  /// Remove a portfolio item by ID
  void removePortfolioItem(String itemId) {
    if (_profile == null) return;

    final creative = Map<String, dynamic>.from(_profile?['creativeDetails'] ?? {});
    final portfolio = List<Map<String, dynamic>>.from(creative['portfolio'] ?? []);

    portfolio.removeWhere((item) => item['_id'] == itemId);
    creative['portfolio'] = portfolio;
    _profile!['creativeDetails'] = creative;

    notifyListeners();
  }

  /// Clear everything (e.g., on logout)
  void clearProfile() {
    _profile = null;
    notifyListeners();
  }
}
