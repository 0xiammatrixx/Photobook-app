import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_frontend/features/shared/offer.dart';

/// This should be the SAME base URL ProfilePortfolioService uses — including
/// the trailing /api, e.g. "https://your-api.example.com/api". The paths
/// below only append "/offers...", not "/api/offers...".
const String _baseUrl = 'https://api.photobookhq.com/api';

class OfferService {
  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// POST /api/offers
  Future<Offer> createOffer({
    required String token,
    required String sentTo,
    required String serviceName,
    required num pricingAmount,
    required String pricingMode, // 'fixed' | 'contact'
    String currencyCode = 'NGN',
    String? description,
    List<String> categories = const [],
    List<String> whatsIncluded = const [],
    String? deliveryTime,
    String? quantityLabel,
    int? quantityMax,
    String? sessionDate,
    String? sessionTime,
    String? locationType,
    String? locationText,
  }) async {
    final body = {
      'sentTo': sentTo,
      'serviceName': serviceName,
      'pricingAmount': pricingAmount,
      'pricingMode': pricingMode,
      'currencyCode': currencyCode,
      if (description != null && description.isNotEmpty)
        'description': description,
      if (categories.isNotEmpty) 'categories': categories,
      if (whatsIncluded.isNotEmpty) 'whatsIncluded': whatsIncluded,
      if (deliveryTime != null) 'deliveryTime': deliveryTime,
      if (quantityLabel != null) 'quantityLabel': quantityLabel,
      if (quantityMax != null) 'quantityMax': quantityMax,
      if (sessionDate != null) 'sessionDate': sessionDate,
      if (sessionTime != null) 'sessionTime': sessionTime,
      if (locationType != null) 'locationType': locationType,
      if (locationText != null) 'locationText': locationText,
    };

    final res = await http.post(
      Uri.parse('$_baseUrl/offers'),
      headers: _headers(token),
      body: jsonEncode(body),
    );

    if (res.statusCode == 201) {
      // ignore: avoid_print
      print('OfferService create response: ${res.body}');
      final data = jsonDecode(res.body);
      // Some endpoints (like /accept) wrap the offer as {"offer": {...}}.
      // Be tolerant of both shapes instead of assuming a flat object.
      final offerJson = (data is Map && data['offer'] is Map)
          ? data['offer'] as Map<String, dynamic>
          : data as Map<String, dynamic>;
      return Offer.fromJson(offerJson);
    }
    throw Exception(_extractError(res, 'Failed to send offer'));
  }

  /// GET /api/offers -> { sent: [...], received: [...] }
  Future<Map<String, List<Offer>>> getOffers({required String token}) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/offers'),
      headers: _headers(token),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return {
        'sent': (data['sent'] as List? ?? [])
            .map((e) => Offer.fromJson(e))
            .toList(),
        'received': (data['received'] as List? ?? [])
            .map((e) => Offer.fromJson(e))
            .toList(),
      };
    }
    throw Exception(_extractError(res, 'Failed to load offers'));
  }

  /// PATCH /api/offers/{id}/accept -> books a session
  Future<Map<String, dynamic>> acceptOffer({
    required String token,
    required String id,
  }) async {
    final res = await http.patch(
      Uri.parse('$_baseUrl/offers/$id/accept'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception(_extractError(res, 'Failed to accept offer'));
  }

  /// PATCH /api/offers/{id}/decline
  Future<void> declineOffer({
    required String token,
    required String id,
  }) async {
    final res = await http.patch(
      Uri.parse('$_baseUrl/offers/$id/decline'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) {
      throw Exception(_extractError(res, 'Failed to decline offer'));
    }
  }

  /// PATCH /api/offers/{id}/cancel
  Future<void> cancelOffer({
    required String token,
    required String id,
  }) async {
    final res = await http.patch(
      Uri.parse('$_baseUrl/offers/$id/cancel'),
      headers: _headers(token),
    );
    if (res.statusCode != 200) {
      throw Exception(_extractError(res, 'Failed to cancel offer'));
    }
  }

  String _extractError(http.Response res, String fallback) {
    // ignore: avoid_print
    print('OfferService error ${res.statusCode}: ${res.body}');
    try {
      final data = jsonDecode(res.body);
      final msg = data['message'] ?? data['error'];
      if (msg != null) return '$msg (${res.statusCode})';
    } catch (_) {
      // response wasn't JSON — fall through
    }
    return '$fallback (${res.statusCode}): ${res.body}';
  }
}