import 'package:flutter/material.dart';
import 'package:mobile_frontend/providers/sessions_provider.dart';
import 'package:mobile_frontend/providers/user_provider.dart';
import 'package:provider/provider.dart';

class CreativeBookingsPage extends StatefulWidget {
  const CreativeBookingsPage({super.key});

  @override
  State<CreativeBookingsPage> createState() => _CreativeBookingsPageState();
}

class _CreativeBookingsPageState extends State<CreativeBookingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final token = context.read<UserProvider>().token;
    if (token == null) return;
    await context.read<SessionsProvider>().loadSessions(token: token);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SessionsProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          color: Color(0xFFFF7A33),
          backgroundColor: Colors.white,
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: const Text(
                    "Bookings",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              if (provider.isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF7A33)),
                  ),
                )
              else if (provider.sessions.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      "No bookings yet.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else ...[
                // Upcoming
                if (provider.upcoming.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        "Upcoming (${provider.upcoming.length})",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _BookingCard(session: provider.upcoming[index]),
                      childCount: provider.upcoming.length,
                    ),
                  ),
                ],

                // Past
                if (provider.past.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(
                        "Past (${provider.past.length})",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _BookingCard(session: provider.past[index]),
                      childCount: provider.past.length,
                    ),
                  ),
                ],
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingSession session;

  const _BookingCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final isUpcoming = session.isUpcoming;
    final statusColor = isUpcoming ? const Color(0xFF047418) : Colors.red;
    final statusLabel = isUpcoming ? "Upcoming" : "Past";

    final date = session.scheduledAt;
    final dateStr = "${date.day}/${date.month}/${date.year}";
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final timeStr = "$hour:$minute";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9F6),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: session.clientAvatarUrl != null
                ? Image.network(
                    session.clientAvatarUrl!,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.asset(
                      "assets/profileplaceholder.png",
                      width: 52,
                      height: 52,
                    ),
                  )
                : Image.asset(
                    "assets/profileplaceholder.png",
                    width: 52,
                    height: 52,
                  ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      session.clientName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor, width: 0.8),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 13,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "$dateStr at $timeStr",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                if (session.location != null &&
                    session.location!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          session.location!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                // The notes field holds event_type_name
                if (session.notes != null && session.notes!.isNotEmpty)
                  Text(
                    session.notes!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF047418),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  session.status.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.black38,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
