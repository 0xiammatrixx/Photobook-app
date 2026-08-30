import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_frontend/features/creative_dashboard/ProfilePage/reviewmodel.dart';

class ReviewService {
  final String baseUrl = 'https://api.photobookhq.com/api';

  /// POST /api/sessions/{id}/review — submit a rating + written review for a
  /// completed session (client only).
  Future<({bool success, String message})> submitReview({
    required String token,
    required String sessionId,
    required int rating,
    required String comment,
  }) async {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final body = jsonEncode({'rating': rating, 'comment': comment});

    final response = await http.post(
      Uri.parse('$baseUrl/sessions/$sessionId/review'),
      headers: headers,
      body: body,
    );
    print('⭐ Submit review [${response.statusCode}]: ${response.body}');

    if (response.statusCode == 201) {
      return (success: true, message: 'Thanks for your feedback!');
    }

    switch (response.statusCode) {
      case 400:
        return (
          success: false,
          message:
              'This session can\'t be reviewed yet — it may not be completed '
              'or the rating is invalid.',
        );
      case 403:
        return (
          success: false,
          message: 'Only the client for this session can leave a review.',
        );
      case 404:
        return (success: false, message: 'Session not found.');
      case 409:
        return (
          success: false,
          message: 'You\'ve already reviewed this session.',
        );
      default:
        return (
          success: false,
          message: 'Failed to submit review (${response.statusCode})',
        );
    }
  }

  /// GET reviews for a profile by its UUID. The API only exposes
  /// GET /api/profiles/{id}/reviews (there is no "me" alias), so a real
  /// profile UUID is required.
  Future<List<Review>> getReviews({
    required String token,
    required String userId,
    int limit = 50,
  }) async {
    final headers = {'Authorization': 'Bearer $token'};
    final uri = Uri.parse('$baseUrl/profiles/$userId/reviews')
        .replace(queryParameters: {'limit': '$limit'});

    try {
      final response = await http.get(uri, headers: headers);
      final snippet = response.body.length > 300
          ? response.body.substring(0, 300)
          : response.body;
      print('⭐ Get reviews [$uri → ${response.statusCode}]: $snippet');
      if (response.statusCode == 200) {
        return _parseReviews(jsonDecode(response.body));
      }
    } catch (e) {
      print('❌ getReviews error: $e');
    }
    return [];
  }

  List<Review> _parseReviews(dynamic data) {
    List<dynamic> items;
    if (data is List) {
      items = data;
    } else if (data is Map) {
      items = (data['reviews'] ?? data['items'] ?? data['data'] ?? []) as List;
    } else {
      return [];
    }
    return items
        .whereType<Map>()
        .map((e) => Review.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
