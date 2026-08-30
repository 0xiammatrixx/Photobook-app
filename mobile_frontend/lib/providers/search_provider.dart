// providers/search_provider.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_frontend/services/search_service.dart';

class SearchProvider extends ChangeNotifier {
  final _service = SearchService();
  List<dynamic> _topPhotographers = [];
  bool isLoading = false;

  List<dynamic> get topPhotographers => _topPhotographers;

  // Hub "Explore Other Creatives" — server-side role filtering.
  List<dynamic> _hubCreatives = [];
  bool _hubLoading = false;

  List<dynamic> get hubCreatives => _hubCreatives;
  bool get hubLoading => _hubLoading;

  List<String> _trendingTags = [];

  // Search state
  List<dynamic> _searchPhotographers = [];
  List<String> _searchTags = [];
  bool isSearching = false;
  bool get hasSearchResults => _searchPhotographers.isNotEmpty || _searchTags.isNotEmpty;

  List<dynamic> get searchPhotographers => _searchPhotographers;
  List<String> get searchTags => _searchTags;

  Timer? _debounce;

  Future<void> loadTopPhotographers() async {
    isLoading = true;
    notifyListeners();
    try {
      _topPhotographers = await _service.getTopPhotographers();
      _trendingTags = await _service.getTrendingTags();
    } catch (e) {
      print("❌ Failed to load top photographers: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void onSearchChanged(String query) {
    _debounce?.cancel();

    if (query.trim().isEmpty) {
      _searchPhotographers = [];
      _searchTags = [];
      isSearching = false;
      notifyListeners();
      return;
    }

    // Filter tags locally immediately
    final q = query.toLowerCase();
    _searchTags = _trendingTags
        .where((tag) => tag.toLowerCase().contains(q))
        .take(5)
        .toList();
    isSearching = true;
    notifyListeners();

    // Debounce photographer API call
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        _searchPhotographers = await _service.searchPhotographers(query.trim());
      } catch (e) {
        print("❌ Search failed: $e");
        _searchPhotographers = [];
      } finally {
        isSearching = false;
        notifyListeners();
      }
    });
  }

  void clearSearch() {
    _debounce?.cancel();
    _searchPhotographers = [];
    _searchTags = [];
    isSearching = false;
    notifyListeners();
  }

  /// Load creatives for the Hub, filtered server-side by role.
  /// role: null = all, 'photographer' | 'videographer' | 'content_creator'.
  Future<void> loadHubCreatives(String? role) async {
    if (_hubLoading) return;
    _hubLoading = true;
    notifyListeners();
    try {
      // For 'all' use the photographers alias endpoint which has no role
      // restriction yet; role-specific calls use /search/users.
      final list = await _service.searchUsers(
        role: role == 'all' || role == null ? 'all' : role,
        sort: 'rating',
        limit: 50,
      );
      _hubCreatives = list;
    } catch (e) {
      print('❌ loadHubCreatives failed: $e');
      _hubCreatives = [];
    } finally {
      _hubLoading = false;
      notifyListeners();
    }
  }
}