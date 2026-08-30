import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

class ProfilePortfolioService {
  final String baseUrl =
      'https://api.photobookhq.com/api'; //"http://172.20.10.5:5000/api";

  /// 1️⃣ GET PROFILE (Client or Creative)

  Future<Map<String, dynamic>> getProfile({
    required String token,
    String? userId,
  }) async {
    final endpoint = userId != null
        ? '$baseUrl/profiles/$userId' // public view of another user
        : '$baseUrl/profiles/me'; // own profile

    final response = await http.get(
      Uri.parse(endpoint),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('UNAUTHORIZED'); // ✅ specific signal
    } else {
      throw Exception('Failed to load profile (${response.statusCode})');
    }
  }

  /// 2️⃣ UPDATE CREATIVE PROFILE
  Future<bool> updateCreativeProfile({
    required String token,
    String? displayName,
    String? businessName,
    String? aboutMe,
    List<String>? tags,
    String? profilePhotoUrl,
  }) async {
    final body = <String, dynamic>{
      if (displayName != null) "displayTitle": displayName,
      if (businessName != null) "businessName": businessName,
      if (aboutMe != null) "about": aboutMe,
      if (tags != null) "tags": tags,
      if (profilePhotoUrl != null) "profilePhotoUrl": profilePhotoUrl,
    };

    final response = await http.patch(
      Uri.parse('$baseUrl/profiles/photographer'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    return response.statusCode == 200;
  }

  /// 3️⃣ UPDATE CLIENT PROFILE

  Future<bool> updateClientProfile({
    required String token,
    String? location,
    String? profilePhotoUrl,
  }) async {
    final body = <String, dynamic>{
      if (profilePhotoUrl != null) "profilePhotoUrl": profilePhotoUrl,
      if (location != null) "location": location,
    };

    final response = await http.patch(
      Uri.parse('$baseUrl/profiles/client'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    return response.statusCode == 200;
  }

  /// 4️⃣ UPLOAD AVATAR (Both Client & Creative)

  Future<String> uploadAvatar({
    required String token,
    required String filePath,
  }) async {
    print("📤 Uploading avatar to: $baseUrl/profiles/avatar");
    print("🔑 Token: $token");
    print("📁 File path: $filePath");
    final mimeType = lookupMimeType(filePath) ?? 'image/jpeg';
    final mimeParts = mimeType.split('/');
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/profiles/avatar'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        filePath,
        contentType: MediaType(mimeParts[0], mimeParts[1]), // ✅
      ),
    );

    final response = await request.send();
    print("📥 Response status: ${response.statusCode}");
    final body = await response.stream.bytesToString();
    print("📥 Response body: $body");

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(body);
      return data['avatarUrl'] ?? data['avatar_url'] ?? data['url'];
    } else {
      throw Exception('Avatar upload failed (${response.statusCode}): $body');
    }
  }

  /// 5️⃣ UPLOAD PORTFOLIO ITEM (Creative only)

  Future<Map<String, dynamic>> uploadPortfolioItem({
    required String token,
    required String filePath,
    String? title,
    String? description,
    String? tags,
    bool isCover = false,
    int? durationSeconds,
  }) async {
    final mimeType = lookupMimeType(filePath) ?? 'image/jpeg';
    final mimeParts = mimeType.split('/');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/portfolio/upload'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        filePath,
        contentType: MediaType(mimeParts[0], mimeParts[1]),
      ),
    );
    if (title != null) request.fields['title'] = title;
    if (description != null) request.fields['description'] = description;
    if (tags != null) request.fields['tags'] = tags;
    request.fields['isCover'] = isCover.toString();
    if (durationSeconds != null) {
      request.fields['durationSeconds'] = durationSeconds.toString(); // ✅
    }

    final response = await request.send();
    final body = await response.stream.bytesToString();
    print("📤 Portfolio upload response: ${response.statusCode} $body");

    if (response.statusCode == 201) {
      final data = jsonDecode(body);
      print("✅ Portfolio item uploaded: $data"); // 👈 shows exact field names
      return data;
    } else {
      throw Exception(
        'Portfolio upload failed (${response.statusCode}): $body',
      );
    }
  }

  Future<List<dynamic>> getMyPortfolio({required String token}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/portfolio/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final raw = data is List
          ? data
          : data['items'] ?? data['portfolio'] ?? [];

      // ✅ Remap field names to what the UI expects
      return (raw as List)
          .map(
            (item) => {
              ...Map<String, dynamic>.from(item),
              'url': item['media_url'],
              'type': item['media_type'], // "image" or "video"
            },
          )
          .toList();
    }
    throw Exception('Failed to load portfolio (${response.statusCode})');
  }

  /// 6️⃣ DELETE PORTFOLIO ITEM

  Future<bool> deletePortfolioItem({
    required String token,
    required String itemId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/portfolio/$itemId'), // ✅ new URL
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200;
  }

  Future<bool> addRateCardItem({
    required String token,
    required String serviceName,
    required String quantityLabel,
    int? quantityMax,
    required String pricingMode,
    double? pricingAmount,
    String currencyCode = "NGN",
    int? sortOrder,
    String? description, // ✅ add
    List<String>? categories, // ✅ add
    List<String>? whatsIncluded, // ✅ add
    String? deliveryTime, // ✅ add
  }) async {
    final body = <String, dynamic>{
      "serviceName": serviceName,
      "quantityLabel": quantityLabel,
      if (quantityMax != null) "quantityMax": quantityMax,
      "pricingMode": pricingMode,
      if (pricingAmount != null) "pricingAmount": pricingAmount,
      "currencyCode": currencyCode,
      if (sortOrder != null) "sortOrder": sortOrder,
      if (description != null) "description": description, // ✅
      if (categories != null) "categories": categories, // ✅
      if (whatsIncluded != null) "whatsIncluded": whatsIncluded, // ✅
      if (deliveryTime != null) "deliveryTime": deliveryTime, // ✅
    };

    final response = await http.post(
      Uri.parse('$baseUrl/rate-card'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    return response.statusCode == 201;
  }

  // Your own rate card (requires photographer token)
  Future<List<dynamic>> getMyRateCard({required String token}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/rate-card/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("📦 Raw rate card response: $data");
      // Handle both shapes
      if (data is List) return data;
      if (data is Map) {
        // Try common wrapper keys
        return data['items'] ?? data['rateCard'] ?? data['data'] ?? [];
      }
      return [];
    } else {
      throw Exception('Failed to load rate card (${response.statusCode})');
    }
  }

  // Public rate card for any photographer (no token needed)
  Future<List<dynamic>> getPhotographerRateCard(String photographerId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/rate-card/$photographerId'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return data;
      if (data is Map) {
        return data['items'] ?? data['rateCard'] ?? data['data'] ?? [];
      }
      return [];
    } else {
      throw Exception('Failed to load rate card (${response.statusCode})');
    }
  }

  Future<bool> updateRateCardItem({
    required String token,
    required String itemId,
    String? serviceName,
    String? quantityLabel,
    int? quantityMax,
    String? pricingMode,
    double? pricingAmount,
    String? currencyCode,
    int? sortOrder,
    String? description, // ✅ add
    List<String>? categories, // ✅ add
    List<String>? whatsIncluded, // ✅ add
    String? deliveryTime, // ✅ add
  }) async {
    final body = <String, dynamic>{
      if (serviceName != null) "serviceName": serviceName,
      if (quantityLabel != null) "quantityLabel": quantityLabel,
      if (quantityMax != null) "quantityMax": quantityMax,
      if (pricingMode != null) "pricingMode": pricingMode,
      if (pricingAmount != null) "pricingAmount": pricingAmount,
      if (currencyCode != null) "currencyCode": currencyCode,
      if (sortOrder != null) "sortOrder": sortOrder,
      if (description != null) "description": description, // ✅
      if (categories != null) "categories": categories, // ✅
      if (whatsIncluded != null) "whatsIncluded": whatsIncluded, // ✅
      if (deliveryTime != null) "deliveryTime": deliveryTime, // ✅
    };

    final response = await http.patch(
      Uri.parse('$baseUrl/rate-card/items/$itemId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    return response.statusCode == 200;
  }

  Future<bool> deleteRateCardItem({
    required String token,
    required String itemId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/rate-card/items/$itemId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }
}
