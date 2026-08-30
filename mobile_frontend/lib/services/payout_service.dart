import 'dart:convert';
import 'package:http/http.dart' as http;

class PayoutService {
  final String baseUrl = 'https://api.photobookhq.com/api';

  /// GET /api/payouts/banks — Nigerian banks for payouts.
  Future<List<Map<String, dynamic>>> getBanks({required String token}) async {
    final res = await http.get(
      Uri.parse('$baseUrl/payouts/banks'),
      headers: {'Authorization': 'Bearer $token'},
    );
    print('🏦 Banks [${res.statusCode}]');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final banks = data['banks'] ?? data;
      if (banks is List) return List<Map<String, dynamic>>.from(banks);
    }
    return [];
  }

  /// POST /api/payouts/verify-account — resolve account number to owner name.
  Future<String?> verifyAccount({
    required String token,
    required String accountNumber,
    required String bankCode,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/payouts/verify-account'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'accountNumber': accountNumber, 'bankCode': bankCode}),
    );
    print('🏦 verify-account [${res.statusCode}]: ${res.body}');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final name = data['accountName'] ??
          data['account_name'] ??
          data['data']?['accountName'];
      return name?.toString();
    }
    return null;
  }

  /// POST /api/payouts/bank-account — save account (creates Paystack recipient).
  Future<({bool success, String message})> saveBankAccount({
    required String token,
    required String bankCode,
    required String accountNumber,
    required String accountName,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/payouts/bank-account'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'bankCode': bankCode,
        'accountNumber': accountNumber,
        'accountName': accountName,
      }),
    );
    print('🏦 save bank-account [${res.statusCode}]: ${res.body}');
    if (res.statusCode == 200 || res.statusCode == 201) {
      return (success: true, message: 'Bank account saved');
    }
    String message = 'Failed to save bank account';
    try {
      final data = jsonDecode(res.body);
      message = data['message']?.toString() ?? message;
    } catch (_) {}
    return (success: false, message: message);
  }

  /// GET /api/payouts/bank-account — saved account (masked).
  Future<Map<String, dynamic>?> getBankAccount({required String token}) async {
    final res = await http.get(
      Uri.parse('$baseUrl/payouts/bank-account'),
      headers: {'Authorization': 'Bearer $token'},
    );
    print('🏦 get bank-account [${res.statusCode}]');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final account = data['account'] ?? data;
      if (account is Map) return Map<String, dynamic>.from(account);
    }
    return null;
  }

  /// DELETE /api/payouts/bank-account — remove saved account.
  Future<bool> deleteBankAccount({required String token}) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/payouts/bank-account'),
      headers: {'Authorization': 'Bearer $token'},
    );
    print('🏦 delete bank-account [${res.statusCode}]');
    return res.statusCode == 200;
  }
}
