import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_frontend/providers/call_provider.dart';
import 'package:mobile_frontend/providers/chat_provider.dart';
import 'package:mobile_frontend/providers/location_provider.dart';
import 'package:mobile_frontend/providers/notification_provider.dart';
import 'package:mobile_frontend/providers/search_provider.dart';
import 'package:mobile_frontend/providers/sessions_provider.dart';
import 'package:mobile_frontend/features/shared/call_screen.dart';
import 'providers/booking_provider.dart';
import 'package:mobile_frontend/services/profileservice.dart';
import 'features/client_dashboard/bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/profile_provider.dart';
import 'providers/ratecard_provider.dart';
import 'providers/user_provider.dart';
import 'features/auth/login/loginscreen.dart';
import 'features/auth/roleSelection.dart';
import 'features/creative_dashboard/bottom_nav_bar.dart';
import 'services/authservice.dart';
import 'services/push_notification_service.dart';
import 'services/notification_service.dart';
import 'app/in_app_banner.dart';
import 'app/splashscreen/splashscreen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  final prefs = await SharedPreferences.getInstance();
  final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

  final userProvider = UserProvider();
  await userProvider.loadUser();

  bool tokenValid = false;
  if (userProvider.token != null) {
    try {
      final profileService = ProfilePortfolioService();
      await profileService.getProfile(token: userProvider.token!);
      tokenValid = true;
    } catch (e) {
      await AuthService().logout();
      await userProvider.loadUser();
      tokenValid = false;
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: userProvider),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => RateCardProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => SessionsProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => CallProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MyApp(
        initialUser: tokenValid ? userProvider.user : null,
        seenOnboarding: seenOnboarding,
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  final Map<String, dynamic>? initialUser;
  final bool seenOnboarding;

  const MyApp({
    super.key,
    required this.initialUser,
    required this.seenOnboarding,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _pushService = PushNotificationService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final callProvider = context.read<CallProvider>();
      final chatProvider = context.read<ChatProvider>();
      final userProvider = context.read<UserProvider>();

      // ── Register call signaling FIRST ──
      callProvider.registerSignaling();

      // ── Wire the incoming-call UI trigger ──
      callProvider.onIncomingCall = () {
        print('📞 [App] onIncomingCall fired — pushing CallScreen');
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const CallScreen()),
        );
      };

      // ── Wire peer-info resolver (so incoming calls show name/avatar) ──
      callProvider.resolvePeerInfo = (userId) {
        for (final conv in chatProvider.conversations) {
          final participants = List<dynamic>.from(conv['participants'] ?? []);
          for (final p in participants) {
            if (p is Map && p['id'] == userId) {
              return {
                'name': (p['businessName'] ?? p['displayName'] ?? p['name'])
                    ?.toString(),
                'avatarUrl': p['profilePhotoUrl']?.toString(),
              };
            }
          }
        }
        return null;
      };

      // ── Connect socket IMMEDIATELY if already authenticated ──
      // Previously the socket was only connected when the chat list
      // screen opened, which meant incoming calls were silently lost
      // if the user was on any other screen (dashboard, profile, etc.).
      final token = userProvider.token;
      final userId = userProvider.user?['id'];
      if (token != null &&
          token.isNotEmpty &&
          userId != null &&
          userId.isNotEmpty) {
        print('📞 [App] Authenticated on startup — connecting socket now');
        chatProvider.connectSocket(token, userId);
        // Also pre-load conversations so rooms are joined and
        // resolvePeerInfo has data to work with.
        chatProvider.loadConversations(token);
      } else {
        print('📞 [App] Not authenticated at startup — socket will connect after login');
      }
      // ── Start location emission for creatives ──
      final role = userProvider.user?['role']?.toString().toLowerCase();
      if (role == 'photographer') {
        final locProvider = context.read<LocationProvider>();
        locProvider.startEmitting();
        print('📍 Location emission started for photographer');
      }

      // ── Initialize push notifications (FCM) ──
      _pushService.init();

      // Surface a branded in-app banner when a push arrives in the foreground.
      _pushService.onForegroundMessage = (message) {
        context.read<NotificationProvider>().load();
        final type = (message.data['type'] ?? '').toString();
        final title =
            message.notification?.title ?? message.data['title']?.toString();
        final body =
            message.notification?.body ?? message.data['body']?.toString() ?? '';
        if (title == null || title.isEmpty) return;
        final ctx = navigatorKey.currentContext;
        if (ctx == null) return;

        // Reuse the existing per-type icon/color mapping so the banner matches
        // the notification-list styling.
        final n = AppNotification(
          id: '',
          type: type,
          title: title,
          body: body,
          data: message.data,
          read: false,
          createdAt: DateTime.now(),
        );
        showInAppBanner(
          ctx,
          title: title,
          body: body,
          icon: n.icon,
          color: n.color,
          onTap: () => _handleNotificationData(message.data),
        );
      };

      // Deep-link when the user taps an FCM notification.
      _pushService.onNotificationTap = (message) {
        context.read<NotificationProvider>().load();
        _handleNotificationData(message.data);
      };

      // Deep-link when the user taps a locally-displayed (styled) notification.
      _pushService.onLocalNotificationTap = (payload) {
        context.read<NotificationProvider>().load();
        if (payload == null || payload.isEmpty) return;
        try {
          final data = Map<String, dynamic>.from(jsonDecode(payload) as Map);
          _handleNotificationData(data);
        } catch (_) {}
      };

      // Surface a branded in-app banner for incoming chat messages.
      chatProvider.onIncomingMessage = (msg) {
        final ctx = navigatorKey.currentContext;
        if (ctx == null) return;
        showInAppBanner(
          ctx,
          title: _resolveSenderName(msg) ?? 'New message',
          body: (msg['content'] ?? '').toString(),
          icon: Icons.chat_bubble_outline,
          color: brandGreen,
          onTap: () => _handleNotificationData({
            'type': 'new_message',
            'conversationId': msg['conversationId'],
          }),
        );
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'PhotoBook',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF7A33),
          primary: const Color(0xFFFF7A33),
        ),
        textTheme: GoogleFonts.quicksandTextTheme(
          Theme.of(context).textTheme,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(color: Colors.black),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFFF7A33)),
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFFFF7A33);
            }
            return null;
          }),
          checkColor: const WidgetStatePropertyAll(Colors.white),
        ),
        radioTheme: RadioThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFFFF7A33);
            }
            return null;
          }),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.black,
          selectionColor: Color(0x33FF7A33),
          selectionHandleColor: Color(0xFFFF7A33),
        ),
      ),
      home: _getStartPage(),
    );
  }

  void _handleNotificationData(Map<String, dynamic> data) {
    final type = (data['type'] ?? data['notificationType'] ?? '').toString();
    switch (type) {
      case 'incoming_call':
      case 'call':
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const CallScreen()),
        );
        break;
      case 'new_message':
      case 'offer_received':
      case 'offer_updated':
        BottomTabs.tabIndex.value = 3; // Chat
        CreativeBottomTabs.tabIndex.value = 3; // Chat
        break;
      case 'booking_confirmed':
      case 'booking_cancelled':
      case 'booking_reminder':
      case 'review_request':
      case 'payment_success':
      case 'refund':
        BottomTabs.tabIndex.value = 1; // Bookings
        CreativeBottomTabs.tabIndex.value = 1; // Bookings
        break;
      default:
        break;
    }
  }

  String? _resolveSenderName(Map<String, dynamic> msg) {
    final convId = msg['conversationId'];
    final senderId = msg['senderId'];
    if (convId == null || senderId == null) return null;
    final chatProvider = context.read<ChatProvider>();
    for (final conv in chatProvider.conversations) {
      if (conv['id'] != convId) continue;
      final participants = List<dynamic>.from(conv['participants'] ?? []);
      for (final p in participants) {
        if (p is Map && p['id'] == senderId) {
          return (p['businessName'] ?? p['displayName'] ?? p['name'])
              ?.toString();
        }
      }
    }
    return null;
  }

  Widget _getStartPage() {
    if (!widget.seenOnboarding) {
      return OnboardingPage();
    }
    if (widget.initialUser == null) {
      return LoginPage();
    }
    final role = widget.initialUser!['role']?.toString().toLowerCase();

    if (role == 'photographer') {
      return const CreativeBottomTabs();
    } else if (role == 'client') {
      return const BottomTabs();
    } else {
      return const RoleSelectionPage();
    }
  }
}