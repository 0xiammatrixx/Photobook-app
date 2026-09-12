import 'dart:convert';
import 'package:http/http.dart' as http;

/// True when a payment-verify response indicates the payment went through.
/// Handles the common Paystack/backend shapes: `status`, `payment_status`,
/// and nested `data.status` / `transaction.status`.
bool isPaymentConfirmed(Map<String, dynamic>? verify) {
  if (verify == null) return false;

  bool ok(Object? value) {
    if (value == null) return false;
    final v = value.toString().toLowerCase();
    return v == 'confirmed' ||
        v == 'success' ||
        v == 'successful' ||
        v == 'paid';
  }

  if (ok(verify['status'])) return true;
  if (ok(verify['payment_status'])) return true;

  for (final key in ['data', 'transaction', 'payment']) {
    final nested = verify[key];
    if (nested is Map) {
      if (ok(nested['status'])) return true;
      if (ok(nested['payment_status'])) return true;
    }
  }
  return false;
}

class PaymentService {
  final String baseUrl = 'https://api.photobookhq.com/api';

  /// POST /api/payments/initiate — start an escrow payment for a session.
  /// Returns { paystackAuthorizationUrl, reference }.
  ///
  /// [callbackUrl] is forwarded to the backend so Paystack redirects back to
  /// the app (a `photobook://` deep link) after payment instead of hitting an
  /// API endpoint that rejects unauthenticated browser redirects with
  /// `{"message":"No token"}`.
  Future<Map<String, dynamic>?> initiatePayment({
    required String token,
    required String sessionId,
    required double amount,
    String? callbackUrl,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/payments/initiate'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'sessionId': sessionId,
        'amount': amount,
        if (callbackUrl != null && callbackUrl.isNotEmpty) ...{
          // Send both spellings — the backend forwards this to Paystack and
          // may expect either the JS-style or the Paystack canonical key.
          'callbackUrl': callbackUrl,
          'callback_url': callbackUrl,
        },
      }),
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
