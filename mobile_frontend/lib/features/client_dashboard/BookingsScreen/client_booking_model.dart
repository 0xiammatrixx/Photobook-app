import 'package:flutter/material.dart';

const bookingOrange = Color(0xFFFF7A33);
const bookingGreen = Color(0xFF047418);

/// A booking as seen from the client's side.
class ClientBooking {
  final String id;
  final String creativeId;
  final String creativeName;
  final String? creativeAvatarUrl;
  final String? serviceType;
  final DateTime scheduledAt;
  final String status;
  final double? price;
  final String? location;
  final int? durationMinutes;

  ClientBooking({
    required this.id,
    required this.creativeId,
    required this.creativeName,
    this.creativeAvatarUrl,
    this.serviceType,
    required this.scheduledAt,
    required this.status,
    this.price,
    this.location,
    this.durationMinutes,
  });

  bool get isCancelled {
    final s = status.toLowerCase();
    return s.contains('cancel') || s.contains('decline');
  }

  /// How long after the session's scheduled end we wait for the client to
  /// confirm before the booking is automatically marked completed.
  static const confirmationWindow = Duration(hours: 48);

  /// Fallback session length used when the payload has no duration.
  static const _defaultSessionMinutes = 120;

  /// When the booking was agreed to end (start + estimated duration).
  DateTime get sessionEnd => scheduledAt.add(
    Duration(minutes: durationMinutes ?? _defaultSessionMinutes),
  );

  bool get isCompleted {
    final s = status.toLowerCase();
    if (s.contains('complete') || s.contains('deliver') || s == 'done') {
      return true;
    }
    // Session ended and the confirmation window elapsed — auto-complete
    // even if the backend status was never updated.
    return DateTime.now().isAfter(sessionEnd.add(confirmationWindow));
  }

  /// Session has ended but we're still inside the confirmation window.
  bool get isAwaitingConfirmation =>
      !isCancelled && !isCompleted && DateTime.now().isAfter(sessionEnd);

  /// Only bookings whose scheduled end is still in the future.
  bool get isUpcoming =>
      !isCancelled && !isCompleted && !isAwaitingConfirmation;

  /// True when the session was created but payment hasn't completed yet.
  /// Such sessions would otherwise be stuck in "pending" with no way to
  /// retry/pay — surface a Pay Now action on the detail screen.
  bool get isAwaitingPayment {
    if (isCancelled || isCompleted) return false;
    final s = status.toLowerCase();
    return s == 'pending' ||
        s == 'created' ||
        s == 'unpaid' ||
        s.contains('awaiting_payment') ||
        s.contains('payment_pending') ||
        s.contains('awaiting payment');
  }

  bool get sessionHasPassed => sessionEnd.isBefore(DateTime.now());

  String get dateLabel {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[scheduledAt.month - 1]} ${scheduledAt.day}, ${scheduledAt.year}';
  }

  String get timeLabel {
    final h = scheduledAt.hour;
    final m = scheduledAt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h % 12 == 0 ? 12 : h % 12;
    return '$hour12:$m $period';
  }

  String get durationLabel {
    final mins = durationMinutes;
    if (mins == null || mins <= 0) return '';
    if (mins % 60 == 0) return '${mins ~/ 60} hours';
    return '$mins mins';
  }

  String get priceLabel => formatNaira(price);

  /// True when the session payload didn't include the creative's real
  /// name/avatar (common on older bookings) and a profile fetch is needed.
  bool get needsCreativeInfo =>
      creativeName.isEmpty ||
      creativeName == 'Creative' ||
      creativeAvatarUrl == null ||
      creativeAvatarUrl!.isEmpty;

  ClientBooking copyWith({String? creativeName, String? creativeAvatarUrl}) {
    return ClientBooking(
      id: id,
      creativeId: creativeId,
      creativeName: creativeName ?? this.creativeName,
      creativeAvatarUrl: creativeAvatarUrl ?? this.creativeAvatarUrl,
      serviceType: serviceType,
      scheduledAt: scheduledAt,
      status: status,
      price: price,
      location: location,
      durationMinutes: durationMinutes,
    );
  }

  factory ClientBooking.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? asMap(dynamic v) =>
        v is Map<String, dynamic> ? v : null;

    final photographer =
        asMap(json['photographer']) ?? asMap(json['creative']) ?? json;

    // Scheduled date/time
    DateTime scheduledAt;
    try {
      final date = json['session_date'] ?? json['scheduled_at'];
      final time = json['session_time'] ?? '00:00';
      final dateOnly = date.toString().split('T')[0];
      final timeOnly = time.toString().trim();
      scheduledAt = DateTime.parse('${dateOnly}T'
          '${timeOnly.padLeft(5, '0').substring(0, 5)}:00');
    } catch (_) {
      scheduledAt = DateTime.now();
    }

    double? price;
    for (final key in [
      'price', 'amount', 'total_price', 'total_amount', 'pricing_amount',
      'agreed_amount',
    ]) {
      final v = double.tryParse((json[key] ?? '').toString());
      if (v != null) {
        price = v;
        break;
      }
    }

    int? duration;
    for (final key in [
      'estimated_duration_minutes', 'duration_minutes', 'duration',
    ]) {
      final v = int.tryParse((json[key] ?? '').toString());
      if (v != null && v > 0) {
        duration = v;
        break;
      }
    }

    return ClientBooking(
      id: json['id']?.toString() ?? '',
      creativeId:
          (json['photographer_id'] ?? json['creative_id'] ?? '')?.toString() ??
          '',
      creativeName:
          (photographer['business_name'] ??
                  photographer['businessName'] ??
                  photographer['name'] ??
                  json['photographer_name'] ??
                  json['creative_name'] ??
                  json['business_name'] ??
                  'Creative')
              .toString(),
      creativeAvatarUrl:
          (photographer['profile_photo_url'] ??
                  photographer['avatar_url'] ??
                  json['photographer_avatar_url'] ??
                  json['creative_avatar_url'])
              ?.toString(),
      serviceType:
          (json['event_type_name'] ??
                  json['package_type'] ??
                  json['packageType'] ??
                  json['service_type'])
              ?.toString(),
      scheduledAt: scheduledAt,
      status: json['status']?.toString() ?? 'pending',
      price: price,
      location:
          (json['location_text'] ?? json['location'])?.toString(),
      durationMinutes: duration,
    );
  }
}

/// ₦450000 → ₦450K, ₦1500000 → ₦1.5M
/// Formats naira amounts with K/M suffixes (₦450000 → ₦450K).
String formatNaira(double? amount) {
  if (amount == null) return '₦—';
  if (amount >= 1000000) {
    final m = amount / 1000000;
    return '₦${m.toStringAsFixed(m >= 10 ? 0 : 1)}M';
  }
  if (amount >= 1000) {
    return '₦${(amount / 1000).toStringAsFixed(0)}K';
  }
  return '₦${amount.toStringAsFixed(0)}';
}
