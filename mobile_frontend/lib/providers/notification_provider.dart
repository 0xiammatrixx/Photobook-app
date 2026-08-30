import 'package:flutter/material.dart';
import 'package:mobile_frontend/services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => _notifications;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Load notifications on first open.
  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    final res = await _service.getNotifications();
    _notifications = res.notifications;
    _unreadCount = res.unreadCount;
    _isLoading = false;
    notifyListeners();
  }

  /// Mark a single notification as read.
  Future<void> markRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1 && !_notifications[idx].read) {
      _notifications[idx] = AppNotification(
        id: _notifications[idx].id,
        type: _notifications[idx].type,
        title: _notifications[idx].title,
        body: _notifications[idx].body,
        data: _notifications[idx].data,
        read: true,
        createdAt: _notifications[idx].createdAt,
      );
      _unreadCount = (_unreadCount - 1).clamp(0, 999);
      notifyListeners();
    }
    await _service.markRead([id]);
  }

  /// Mark all as read.
  Future<void> markAllRead() async {
    for (var i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].read) {
        _notifications[i] = AppNotification(
          id: _notifications[i].id,
          type: _notifications[i].type,
          title: _notifications[i].title,
          body: _notifications[i].body,
          data: _notifications[i].data,
          read: true,
          createdAt: _notifications[i].createdAt,
        );
      }
    }
    _unreadCount = 0;
    notifyListeners();
    await _service.markAllRead();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
