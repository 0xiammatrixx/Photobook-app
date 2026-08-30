import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static const _base = 'https://api.photobookhq.com/api';

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// GET /api/notifications?limit=&offset=&unread=
  Future<NotificationsResponse> getNotifications({
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    final token = await _token();
    if (token == null) return NotificationsResponse(notifications: [], total: 0);

    try {
      final uri = Uri.parse('$_base/notifications').replace(queryParameters: {
        'limit': limit.toString(),
        'offset': offset.toString(),
        if (unreadOnly) 'unread': 'true',
      });
      final res = await http.get(uri, headers: _headers(token));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['notifications'] as List? ?? [])
            .map((j) => AppNotification.fromJson(j))
            .toList();
        return NotificationsResponse(
          notifications: list,
          total: data['total'] ?? list.length,
          unreadCount: data['unreadCount'] ?? 0,
        );
      }
      return NotificationsResponse(notifications: [], total: 0);
    } catch (e) {
      print('❌ getNotifications error: $e');
      return NotificationsResponse(notifications: [], total: 0);
    }
  }

  /// PATCH /api/notifications/read
  Future<bool> markRead(List<String> ids) async {
    final token = await _token();
    if (token == null) return false;
    try {
      final res = await http.patch(
        Uri.parse('$_base/notifications/read'),
        headers: _headers(token),
        body: jsonEncode({'ids': ids}),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('❌ markRead error: $e');
      return false;
    }
  }

  /// PATCH /api/notifications/read-all
  Future<bool> markAllRead() async {
    final token = await _token();
    if (token == null) return false;
    try {
      final res = await http.patch(
        Uri.parse('$_base/notifications/read-all'),
        headers: _headers(token),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('❌ markAllRead error: $e');
      return false;
    }
  }
}

class AppNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool read;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? json['message'] ?? '',
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data']) : null,
      read: json['read'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  IconData get icon {
    switch (type) {
      case 'incoming_call':
      case 'call':
        return Icons.call;
      case 'booking_confirmed':
      case 'payment_success':
        return Icons.check_circle_outline;
      case 'new_message':
        return Icons.chat_bubble_outline;
      case 'offer_received':
      case 'offer_updated':
        return Icons.local_offer_outlined;
      case 'booking_reminder':
        return Icons.alarm;
      case 'booking_cancelled':
        return Icons.cancel_outlined;
      case 'review_request':
        return Icons.star_outline;
      case 'refund':
        return Icons.account_balance_wallet_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color get color {
    switch (type) {
      case 'incoming_call':
      case 'call':
        return const Color(0xFF047418);
      case 'booking_confirmed':
      case 'payment_success':
      case 'refund':
        return const Color(0xFF047418);
      case 'new_message':
      case 'offer_received':
      case 'offer_updated':
      case 'booking_reminder':
        return const Color(0xFFFF7A33);
      case 'review_request':
        return Colors.orange;
      case 'booking_cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class NotificationsResponse {
  final List<AppNotification> notifications;
  final int total;
  final int unreadCount;

  NotificationsResponse({
    required this.notifications,
    this.total = 0,
    this.unreadCount = 0,
  });
}
