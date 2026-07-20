import 'package:flutter/material.dart';
import 'package:mobile_frontend/services/booking_service.dart';
import 'package:mobile_frontend/services/profileservice.dart';

class BookingSession {
  final String id;
  final String clientId;
  final String clientName;
  final String? clientAvatarUrl;
  final String status;
  final DateTime scheduledAt;
  final String? location;
  final String? notes;

  BookingSession({
    required this.id,
    required this.clientId,
    required this.clientName,
    this.clientAvatarUrl,
    required this.status,
    required this.scheduledAt,
    this.location,
    this.notes,
  });

  bool get isUpcoming => scheduledAt.isAfter(DateTime.now());

  factory BookingSession.fromJson(Map<String, dynamic> json) {
    // ✅ Combine session_date + session_time into a DateTime
    DateTime scheduledAt;
    try {
      final date = json['session_date'] ?? json['scheduled_at'];
      final time = json['session_time'] ?? '00:00:00';
      final dateOnly = date.toString().split('T')[0]; // "2026-04-08"
      final timeOnly = time.toString().substring(0, 5); // "08:00"
      scheduledAt = DateTime.parse('${dateOnly}T${timeOnly}:00');
    } catch (_) {
      scheduledAt = DateTime.now();
    }

    return BookingSession(
      id: json['id'] ?? '',
      clientId: json['client_id'] ?? '',
      clientName: json['client_name'] ?? json['clientName'] ?? 'Loading...',
      clientAvatarUrl: json['client_avatar_url'] ?? json['clientAvatarUrl'],
      status: json['status'] ?? 'pending',
      scheduledAt: scheduledAt, // ✅
      location:
          json['location_text'] ?? json['location'], // ✅ was just 'location'
      notes: json['event_type_name'], // ✅ repurpose notes to show event type
    );
  }
}

class SessionsProvider extends ChangeNotifier {
  final _service = BookingService();
  List<BookingSession> _sessions = [];
  bool isLoading = false;

  List<BookingSession> get sessions => _sessions;
  List<BookingSession> get upcoming =>
      _sessions.where((s) => s.isUpcoming).toList();
  List<BookingSession> get past =>
      _sessions.where((s) => !s.isUpcoming).toList();

  Future<void> loadSessions({required String token}) async {
    isLoading = true;
    notifyListeners();
    try {
      final data = await _service.getMySessions(token: token);
      _sessions = data.map((e) => BookingSession.fromJson(e)).toList();
      _sessions.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
      notifyListeners(); // ✅ show sessions immediately while names load

      // ✅ Fetch client names in parallel
      final enriched = await Future.wait(
        _sessions.map((session) async {
          if (session.clientId.isEmpty) return session;
          try {
            final profile = await ProfilePortfolioService().getProfile(
              token: token,
              userId: session.clientId,
            );
            final raw = profile['profile'] ?? profile;
            final name = raw['name'] ?? raw['full_name'] ?? session.clientName;
            return BookingSession(
              id: session.id,
              clientId: session.clientId,
              clientName: name,
              clientAvatarUrl:
                  raw['client_profile_photo_url'] ??
                  raw['photographer_profile_photo_url'],
              status: session.status,
              scheduledAt: session.scheduledAt,
              location: session.location,
              notes: session.notes,
            );
          } catch (_) {
            return session; // fallback to original if fetch fails
          }
        }),
      );

      _sessions = enriched;
    } catch (e) {
      print("❌ Failed to load sessions: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
