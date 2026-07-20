import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_frontend/providers/booking_provider.dart';
import 'package:mobile_frontend/providers/user_provider.dart';
import 'package:mobile_frontend/services/booking_service.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class BookingPage extends StatefulWidget {
  final String creativeId;
  final String name;
  final String avatarUrl;
  final double rating;

  const BookingPage({
    super.key,
    required this.creativeId,
    required this.name,
    required this.avatarUrl,
    required this.rating,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  bool showCalendar = false;
  List<Map<String, dynamic>> eventTypes = []; // ✅ from API
  bool _submitting = false;

  List<String> availableTimes = [
    "8:00 AM",
    "9:00 AM",
    "10:00 AM",
    "11:00 AM",
    "12:00 PM",
    "1:00 PM",
    "2:00 PM",
    "3:00 PM",
    "4:00 PM",
    "5:00 PM",
  ];

  String _convertTo24Hour(String time12h) {
    final parsed =
        TimeOfDayFormat.HH_colon_mm; // ignore this, just parse manually

    final parts = time12h.split(' ');
    final time = parts[0];
    final modifier = parts[1];

    int hour = int.parse(time.split(':')[0]);
    final minute = time.split(':')[1];

    if (modifier == 'PM' && hour != 12) {
      hour += 12;
    } else if (modifier == 'AM' && hour == 12) {
      hour = 0;
    }

    return '${hour.toString().padLeft(2, '0')}:$minute';
  }

  @override
  void initState() {
    super.initState();
    context.read<BookingProvider>().booking.creativeId = widget.creativeId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadEventTypes());
  }

  Future<void> _loadEventTypes() async {
    final token = context.read<UserProvider>().token;
    if (token == null) return;
    try {
      final response = await http.get(
        Uri.parse('https://api.photobookhq.com/api/sessions/event-types'),
        headers: {'Authorization': 'Bearer $token'},
      );
      print("📋 Event types raw: ${response.statusCode} ${response.body}");
      final data = jsonDecode(response.body);
      final list = data is List
          ? data
          : data['eventTypes'] ?? data['items'] ?? data['data'] ?? [];
      setState(() => eventTypes = List<Map<String, dynamic>>.from(list));
      if (eventTypes.isEmpty) {
        setState(
          () => eventTypes = [
            {'id': 1, 'name': 'Wedding'},
            {'id': 2, 'name': 'Birthday'},
            {'id': 3, 'name': 'Corporate'},
            {'id': 4, 'name': 'Portrait'},
            {'id': 5, 'name': 'Product'},
          ],
        );
      }
    } catch (e) {
      print("❌ Failed to load event types: $e");
    }
  }

  Future<void> _submitBooking() async {
    final booking = context.read<BookingProvider>().booking;
    final token = context.read<UserProvider>().token;

    if (booking.eventTypeId == null ||
        booking.date == null ||
        booking.time == null ||
        booking.locationType == null ||
        booking.location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }
    final payload = {
      "photographerId": widget.creativeId,
      "eventTypeId": booking.eventTypeId,
      "packageType": booking.package?.toLowerCase() ?? 'regular',
      "sessionDate":
          "${booking.date!.year}-${booking.date!.month.toString().padLeft(2, '0')}-${booking.date!.day.toString().padLeft(2, '0')}",
      "sessionTime": _convertTo24Hour(booking.time!),
      "locationType": booking.locationType!.toLowerCase().replaceAll(' ', '_'),
      "locationText": booking.location!,
    };
    print("🚀 Booking payload: $payload");
    setState(() => _submitting = true);
    try {
      final success = await BookingService().createSession(
        token: token!,
        photographerId: widget.creativeId,
        eventTypeId: booking.eventTypeId!,
        packageType: booking.package?.toLowerCase() ?? 'regular',
        sessionDate:
            "${booking.date!.year}-${booking.date!.month.toString().padLeft(2, '0')}-${booking.date!.day.toString().padLeft(2, '0')}",
        sessionTime: _convertTo24Hour(booking.time!),
        locationType: booking.locationType!.toLowerCase().replaceAll(' ', '_'),
        locationText: booking.location!,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Booking request sent!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Failed to book: $e")));
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingProvider>().booking;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text(
          "Book a Session",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// CREATIVE INFO
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: widget.avatarUrl.isNotEmpty
                      ? Image.network(
                          widget.avatarUrl,
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/profileplaceholder.png',
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          'assets/profileplaceholder.png',
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                        ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (i) => const Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                    Text(
                      "Corporate Photographer",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            _dropdown(
              title: "Event Type",
              value: booking.eventType,
              items: eventTypes
                  .map(
                    (e) => e['display_name']?.toString() ?? '',
                  ) // ✅ was 'name'
                  .where((e) => e.isNotEmpty)
                  .toList(),
              onChange: (v) {
                final match = eventTypes.firstWhere(
                  (e) => e['display_name'] == v,
                  orElse: () => {},
                );
                final provider = context.read<BookingProvider>();
                provider.setEventType(v ?? "");
                provider.setEventTypeId(
                  match['id'] as int?,
                ); // ✅ id is already an int
              },
            ),

            _dropdown(
              title: "Package",
              value: booking.package,
              items: ["Regular", "Premium"],
              onChange: (v) =>
                  context.read<BookingProvider>().setPackage(v ?? ""),
            ),

            /// DATE PICKER (TABLE CALENDAR)
            GestureDetector(
              onTap: () => setState(() => showCalendar = !showCalendar),
              child: _dropdownDisplay(
                title: "Date",
                value: booking.date == null
                    ? "DD / MM / YYYY"
                    : "${booking.date!.day}/${booking.date!.month}/${booking.date!.year}",
              ),
            ),

            if (showCalendar) _calendar(),

            /// TIME SELECTOR
            const SizedBox(height: 20),
            const Text("Time", style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: availableTimes.map((time) {
                final isSelected = time == booking.time;

                return GestureDetector(
                  onTap: () => context.read<BookingProvider>().setTime(time),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: isSelected ? Colors.black : Colors.white,
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.grey.shade400,
                      ),
                    ),
                    child: Text(
                      time,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            _dropdown(
              title: "Location Type",
              value: booking.locationType,
              items: ["Indoor", "Outdoor"],
              onChange: (v) =>
                  context.read<BookingProvider>().setLocationType(v ?? ""),
            ),

            _dropdown(
              title: "Location",
              value: booking.location,
              items: ["Lekki", "Ikeja", "YabaPoly", "Victoria Island", "Abuja"],
              onChange: (v) =>
                  context.read<BookingProvider>().setLocation(v ?? ""),
            ),

            const SizedBox(height: 60),

            /// BOOK BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submitBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A33),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Book Session",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown({
    required String title,
    required String? value,
    required List<String> items,
    required Function(String?) onChange,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: const Text("Select"),
              isExpanded: true,
              items: items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: onChange,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// Fake dropdown display for date
  Widget _dropdownDisplay({required String title, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value, style: const TextStyle(color: Colors.black)),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  CalendarFormat _calendarFormat = CalendarFormat.month;
  Widget _calendar() {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TableCalendar(
        focusedDay: DateTime.now(),
        firstDay: DateTime.now(),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        calendarStyle: const CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
          ),
        ),
        calendarFormat: _calendarFormat,
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onDaySelected: (selected, _) {
          context.read<BookingProvider>().setDate(selected);
          setState(() => showCalendar = false);
        },
      ),
    );
  }
}
