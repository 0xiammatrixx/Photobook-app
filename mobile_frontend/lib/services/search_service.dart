// services/search_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class SearchService {
  final String baseUrl = 'https://api.photobookhq.com/api';

  /// GET /api/search/users — discovery endpoint with role filtering.
  /// role: photographer | client | all (videographer/content_creator coming)
  Future<List<dynamic>> searchUsers({
    String? role,
    String sort = 'rating',
    int limit = 50,
    int offset = 0,
    String? q,
  }) async {
    final params = <String, String>{
      'sort': sort,
      'limit': limit.toString(),
      'offset': offset.toString(),
      if (role != null) 'role': role,
      if (q != null && q.isNotEmpty) 'q': q,
    };
    final uri = Uri.parse('$baseUrl/search/users')
        .replace(queryParameters: params);
    final response = await http.get(uri);

    print('🔍 searchUsers(role=$role) [${response.statusCode}]: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List
          ? data
          : data['items'] ?? data['users'] ?? data['results'] ?? data['data'] ?? [];
    }
    return [];
  }

  Future<List<dynamic>> getTopPhotographers({int limit = 50}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/search/photographers?sort=rating&limit=$limit'),
    );

    print("🔍 Top photographers response: ${response.statusCode} ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<dynamic> results = data is List
          ? data
          : data['items'] ?? data['users'] ?? data['results'] ?? data['data'] ?? [];

      // Shuffle so each user sees a different order
      results.shuffle(Random());
      return results;
    }
    throw Exception('Failed to load photographers (${response.statusCode})');
  }

  Future<List<dynamic>> searchPhotographers(String query) async {
  final response = await http.get(
    Uri.parse('$baseUrl/search/photographers?q=${Uri.encodeComponent(query)}&limit=5'),
  );
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['items'] ?? data['users'] ?? data['results'] ?? data['data'] ?? [];
  }
  return [];
}

Future<List<String>> getTrendingTags({int limit = 50}) async {
  final response = await http.get(
    Uri.parse('$baseUrl/search/tags/trending?limit=$limit'),
  );
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final raw = data is List ? data : data['tags'] ?? data['items'] ?? [];
    return List<String>.from(raw.map((t) => t is String ? t : t['tag'] ?? t['name'] ?? ''));
  }
  return [];
}
}

