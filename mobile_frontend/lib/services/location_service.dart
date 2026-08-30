import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static const _base = 'https://api.photobookhq.com/api';

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// PUT /api/locations — update your current live location
  Future<bool> updateLocation({
    required double latitude,
    required double longitude,
    double? accuracy,
    double? altitude,
    double? speed,
    double? heading,
  }) async {
    final token = await _token();
    if (token == null) return false;
    try {
      final res = await http.put(
        Uri.parse('$_base/locations'),
        headers: _headers(token),
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
          if (accuracy != null) 'accuracy': accuracy,
          if (altitude != null) 'altitude': altitude,
          if (speed != null) 'speed': speed,
          if (heading != null) 'heading': heading,
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('❌ updateLocation error: $e');
      return false;
    }
  }

  /// GET /api/locations/me
  Future<Map<String, dynamic>?> getMyLocation() async {
    final token = await _token();
    if (token == null) return null;
    try {
      final res = await http.get(
        Uri.parse('$_base/locations/me'),
        headers: _headers(token),
      );
      print('📍 getMyLocation — status=${res.statusCode}, body=${res.body}');
      if (res.statusCode == 200) return jsonDecode(res.body);
      return null;
    } catch (e) {
      print('❌ getMyLocation error: $e');
      return null;
    }
  }

  /// GET /api/locations/nearby — creatives near you
  Future<List<NearbyCreative>> getNearby() async {
    final token = await _token();
    if (token == null) return [];
    try {
      final res = await http.get(
        Uri.parse('$_base/locations/nearby'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data['locations'] as List? ?? [];
        return list.map((j) => NearbyCreative.fromJson(j)).toList();
      }
      return [];
    } catch (e) {
      print('❌ getNearby error: $e');
      return [];
    }
  }

  /// GET /api/locations/shares
  Future<Map<String, dynamic>?> getShares() async {
    final token = await _token();
    if (token == null) return null;
    try {
      final res = await http.get(
        Uri.parse('$_base/locations/shares'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
      return null;
    } catch (e) {
      print('❌ getShares error: $e');
      return null;
    }
  }

  /// POST /api/locations/share — share with a user
  Future<bool> shareWith(String targetUserId) async {
    final token = await _token();
    if (token == null) return false;
    try {
      final res = await http.post(
        Uri.parse('$_base/locations/share'),
        headers: _headers(token),
        body: jsonEncode({'targetUserId': targetUserId}),
      );
      return res.statusCode == 201;
    } catch (e) {
      print('❌ shareWith error: $e');
      return false;
    }
  }

  /// DELETE /api/locations/share/{userId}
  Future<bool> stopSharing(String userId) async {
    final token = await _token();
    if (token == null) return false;
    try {
      final res = await http.delete(
        Uri.parse('$_base/locations/share/$userId'),
        headers: _headers(token),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('❌ stopSharing error: $e');
      return false;
    }
  }

  /// GET /api/locations/{userId}
  Future<NearbyCreative?> getUserLocation(String userId) async {
    final token = await _token();
    if (token == null) return null;
    try {
      final res = await http.get(
        Uri.parse('$_base/locations/$userId'),
        headers: _headers(token),
      );
      print('📍 getUserLocation — status=${res.statusCode}, body=${res.body}');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['location'] != null) {
          return NearbyCreative.fromJson(data['location']);
        }
      }
      return null;
    } catch (e) {
      print('❌ getUserLocation error: $e');
      return null;
    }
  }
}

class NearbyCreative {
  final String userId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final double? heading;
  final DateTime? updatedAt;
  final String? name;
  final String? role;
  double? distanceKm; // set by the client after sorting

  NearbyCreative({
    required this.userId,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    this.heading,
    this.updatedAt,
    this.name,
    this.role,
    this.distanceKm,
  });

  factory NearbyCreative.fromJson(Map<String, dynamic> json) {
    return NearbyCreative(
      userId: json['user_id'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      name: json['name'],
      role: json['role'],
    );
  }
}
