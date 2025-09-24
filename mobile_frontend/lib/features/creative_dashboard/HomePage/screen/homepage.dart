import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_frontend/app/count_up_effect.dart';
import 'package:mobile_frontend/app/user_provider.dart';
import 'package:mobile_frontend/features/creative_dashboard/HomePage/model/booking_model.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class CreativeHomePage extends StatefulWidget {
  const CreativeHomePage({Key? key}) : super(key: key);

  @override
  _CreativeHomePageState createState() => _CreativeHomePageState();
}

class _CreativeHomePageState extends State<CreativeHomePage> {
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

  final List<Activity> activities = [
    Activity(
      message: "Pre-Wedding shoot with Tolu is completed",
      time: "09:00 am",
    ),
    Activity(
      message: "Clarence cancelled his birthday shoot",
      time: "11:00 am",
    ),
    Activity(
      message: "Tolu just paid for his pre-wedding shoot",
      time: "07:00 pm",
    ),
  ];

  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    final firstName = user?['name']?.split(' ').first ?? "Guest";
    final businessName = user?['businessName'];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
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

              // Calendar
              Card(color: Colors.white, child: buildCalendar()),

              const SizedBox(height: 20),

              // Upcoming Bookings
              Text(
                "Upcoming Bookings",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              buildUpcomingBookingCard(bookings.first),

              const SizedBox(height: 20),

              // My Numbers (animated)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  buildAnimatedEarningsCard(
                    17500,
                    "Total Earnings",
                    Color(0xFF2457C5),
                    'assets/Cash.png',
                  ),
                  buildAnimatedNumberCard(
                    20,
                    "Successful sessions",
                    Color(0xFF047418),
                    'assets/up_trend_arrow.png',
                  ),
                  buildAnimatedNumberCard(
                    2,
                    "Failed sessions",
                    Color(0xFFE60909),
                    'assets/down_trend_arrow.png',
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Recent Activity
              Text(
                "Recent Activity",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Column(
                children: activities
                    .map(
                      (a) => ListTile(
                        tileColor: Color(0xFFF5F9F6),
                        dense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        leading: Icon(
                          Icons.circle,
                          size: 10,
                          color: Colors.black,
                        ),
                        title: Text(
                          a.message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: Text(a.time),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  CalendarFormat _calendarFormat = CalendarFormat.month;

  Widget buildCalendar() {
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
        // 🔶 Booked day pill (long horizontal)
        defaultBuilder: (context, day, focusedDay) {
          final isBooked = bookings.any((b) => isSameDay(b.date, day));
          if (isBooked) {
            return Container(
              height: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7A33),
                borderRadius: BorderRadius.circular(40), // pill shape
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
        // 🔸 Selected day only highlights border (so it doesn’t override booked/today)
        selectedBuilder: (context, day, focusedDay) {
          final isBooked = bookings.any((b) => isSameDay(b.date, day));
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

  Widget buildUpcomingBookingCard(Booking booking) {
    return Card(
      color: Color(0xFF615651).withOpacity(0.005),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        height: 120,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start, // align to top
          children: [
            // Column 1: Avatar
            CircleAvatar(
              radius: 24,
              backgroundImage: const AssetImage("assets/tolu_avatar.png"),
            ),

            const SizedBox(width: 12),

            // Column 2: Name, Type+Date, Location
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    booking.type,
                    style: const TextStyle(color: Color(0xFF181818)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d MMM yyyy').format(booking.date),
                    style: const TextStyle(color: Color(0xFF181818)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    booking.location,
                    style: const TextStyle(color: Color(0xFF181818)),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    booking.time,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: navigate to booking details
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero, // tighter look
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      "View details",
                      style: TextStyle(fontSize: 12, color: Color(0xFF181818)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAnimatedNumberCard(
    int value,
    String label,
    Color color,
    String imagePath,
  ) {
    return Flexible(
      child: Container(
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F9F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CountUpText(
              endValue: value,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.start,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(height: 20, width: 20, child: Image.asset(imagePath)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAnimatedEarningsCard(
    int value,
    String label,
    Color color,
    String imagePath,
  ) {
    return Flexible(
      child: Container(
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F9F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CountUpFormattedText(
              endValue: value,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.start,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(height: 20, width: 20, child: Image.asset(imagePath)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
