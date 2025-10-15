import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfilePortfolioService {
  final String baseUrl = 'http://10.0.2.2:5000/api'; //"http://172.20.10.5:5000/api"; 

  /// 1️⃣ GET PROFILE (Client or Creative)

  Future<Map<String, dynamic>> getProfile(String userId, {String? token}) async {
    final headers = <String, String>{};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final response = await http.get(
      Uri.parse('$baseUrl/profiles/$userId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
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
    List<Map<String, dynamic>>? rateCard,
    List<String>? tags,
    List<String>? categories,
    String? location,
    String? phone,
  }) async {
    final body = <String, dynamic>{
      if (displayName != null) "displayName": displayName,
      if (businessName != null) "businessName": businessName,
      if (aboutMe != null) "aboutMe": aboutMe,
      if (rateCard != null) "rateCard": rateCard,
      if (tags != null) "tags": tags,
      if (categories != null) "categories": categories,
      if (location != null) "location": location,
      if (phone != null) "phone": phone,
    };

    final response = await http.put(
      Uri.parse('$baseUrl/profiles/creative'),
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
    String? displayName,
    String? businessName,
    String? location,
    String? phone,
  }) async {
    final body = <String, dynamic>{
      if (displayName != null) "displayName": displayName,
      if (businessName != null) "businessName": businessName,
      if (location != null) "location": location,
      if (phone != null) "phone": phone,
    };

    final response = await http.put(
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
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/profiles/avatar'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final response = await request.send();
    print("📥 Response status: ${response.statusCode}");
    final body = await response.stream.bytesToString();
    print("📥 Response body: $body");

    if (response.statusCode == 201) {
      final data = jsonDecode(body);
      return data['avatarUrl']; // returned { message, avatarUrl }
    } else {
      throw Exception('Avatar upload failed (${response.statusCode})');
    }
  }
  
  /// 5️⃣ UPLOAD PORTFOLIO ITEM (Creative only)
  
  Future<Map<String, dynamic>> uploadPortfolioItem({
    required String token,
    required String filePath,
    String? title,
    String? description,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/profiles/creative/portfolio'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    if (title != null) request.fields['title'] = title;
    if (description != null) request.fields['description'] = description;

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode == 201) {
      final data = jsonDecode(body);
      return data; // includes message + item
    } else {
      throw Exception('Portfolio upload failed (${response.statusCode})');
    }
  }

  /// 6️⃣ DELETE PORTFOLIO ITEM
  
  Future<bool> deletePortfolioItem({
    required String token,
    required String itemId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/profiles/creative/portfolio/$itemId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }
}
