import 'dart:convert';
import 'package:http/http.dart' as http;

class BookingService {
  final String baseUrl = 'https://api.photobookhq.com/api';

  Future<List<dynamic>> getMySessions({required String token}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/sessions/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    print("📅 Sessions response: ${response.statusCode} ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return data;
      if (data is Map)
        return data['sessions'] ?? data['items'] ?? data['data'] ?? [];
      return [];
    } else if (response.statusCode == 401) {
      throw Exception('UNAUTHORIZED');
    } else {
      throw Exception('Failed to load sessions (${response.statusCode})');
    }
  }

  Future<List<dynamic>> getEventTypes({required String token}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/sessions/event-types'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("📋 Event types: $data");
      if (data is List) return data;
      return data['eventTypes'] ?? data['items'] ?? [];
    }
    throw Exception('Failed to load event types');
  }

  Future<bool> createSession({
    required String token,
    required String photographerId,
    required int eventTypeId,
    required String packageType,
    required String sessionDate,
    required String sessionTime,
    required String locationType,
    required String locationText,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sessions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "photographerId": photographerId,
        "eventTypeId": eventTypeId,
        "packageType": packageType,
        "sessionDate": sessionDate,
        "sessionTime": sessionTime,
        "locationType": locationType,
        "locationText": locationText,
      }),
    );
    print(
      "📅 Create session response: ${response.statusCode} ${response.body}",
    );
    return response.statusCode == 201;
  }

  Future<bool> deleteSession({
    required String token,
    required String sessionId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/sessions/$sessionId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200;
  }
}
