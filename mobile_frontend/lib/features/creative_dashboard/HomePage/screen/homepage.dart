import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_frontend/app/count_up_effect.dart';
import 'package:mobile_frontend/app/skeleton.dart';
import 'package:mobile_frontend/features/client_dashboard/HomeScreen/notifications_page.dart';
import 'package:mobile_frontend/features/creative_dashboard/BookingsPage/booking_detail_page.dart';
import 'package:mobile_frontend/features/creative_dashboard/BookingsPage/bookingspage.dart';
import 'package:mobile_frontend/features/creative_dashboard/onboarding/creative_onboarding_page.dart';
import 'package:mobile_frontend/features/creative_dashboard/HomePage/model/booking_model.dart';
import 'package:mobile_frontend/providers/notification_provider.dart';
import 'package:mobile_frontend/providers/sessions_provider.dart';
import 'package:mobile_frontend/providers/user_provider.dart';
import 'package:mobile_frontend/services/authservice.dart';
import 'package:mobile_frontend/services/location_service.dart';
import 'package:mobile_frontend/services/payout_service.dart';
import 'package:mobile_frontend/services/profileservice.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

class CreativeHomePage extends StatefulWidget {
  const CreativeHomePage({Key? key}) : super(key: key);

  @override
  _CreativeHomePageState createState() => _CreativeHomePageState();
}

class _CreativeHomePageState extends State<CreativeHomePage> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<UserProvider>().token;
      if (token != null) {
        context.read<SessionsProvider>().loadSessions(token: token);
      }
      context.read<NotificationProvider>().load();
      _loadOnboardingStatus(token);
    });
  }

  static const _onboardingCacheKey = 'creative_onboarding_status';

  Future<void> _loadOnboardingStatus(String? token) async {
    // Show the last-known status immediately so the card never flashes
    // "0 of 4" while the fresh checks run after an app restart.
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getStringList(_onboardingCacheKey);
    if (cached != null && cached.length == 4 && mounted) {
      setState(() {
        _step1Done = cached[0] == '1';
        _step2Done = cached[1] == '1';
        _step3Done = cached[2] == '1';
        _step4Done = cached[3] == '1';
        _onboardingStatusLoaded = true;
      });
    }

    if (token == null) return;
    final profileService = ProfilePortfolioService();

    // Run all four checks in parallel and update the UI in a single setState,
    // so the counter doesn't visibly count up 0 → 1 → 2 → 3.
    final results = await Future.wait<bool?>([
      _checkStep1(profileService, token),
      _checkStep2(),
      _checkStep3(profileService, token),
      _checkStep4(token),
    ]);

    if (!mounted) return;
    setState(() {
      _step1Done = results[0] ?? _step1Done;
      _step2Done = results[1] ?? _step2Done;
      _step3Done = results[2] ?? _step3Done;
      _step4Done = results[3] ?? _step4Done;
      _onboardingStatusLoaded = true;
    });
    await prefs.setStringList(_onboardingCacheKey, [
      _step1Done ? '1' : '0',
      _step2Done ? '1' : '0',
      _step3Done ? '1' : '0',
      _step4Done ? '1' : '0',
    ]);
  }

  Future<bool?> _checkStep1(
    ProfilePortfolioService service,
    String token,
  ) async {
    try {
      final data = await service.getProfile(token: token);
      final raw = data['profile'] ?? data;
      final biz = (raw['business_name'] ?? raw['businessName'] ?? '')
          .toString();
      final title = (raw['display_title'] ?? raw['displayTitle'] ?? '')
          .toString();
      return biz.isNotEmpty && title.isNotEmpty;
    } catch (_) {
      return null; // unknown — keep the cached value
    }
  }

  Future<bool?> _checkStep2() async {
    try {
      final loc = await LocationService().getMyLocation();
      return loc != null;
    } catch (_) {
      return null;
    }
  }

  Future<bool?> _checkStep3(
    ProfilePortfolioService service,
    String token,
  ) async {
    try {
      final portfolio = await service.getMyPortfolio(token: token);
      return portfolio.isNotEmpty;
    } catch (_) {
      return null;
    }
  }

  Future<bool?> _checkStep4(String token) async {
    try {
      final bank = await PayoutService().getBankAccount(token: token);
      return bank != null;
    } catch (_) {
      return null;
    }
  }

  // Dummy Data
  final List<Booking> bookings = [
    Booking(
      name: "David Joseph",
      type: "Marriage Shoot",
      date: DateTime(2025, 9, 22),
      location: "Outdoor",
      time: "02:00 pm",
    ),
    Booking(
      name: "KhalaManja",
      type: "Head Shot",
      date: DateTime(2025, 9, 24),
      location: "Indoor",
      time: "02:00 pm",
    ),
    Booking(
      name: "Jeff Bay",
      type: "Marriage Shoot",
      date: DateTime(2025, 9, 30),
      location: "Outdoor",
      time: "02:00 pm",
    ),
    Booking(
      name: "Tolu Makinde",
      type: "Birthday shoot",
      date: DateTime(2025, 10, 1),
      location: "Outdoor",
      time: "03:00 pm",
    ),
  ];

  DateTime selectedDate = DateTime.now();
  String _timeFilter = 'This Month';
  bool _step1Done = false; // professional info
  bool _step2Done = false; // location
  bool _step3Done = false; // portfolio & packages
  bool _step4Done = false; // payment
  bool _onboardingStatusLoaded = false;

  String _formatActivityTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    final sessionsProvider = context.watch<SessionsProvider>();

    final firstName = user?['name']?.split(' ').first ?? "Guest";
    final businessName = user?['businessName'];

    final upcomingSessions = sessionsProvider.upcoming
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    final nextSession = upcomingSessions.isNotEmpty
        ? upcomingSessions.first
        : null;

    final bookedDates = sessionsProvider.sessions
        .map(
          (s) => DateTime(
            s.scheduledAt.year,
            s.scheduledAt.month,
            s.scheduledAt.day,
          ),
        )
        .toSet();

    final allSessions = sessionsProvider.sessions;
    final successfulSessions = allSessions.where((s) {
      final st = s.status.toLowerCase();
      return st.contains('complete') || st.contains('deliver') || st == 'done';
    }).length;
    final cancelledSessions = allSessions.where((s) => s.isCancelled).length;
    final totalEarnings = allSessions
        .where((s) {
          final st = s.status.toLowerCase();
          return st.contains('complete') ||
              st.contains('deliver') ||
              st == 'done';
        })
        .fold<int>(0, (sum, s) => sum + ((s.agreedAmount ?? 0) * 0.7).round());
    final profileViews = 0; // TODO: needs a backend profile-view counter

    final completedSteps = [
      _step1Done,
      _step2Done,
      _step3Done,
      _step4Done,
    ].where((d) => d).length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                businessName != null && businessName.isNotEmpty
                    ? "Hello $firstName ($businessName),"
                    : "Hello $firstName,",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              if (_onboardingStatusLoaded && completedSteps < 4)
                _buildOnboardingCard(completedSteps),

              const SizedBox(height: 20),

              // Calendar
              Card(color: Colors.white, child: buildCalendar(bookedDates)),

              const SizedBox(height: 20),

              // Upcoming Bookings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Upcoming Bookings",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreativeBookingsPage(),
                      ),
                    ),
                    child: const Text(
                      "See all",
                      style: TextStyle(color: Color(0xFFFF7A33), fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (sessionsProvider.isLoading)
                const SkeletonListTile()
              else if (nextSession == null)
                const Text(
                  "No upcoming bookings",
                  style: TextStyle(color: Colors.grey),
                )
              else
                buildUpcomingBookingCard(nextSession),

              const SizedBox(height: 20),

              // My Numbers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "My Numbers",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _timeFilter,
                      isDense: true,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Color(0xFFFF7A33),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'This Month',
                          child: Text('This Month'),
                        ),
                        DropdownMenuItem(
                          value: 'This Week',
                          child: Text('This Week'),
                        ),
                        DropdownMenuItem(
                          value: 'This Year',
                          child: Text('This Year'),
                        ),
                        DropdownMenuItem(
                          value: 'All Time',
                          child: Text('All Time'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _timeFilter = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (successfulSessions == 0 &&
                  cancelledSessions == 0 &&
                  totalEarnings == 0)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      "No data yet",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.9,
                  children: [
                    _statCard(
                      value: totalEarnings,
                      label: 'Total Earnings',
                      color: const Color(0xFF2457C5),
                      imagePath: 'assets/Cash.png',
                      isCurrency: true,
                    ),
                    _statCard(
                      value: successfulSessions,
                      label: 'Successful Sessions',
                      color: const Color(0xFF047418),
                      imagePath: 'assets/up_trend_arrow.png',
                    ),
                    _statCard(
                      value: cancelledSessions,
                      label: 'Cancelled Sessions',
                      color: const Color(0xFFE60909),
                      imagePath: 'assets/down_trend_arrow.png',
                    ),
                    _statCard(
                      value: profileViews,
                      label: 'Profile Views',
                      color: const Color(0xFF7C3AED),
                      icon: Icons.visibility_outlined,
                    ),
                  ],
                ),

              const SizedBox(height: 20),

              // Recent Activity
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Recent Activity",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton(
                    onPressed: () {
                      context.read<NotificationProvider>().load();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "See more",
                      style: TextStyle(color: Color(0xFFFF7A33), fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Consumer<NotificationProvider>(
                builder: (context, notif, _) {
                  final items = notif.notifications.take(3).toList();
                  if (items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        "No recent activity",
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }
                  return Column(
                    children: items.map((n) {
                      return ListTile(
                        tileColor: const Color(0xFFF5F9F6),
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                        ),
                        leading: Icon(n.icon, size: 18, color: n.color),
                        title: Text(
                          n.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          n.body,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        trailing: Text(
                          _formatActivityTime(n.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  CalendarFormat _calendarFormat = CalendarFormat.month;

  Widget buildCalendar(Set<DateTime> bookedDates) {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: selectedDate,
      selectedDayPredicate: (day) => isSameDay(selectedDate, day),

      onDaySelected: (selected, focused) {
        setState(() {
          selectedDate = selected;
        });
      },

      calendarFormat: _calendarFormat,
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },

      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          border: Border.all(color: Colors.grey, width: 2),
          shape: BoxShape.circle,
        ),
        todayTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        selectedDecoration: BoxDecoration(
          border: Border.all(color: Color(0xFFFF7A33), width: 2),
          shape: BoxShape.circle,
        ),
        selectedTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),

        outsideDaysVisible: true,
      ),

      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) {
          final dayOnly = DateTime(day.year, day.month, day.day);
          final isBooked = bookedDates.contains(dayOnly); // ✅ real data
          if (isBooked) {
            return Container(
              height: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7A33),
                borderRadius: BorderRadius.circular(40),
              ),
              alignment: Alignment.center,
              child: Text(
                '${day.day}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }
          return null;
        },
        selectedBuilder: (context, day, focusedDay) {
          final dayOnly = DateTime(day.year, day.month, day.day);
          final isBooked = bookedDates.contains(dayOnly); // ✅ real data
          final isToday = isSameDay(day, DateTime.now());

          if (isBooked) {
            // 🔶 Selected booked day = booked pill + orange ring
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 25,
                  margin: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF7A33),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${day.day}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  height: 28,
                  margin: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFFF7A33),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
              ],
            );
          }

          if (isToday) {
            // 🔸 Selected today = grey ring (not orange fill)
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 2),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '${day.day}',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          return null; // others use calendarStyle
        },
      ),
    );
  }

  Widget buildUpcomingBookingCard(BookingSession session) {
    final date = session.scheduledAt;
    final timeStr =
        "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";

    return GestureDetector(
      onTap: () => _openBookingDetails(session),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F9F6),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: session.clientAvatarUrl != null
                      ? Image.network(
                          session.clientAvatarUrl!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.asset(
                            "assets/profileplaceholder.png",
                            width: 50,
                            height: 50,
                          ),
                        )
                      : Image.asset(
                          "assets/profileplaceholder.png",
                          width: 50,
                          height: 50,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      session.clientName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF047418).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    timeStr,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF047418),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (session.notes != null && session.notes!.isNotEmpty) ...[
              _infoRow(Icons.cake_outlined, session.notes!),
              const SizedBox(height: 6),
            ],
            _infoRow(
              Icons.calendar_today_outlined,
              DateFormat('d MMMM, yyyy').format(date),
            ),
            const SizedBox(height: 6),
            if (session.location != null && session.location!.isNotEmpty) ...[
              _infoRow(Icons.location_on_outlined, session.location!),
              const SizedBox(height: 6),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: _viewDetailsButton(session),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.grey),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _viewDetailsButton(BookingSession session) {
    return InkWell(
      onTap: () => _openBookingDetails(session),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "View details",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.arrow_forward, size: 14, color: Colors.black),
          ],
        ),
      ),
    );
  }

  void _openBookingDetails(BookingSession session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreativeBookingDetailPage(session: session),
      ),
    );
  }

  Widget _statCard({
    required int value,
    required String label,
    required Color color,
    String? imagePath,
    IconData? icon,
    bool isCurrency = false,
  }) {
    final Widget badge = imagePath != null
        ? Image.asset(imagePath, height: 20, width: 20)
        : Icon(icon, size: 20, color: color);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: isCurrency
                    ? CountUpFormattedText(
                        endValue: value,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      )
                    : CountUpText(
                        endValue: value,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
              ),
              badge,
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingCard(int completedSteps) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE7D1), Color(0xFFFFF3EC)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF7A33), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.person_pin_circle_outlined,
                color: Color(0xFFFF7A33),
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Complete Your Creative Profile',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Finish setting up your profile so clients can find you and start booking your services.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: completedSteps / 4,
                    minHeight: 6,
                    backgroundColor: Colors.white,
                    color: const Color(0xFFFF7A33),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$completedSteps of 4 steps completed',
                style: TextStyle(fontSize: 11, color: Colors.grey[700]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreativeOnboardingPage(
                          completed: [
                            _step1Done,
                            _step2Done,
                            _step3Done,
                            _step4Done,
                          ],
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A33),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue Onboarding',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Opacity(
                opacity: 0.3,
                child: Image.asset(
                  'assets/photobooklogo.jpg',
                  width: 40,
                  height: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
