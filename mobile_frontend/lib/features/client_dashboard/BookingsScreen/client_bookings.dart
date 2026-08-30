import 'package:flutter/material.dart';
import 'package:mobile_frontend/app/skeleton.dart';
import 'package:mobile_frontend/features/client_dashboard/BookingsScreen/booking_details.dart';
import 'package:mobile_frontend/features/client_dashboard/BookingsScreen/client_booking_model.dart';
import 'package:mobile_frontend/providers/user_provider.dart';
import 'package:mobile_frontend/services/booking_service.dart';
import 'package:mobile_frontend/services/profileservice.dart';
import 'package:provider/provider.dart';

class ClientBookingsPage extends StatefulWidget {
  const ClientBookingsPage({super.key});

  @override
  State<ClientBookingsPage> createState() => _ClientBookingsPageState();
}

/// Client-side bookings list: tabs, summary cards and booking cards.
class _ClientBookingsPageState extends State<ClientBookingsPage> {
  final _service = BookingService();
  List<ClientBooking> _bookings = [];
  bool _loading = true;
  String _tab = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final token = context.read<UserProvider>().token;
    if (token == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final data = await _service.getMySessions(token: token);
      final bookings = data
          .map((e) => ClientBooking.fromJson(e as Map<String, dynamic>))
          .toList();
      bookings.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

      // Older sessions don't include the creative's name/avatar in the
      // payload — enrich them from the profile API so cards, details and
      // chat show the real creative instead of "Creative". Keep the loading
      // skeleton up until this completes so cards never flash placeholder
      // data.
      final profileService = ProfilePortfolioService();
      final enriched = await Future.wait(bookings.map((booking) async {
        if (booking.creativeId.isEmpty || !booking.needsCreativeInfo) {
          return booking;
        }
        try {
          final profile = await profileService.getProfile(
            token: token,
            userId: booking.creativeId,
          );
          final raw = profile['profile'] ?? profile;
          if (raw is! Map) return booking;
          final name = raw['business_name'] ??
              raw['businessName'] ??
              raw['name'] ??
              raw['full_name'] ??
              raw['display_title'] ??
              raw['displayTitle'];
          final avatar = raw['photographer_profile_photo_url'] ??
              raw['avatarUrl'] ??
              raw['avatar_url'] ??
              raw['profile_photo_url'];
          if (name == null && avatar == null) return booking;
          return booking.copyWith(
            creativeName: name != null ? name.toString() : null,
            creativeAvatarUrl: avatar != null ? avatar.toString() : null,
          );
        } catch (_) {
          return booking;
        }
      }));
      if (mounted) {
        setState(() {
          _bookings = enriched;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<ClientBooking> get _filtered {
    switch (_tab) {
      case 'Upcoming':
        return _bookings.where((b) => b.isUpcoming).toList();
      case 'Completed':
        return _bookings.where((b) => b.isCompleted).toList();
      case 'Cancelled':
        return _bookings.where((b) => b.isCancelled).toList();
      default:
        return _bookings;
    }
  }

  ClientBooking? _nextOf(bool Function(ClientBooking) test) {
    ClientBooking? found;
    for (final b in _bookings.where(test)) {
      if (found == null || b.scheduledAt.isAfter(found.scheduledAt)) {
        found = b;
      }
    }
    return found;
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _bookings.where((b) => b.isUpcoming).toList();
    final completed = _bookings.where((b) => b.isCompleted).toList();
    final next = _nextOf((b) => b.isUpcoming);
    final last = _nextOf((b) => b.isCompleted);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          color: bookingOrange,
          backgroundColor: Colors.white,
          onRefresh: _load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Bookings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),
                ),
              ),

              // Summary cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: 'Upcoming (${upcoming.length})',
                          subtitle:
                              next != null
                                  ? 'Next: ${next.dateLabel}'
                                  : 'Next: —',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SummaryCard(
                          title: 'Completed (${completed.length})',
                          subtitle:
                              last != null
                                  ? 'Last: ${last.dateLabel}'
                                  : 'Last: —',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Tabs
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final tab in const [
                          'All',
                          'Upcoming',
                          'Completed',
                          'Cancelled',
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _TabChip(
                              label: tab,
                              selected: _tab == tab,
                              onTap: () => setState(() => _tab = tab),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              if (_loading)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const SkeletonListTile(),
                    childCount: 5,
                  ),
                )
              else if (_bookings.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(),
                )
              else if (_filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No $_tab bookings yet.',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final booking = _filtered[index];
                    return _ClientBookingCard(
                      booking: booking,
                      onTap: () async {
                        final changed = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ClientBookingDetailsPage(booking: booking),
                          ),
                        );
                        if (changed == true && mounted) _load();
                      },
                    );
                  }, childCount: _filtered.length),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SummaryCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3EC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bookingOrange.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? bookingOrange : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? bookingOrange : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _ClientBookingCard extends StatelessWidget {
  final ClientBooking booking;
  final VoidCallback onTap;

  const _ClientBookingCard({required this.booking, required this.onTap});

  Color get _statusColor {
    if (booking.isCancelled) return Colors.red;
    if (booking.isCompleted) return const Color(0xFF2E7DD1);
    if (booking.isAwaitingConfirmation) return bookingOrange;
    return bookingGreen;
  }

  String get _statusLabel {
    final s = booking.status.toLowerCase();
    if (booking.isCancelled) return 'Cancelled';
    if (booking.isCompleted) return 'Completed';
    if (booking.isAwaitingConfirmation) return 'Awaiting Confirmation';
    if (s.contains('review')) return 'Under Review';
    return 'Upcoming';
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F9F6),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: booking.creativeAvatarUrl != null
                  ? Image.network(
                      booking.creativeAvatarUrl!,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/profileplaceholder.png',
                        width: 52,
                        height: 52,
                      ),
                    )
                  : Image.asset(
                      'assets/profileplaceholder.png',
                      width: 52,
                      height: 52,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          booking.creativeName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color, width: 0.8),
                        ),
                        child: Text(
                          _statusLabel,
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (booking.serviceType != null &&
                      booking.serviceType!.isNotEmpty)
                    Text(
                      booking.serviceType!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '${booking.dateLabel} • ${booking.priceLabel}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
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
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3EC),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_note_outlined,
                size: 34,
                color: bookingOrange,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No booking yet...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'New bookings will appear here once you book a creative.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
