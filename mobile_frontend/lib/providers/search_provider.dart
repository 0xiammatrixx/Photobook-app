// providers/search_provider.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_frontend/services/search_service.dart';

class SearchProvider extends ChangeNotifier {
  final _service = SearchService();
  List<dynamic> _topPhotographers = [];
  bool isLoading = false;

  List<dynamic> get topPhotographers => _topPhotographers;

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
}