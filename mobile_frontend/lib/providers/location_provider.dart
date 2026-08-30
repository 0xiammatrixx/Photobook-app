import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_frontend/services/location_service.dart';

class LocationProvider extends ChangeNotifier {
  final LocationService _service = LocationService();

  List<NearbyCreative> _nearbyCreatives = [];
  List<NearbyCreative> get nearbyCreatives => _nearbyCreatives;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _currentCity;
  String? get currentCity => _currentCity;

  /// Client's own position, set by loadNearby.
  double? clientLat;
  double? clientLng;

  Timer? _updateTimer;
  bool _emitting = false;

  /// Load nearby creatives for clients.
  Future<void> loadNearby({required double lat, required double lng}) async {
    clientLat = lat;
    clientLng = lng;
    _isLoading = true;
    notifyListeners();

    try {
      final list = await _service.getNearby();
      for (final c in list) {
        c.distanceKm = _haversine(lat, lng, c.latitude, c.longitude);
      }
      list.sort((a, b) => (a.distanceKm ?? double.infinity)
          .compareTo(b.distanceKm ?? double.infinity));
      _nearbyCreatives = list;
    } catch (e) {
      print('❌ loadNearby error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Start periodically emitting location (for creatives).
  /// Call once when creative logs in. Stops when disposed or explicitly stopped.
  void startEmitting({Duration interval = const Duration(minutes: 3)}) {
    if (_emitting) return;
    _emitting = true;
    _pushLocation(); // fire first emission immediately (fire-and-forget is fine,
    // the profile page will retry with a delay if needed)
    _updateTimer = Timer.periodic(interval, (_) => _pushLocation());
  }

  void stopEmitting() {
    _emitting = false;
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  Future<void> _pushLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _service.updateLocation(
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracy: pos.accuracy,
        altitude: pos.altitude,
        speed: pos.speed,
        heading: pos.heading,
      );
      print('📍 Location emitted: ${pos.latitude}, ${pos.longitude}');
    } catch (e) {
      print('❌ _pushLocation error: $e');
    }
  }

  /// Reverse-geocode using Nominatim (free OpenStreetMap API).
  Future<void> resolveCityName(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=$lat&lon=$lng&format=json&zoom=10',
      );
      final res = await http.get(uri, headers: {
        'User-Agent': 'PhotoBookApp/1.0',
        'Accept-Language': 'en',
      });
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          _currentCity = address['city'] ??
              address['town'] ??
              address['state'] ??
              address['country'];
          notifyListeners();
        }
      }
    } catch (e) {
      print('❌ resolveCityName error: $e');
    }
  }

  /// Share location with another user.
  Future<bool> shareWith(String userId) => _service.shareWith(userId);

  /// Stop sharing with a user.
  Future<bool> stopSharing(String userId) => _service.stopSharing(userId);

  /// Static helper — resolve city name from coordinates.
  /// Usable without a provider instance (e.g. from profile pages).
  static Future<String?> cityFromCoords(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=$lat&lon=$lng&format=json&zoom=10',
      );
      final res = await http.get(uri, headers: {
        'User-Agent': 'PhotoBookApp/1.0',
        'Accept-Language': 'en',
      });
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          return (address['city'] ??
                  address['town'] ??
                  address['state'] ??
                  address['country'])
              ?.toString();
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  void dispose() {
    stopEmitting();
    super.dispose();
  }

  // ── Haversine formula ──
  static double _haversine(
    double lat1, double lng1, double lat2, double lng2,
  ) {
    const R = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) *
            sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _toRad(double deg) => deg * pi / 180;
}
