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
  if (_profile == null) return;
  for (final key in updates.keys) {
    if (_profile![key] is Map && updates[key] is Map) {
      _profile![key] = {
        ...(_profile![key] as Map<String, dynamic>),
        ...(updates[key] as Map<String, dynamic>),
      };
    } else {
      _profile![key] = updates[key];
    }
  }
  notifyListeners();
}

  /// Add a new portfolio item
  void addPortfolioItem(Map<String, dynamic> newItem) {
    if (_profile == null) return;
    final raw = Map<String, dynamic>.from(
      newItem['item'] ?? newItem['portfolioItem'] ?? newItem,
    );

    // ✅ Remap to consistent keys
    final item = {
      ...raw,
      'url': raw['url'] ?? raw['media_url'],
      'type': raw['type'] ?? raw['media_type'],
    };
    final creative = Map<String, dynamic>.from(
      _profile?['creativeDetails'] ?? {},
    );
    final portfolio = List<Map<String, dynamic>>.from(
      creative['portfolio'] ?? [],
    );
    portfolio.insert(0, Map<String, dynamic>.from(item));
    creative['portfolio'] = portfolio;
    _profile!['creativeDetails'] = creative;
    notifyListeners();
  }

  /// Remove a portfolio item by ID
  void removePortfolioItem(String itemId) {
    if (_profile == null) return;

    final creative = Map<String, dynamic>.from(
      _profile?['creativeDetails'] ?? {},
    );
    final portfolio = List<Map<String, dynamic>>.from(
      creative['portfolio'] ?? [],
    );

    portfolio.removeWhere(
      (item) => item['id'] == itemId || item['_id'] == itemId,
    );
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
