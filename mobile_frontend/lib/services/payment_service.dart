import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentService {
  final String baseUrl = 'https://api.photobookhq.com/api';

  /// POST /api/payments/initiate — start an escrow payment for a session.
  /// Returns { paystackAuthorizationUrl, reference }.
  Future<Map<String, dynamic>?> initiatePayment({
    required String token,
    required String sessionId,
    required double amount,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/payments/initiate'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'sessionId': sessionId, 'amount': amount}),
    );
    print('💳 initiate [${res.statusCode}]: ${res.body}');
    if (res.statusCode == 200 || res.statusCode == 201) {
      return Map<String, dynamic>.from(jsonDecode(res.body));
    }
    return null;
  }

  /// GET /api/payments/verify/{reference} — check payment status after redirect.
  Future<Map<String, dynamic>?> verifyPayment({
    required String token,
    required String reference,
  }) async {
    final res = await http.get(
      Uri.parse('$baseUrl/payments/verify/$reference'),
      headers: {'Authorization': 'Bearer $token'},
    );
    print('💳 verify [${res.statusCode}]: ${res.body}');
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(res.body));
    }
    return null;
  }
}
