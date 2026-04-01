import 'package:flutter/material.dart';
import 'package:mobile_frontend/services/booking_service.dart';

class BookingSession {
  final String id;
  final String clientName;
  final String? clientAvatarUrl;
  final String status;
  final DateTime scheduledAt;
  final String? location;
  final String? notes;

  BookingSession({
    required this.id,
    required this.clientName,
    this.clientAvatarUrl,
    required this.status,
    required this.scheduledAt,
    this.location,
    this.notes,
  });

  bool get isUpcoming => scheduledAt.isAfter(DateTime.now());

  factory BookingSession.fromJson(Map<String, dynamic> json) {
    return BookingSession(
      id: json['id'] ?? '',
      clientName: json['client_name'] ?? json['clientName'] ?? 'Unknown Client',
      clientAvatarUrl: json['client_avatar_url'] ?? json['clientAvatarUrl'],
      status: json['status'] ?? 'pending',
      scheduledAt: DateTime.parse(json['scheduled_at'] ?? json['scheduledAt'] ?? DateTime.now().toIso8601String()),
      location: json['location'],
      notes: json['notes'],
    );
  }
}

class SessionsProvider extends ChangeNotifier {
  final _service = BookingService();
  List<BookingSession> _sessions = [];
  bool isLoading = false;

  List<BookingSession> get sessions => _sessions;
  List<BookingSession> get upcoming => _sessions.where((s) => s.isUpcoming).toList();
  List<BookingSession> get past => _sessions.where((s) => !s.isUpcoming).toList();

  Future<void> loadSessions({required String token}) async {
    isLoading = true;
    notifyListeners();
    try {
      final data = await _service.getMySessions(token: token);
      print("📅 Raw sessions: $data");
      _sessions = data.map((e) => BookingSession.fromJson(e)).toList();
      _sessions.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    } catch (e) {
      print("❌ Failed to load sessions: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}