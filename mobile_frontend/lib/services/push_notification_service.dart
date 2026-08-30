import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Shared local-notifications plugin + Android channel, used to render styled
/// system-tray notifications (brand color/icon) for background + killed state.
final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

const String _channelId = 'photobook_notifications';
const String _channelName = 'PhotoBook notifications';
const String _channelDescription = 'Bookings, messages and calls';

/// Shows a styled system notification from a background isolate (app in
/// background or killed). Creates its own plugin instance + channel because
/// background isolates don't share the main isolate's plugin state.
Future<void> _showBackgroundNotification({
  required String title,
  required String body,
  required String payload,
}) async {
  final plugin = FlutterLocalNotificationsPlugin();
  const init = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
  );
  await plugin.initialize(settings: init);
  await plugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        enableLights: true,
        ledColor: Color(0xFFFF7A33),
      ));
  const androidDetails = AndroidNotificationDetails(
    _channelId,
    _channelName,
    channelDescription: _channelDescription,
    importance: Importance.high,
    priority: Priority.high,
    color: Color(0xFFFF7A33),
  );
  const iosDetails = DarwinNotificationDetails();
  const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
  await plugin.show(
    id: DateTime.now().millisecondsSinceEpoch % 2147483647,
    title: title,
    body: body,
    notificationDetails: details,
    payload: payload,
  );
}

/// Central wrapper around Firebase Cloud Messaging.
///
/// Responsibilities:
///  - Request notification permission (iOS/Android 13+).
///  - Obtain the FCM device token and register it with our backend.
///  - Keep the token in sync (onTokenRefresh).
///  - Deliver foreground messages to the UI (via [onForegroundMessage]).
///  - Handle notification taps (via [onNotificationTap]).
///  - Process background/terminated messages via [backgroundMessageHandler].
class PushNotificationService {
  static const _base = 'https://api.photobookhq.com/api';

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Invoked when a notification is received while the app is in the
  /// foreground. Return nothing — the UI decides how to surface it.
  void Function(RemoteMessage message)? onForegroundMessage;

  /// Invoked when the user taps a notification (or opens from terminated).
  void Function(RemoteMessage message)? onNotificationTap;

  /// Invoked when the user taps a locally-displayed notification (shown by
  /// [backgroundMessageHandler] via flutter_local_notifications). [payload] is
  /// the JSON-encoded message data used for deep-linking.
  void Function(String? payload)? onLocalNotificationTap;

  /// Static handler registered as a top-level entry point so messages can be
  /// processed even when the app is killed. Renders a styled system-tray
  /// notification (brand color/icon) for background + killed state.
  @pragma('vm:entry-point')
  static Future<void> backgroundMessageHandler(RemoteMessage message) async {
    // If the message carries a `notification` payload, FCM already renders a
    // system-tray notification on its own. Only render our styled one for
    // data-only messages, otherwise the user sees two notifications.
    if (message.notification != null) return;

    final title = message.data['title']?.toString() ?? 'PhotoBook';
    final body = message.data['body']?.toString() ?? '';
    await _showBackgroundNotification(
      title: title,
      body: body,
      payload: jsonEncode(message.data),
    );
  }

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// Initialize: permissions, token, and listeners.
  /// Returns the current FCM token (null if unavailable).
  Future<String?> init() async {
    // Set the background handler BEFORE any message can arrive.
    FirebaseMessaging.onBackgroundMessage(backgroundMessageHandler);

    // Initialize styled local notifications (brand color/icon) and wire the
    // tap handler for locally-displayed notifications.
    await _initLocalNotifications();

    // Request permission (iOS shows the system prompt; Android 13+ too).
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('📨 FCM permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      debugPrint('📨 FCM permission denied — push will not work.');
    }

    // Register token (also fired on first app run once permission granted).
    // On the iOS simulator APNs may not return a valid token, causing
    // getToken() to throw — treat it as non-fatal so the app doesn't crash.
    String? token;
    try {
      token = await _messaging.getToken();
      debugPrint('📨 FCM token: $token');
      if (token != null) {
        await registerToken(token);
      }
    } catch (e) {
      debugPrint('📨 FCM getToken failed (non-fatal): $e');
    }

    // Keep the backend token fresh if FCM rotates it.
    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('📨 FCM token refreshed');
      await registerToken(newToken);
    });

    // Foreground messages.
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint(
          '📨 [FCM foreground] ${message.notification?.title}: ${message.notification?.body}');
      onForegroundMessage?.call(message);
    });

    // User taps a notification while app is in background (not terminated).
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('📨 [FCM opened] ${message.notification?.title}');
      onNotificationTap?.call(message);
    });

    // User taps a notification that launched the app from terminated state.
    try {
      final initial = await _messaging.getInitialMessage();
      if (initial != null) {
        debugPrint('📨 [FCM initial] ${initial.notification?.title}');
        onNotificationTap?.call(initial);
      }
    } catch (e) {
      debugPrint('📨 getInitialMessage failed (non-fatal): $e');
    }

    return token;
  }

  Future<void> _initLocalNotifications() async {
    const init = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _localNotifications.initialize(
      settings: init,
      onDidReceiveNotificationResponse: (response) {
        onLocalNotificationTap?.call(response.payload);
      },
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
          enableLights: true,
          ledColor: Color(0xFFFF7A33),
        ));
  }

  /// POST the FCM token to the backend so it can target this device.
  ///
  /// Endpoint: POST /api/notifications/device-token
  /// Body: { "token": "<fcm token>", "platform": "ios" | "android" }
  Future<void> registerToken(String fcmToken) async {
    final token = await _token();
    if (token == null || token.isEmpty) {
      // Not logged in yet — skip; the token will be registered on login.
      debugPrint('📨 No auth token yet, skipping FCM registration.');
      return;
    }
    try {
      final platform = !kIsWeb && Platform.isIOS ? 'ios' : 'android';
      final res = await http.post(
        Uri.parse('$_base/notifications/device-token'),
        headers: _headers(token),
        body: jsonEncode({'token': fcmToken, 'platform': platform}),
      );
      debugPrint('📨 device-token → ${res.statusCode}');
    } catch (e) {
      // Non-fatal: the route may not exist yet on the backend.
      debugPrint('📨 registerToken error: $e');
    }
  }

  /// Fetch the current FCM token and register it (used right after login,
  /// when the auth token is freshly available).
  Future<void> registerCurrentToken() async {
    try {
      final fcmToken = await _messaging.getToken();
      if (fcmToken != null) {
        await registerToken(fcmToken);
      }
    } catch (e) {
      // Non-fatal: on iOS the APNs token may not be available yet (especially
      // on the simulator). onTokenRefresh re-registers once it arrives.
      debugPrint('📨 FCM getToken failed on login (non-fatal): $e');
    }
  }

  /// Clear the token on logout so the device stops receiving pushes.
  Future<void> unregisterToken() async {
    final token = await _token();
    if (token == null || token.isEmpty) return;
    try {
      final fcmToken = await _messaging.getToken();
      if (fcmToken == null) return;
      await http.delete(
        Uri.parse('$_base/notifications/device-token'),
        headers: _headers(token),
        body: jsonEncode({'token': fcmToken}),
      );
    } catch (e) {
      debugPrint('📨 unregisterToken error: $e');
    }
  }
}
