import 'dart:convert';
import 'package:http/http.dart' as http;

class BookingService {
  final String baseUrl = 'https://api.photobookhq.com/api';

  /// GET /api/rate-card/{photographerId} — public rate card.
  Future<List<dynamic>> getPublicRateCard({
    required String photographerId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/rate-card/$photographerId'),
    );
    print('📦 Public rate card [${response.statusCode}]: ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return data;
      return data['items'] ?? data['rateCard'] ?? data['data'] ?? [];
    }
    return [];
  }

  /// Free address lookup via OpenStreetMap Nominatim.
  Future<List<Map<String, dynamic>>> searchAddress(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}&format=json&limit=5',
      );
      final res = await http.get(uri, headers: {
        'User-Agent': 'PhotoBookApp/1.0',
        'Accept-Language': 'en',
      });
      if (res.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(res.body));
      }
    } catch (_) {}
    return [];
  }

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
      return data['eventTypes'] ?? data['items'] ?? data['data'] ?? [];
    }
    throw Exception('Failed to load event types');
  }

  Future<Map<String, dynamic>?> createSession({
    required String token,
    required String photographerId,
    required String creativeType,
    required int eventTypeId,
    required String rateCardItemId,
    required String sessionDate,
    required String sessionTime,
    required String sessionEndTime,
    required String locationType,
    required String locationText,
    required bool useCreativeStudio,
    int? numberOfOutfits,
    int? numberOfShootingLocations,
    String? deliverableType,
    String? notes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sessions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "photographerId": photographerId,
        "creativeType": creativeType,
        "eventTypeId": eventTypeId,
        "rateCardItemId": rateCardItemId,
        "sessionDate": sessionDate,
        "sessionTime": sessionTime,
        "sessionEndTime": sessionEndTime,
        "locationType": locationType,
        "locationText": locationText,
        "useCreativeStudio": useCreativeStudio,
        if (numberOfOutfits != null) "numberOfOutfits": numberOfOutfits,
        if (numberOfShootingLocations != null)
          "numberOfShootingLocations": numberOfShootingLocations,
        if (deliverableType != null) "deliverableType": deliverableType,
        if (notes != null && notes.isNotEmpty) "notes": notes,
      }),
    );
    print(
      "📅 Create session response: ${response.statusCode} ${response.body}",
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        if (data is Map) return Map<String, dynamic>.from(data);
        return {'id': data};
      } catch (_) {
        return {};
      }
    }
    return null;
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

  /// PATCH /api/sessions/{id}/complete — creative marks the session complete
  /// (step 1 of payout release).
  Future<bool> completeSession({
    required String token,
    required String sessionId,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/sessions/$sessionId/complete'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200;
  }

  /// PATCH /api/sessions/{id}/confirm — client confirms satisfaction
  /// (step 2 of payout release).
  Future<bool> confirmSession({
    required String token,
    required String sessionId,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/sessions/$sessionId/confirm'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200;
  }

  /// PATCH /api/sessions/{id}/accept — creative accepts a booking.
  Future<bool> acceptSession({
    required String token,
    required String sessionId,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/sessions/$sessionId/accept'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200;
  }

  /// PATCH /api/sessions/{id}/decline — creative declines a booking.
  Future<bool> declineSession({
    required String token,
    required String sessionId,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/sessions/$sessionId/decline'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200;
  }

  /// PATCH /api/sessions/{id}/deliverables-sent — creative marks deliverables
  /// as sent.
  Future<bool> markDeliverablesSent({
    required String token,
    required String sessionId,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/sessions/$sessionId/deliverables-sent'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200;
  }

  /// PATCH /api/sessions/{id}/deliverables-confirm — client confirms
  /// deliverables received.
  Future<bool> confirmDeliverables({
    required String token,
    required String sessionId,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/sessions/$sessionId/deliverables-confirm'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200;
  }
}
