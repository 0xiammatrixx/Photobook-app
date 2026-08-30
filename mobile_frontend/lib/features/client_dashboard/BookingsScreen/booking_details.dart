import 'package:flutter/material.dart';
import 'package:mobile_frontend/features/client_dashboard/BookingsScreen/client_booking_model.dart';
import 'package:mobile_frontend/features/creative_dashboard/ProfilePage/profilepage.dart';
import 'package:mobile_frontend/features/shared/chat_conversation_screen.dart';
import 'package:mobile_frontend/providers/chat_provider.dart';
import 'package:mobile_frontend/providers/user_provider.dart';
import 'package:mobile_frontend/services/booking_service.dart';
import 'package:mobile_frontend/services/payment_service.dart';
import 'package:mobile_frontend/services/review_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ClientBookingDetailsPage extends StatefulWidget {
  final ClientBooking booking;

  const ClientBookingDetailsPage({super.key, required this.booking});

  @override
  State<ClientBookingDetailsPage> createState() =>
      _ClientBookingDetailsPageState();
}

class _ClientBookingDetailsPageState extends State<ClientBookingDetailsPage>
    with WidgetsBindingObserver {
  ClientBooking get booking => widget.booking;

  bool _submitting = false;
  String? _pendingReference;
  String? _pendingToken;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _pendingReference != null) {
      _verifyAndHandlePayment();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCreativeId = booking.creativeId.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _Header(booking: booking),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Creative card
                    _CreativeCard(
                      booking: booking,
                      onViewProfile: hasCreativeId
                          ? () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CreativeProfilePage(
                                  isOwner: false,
                                  creativeId: booking.creativeId,
                                ),
                              ),
                            )
                          : null,
                      onChat: hasCreativeId ? _startChat : null,
                    ),

                    const SizedBox(height: 14),

                    // Booking protection banner
                    _BookingProtectionBanner(),

                    const SizedBox(height: 14),

                    _SectionCard(
                      title: 'BOOKING DETAILS',
                      rows: [
                        if (booking.serviceType != null &&
                            booking.serviceType!.isNotEmpty)
                          _DetailRow(
                            icon: Icons.photo_camera_outlined,
                            label: booking.serviceType!,
                          ),
                        _DetailRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Date',
                          value: booking.dateLabel,
                        ),
                        _DetailRow(
                          icon: Icons.schedule_outlined,
                          label: 'Time',
                          value: booking.timeLabel,
                        ),
                        if (booking.durationLabel.isNotEmpty)
                          _DetailRow(
                            icon: Icons.timelapse_outlined,
                            label: 'Duration',
                            value: booking.durationLabel,
                          ),
                        _DetailRow(
                          icon: Icons.payments_outlined,
                          label: 'Price',
                          value: booking.priceLabel,
                        ),
                        if (booking.location != null &&
                            booking.location!.isNotEmpty)
                          _DetailRow(
                            icon: Icons.location_on_outlined,
                            label: 'Location',
                            value: booking.location!,
                          ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    _PaymentTimeline(booking: booking),

                    const SizedBox(height: 18),

                    ..._buildActions(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Action sections based on status ─────────────────────────────────────
  List<Widget> _buildActions() {
    if (booking.isCancelled) {
      return [
        Center(
          child: Text(
            'This booking was cancelled.',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ),
      ];
    }

    if (booking.isCompleted) {
      return [
        _ActionPromptCard(
          title: 'How was your session?',
          subtitle: 'Rate your experience with ${booking.creativeName}',
          buttonLabel: 'Rate Session',
          buttonColor: bookingGreen,
          onPressed: _showRatingModal,
        ),
        if (booking.status.toLowerCase().contains('deliver')) ...[
          const SizedBox(height: 12),
          _ActionPromptCard(
            title: 'How was the deliverables?',
            subtitle: "Confirm that you've received your deliverables.",
            buttonLabel: 'Confirm Deliverables',
            buttonColor: bookingOrange,
            onPressed: _showDeliverablesModal,
          ),
        ],
      ];
    }

    if (booking.isAwaitingPayment) {
      return [
        _ActionPromptCard(
          title: 'Complete your payment',
          subtitle: 'Your booking is on hold until payment is confirmed.',
          buttonLabel: 'Pay Now',
          buttonColor: bookingOrange,
          onPressed: _retryPayment,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Cancel Booking',
                color: Colors.red,
                onPressed: _confirmCancel,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                label: 'Reschedule',
                color: Colors.black,
                onPressed: () => _comingSoon('Reschedule'),
              ),
            ),
          ],
        ),
      ];
    }

    // Upcoming / other states
    final actions = <Widget>[];

    if (booking.sessionHasPassed) {
      actions.add(
        _ActionPromptCard(
          title: 'How did your session go?',
          subtitle: 'Let us know if the session went as planned.',
          buttonLabel: 'Confirm Session',
          buttonColor: bookingGreen,
          onPressed: _showSessionOutcomeModal,
        ),
      );
      actions.add(const SizedBox(height: 12));
      actions.add(
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Report A No-Show',
                color: Colors.red,
                onPressed: _showNoShowFlow,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                label: 'Reschedule',
                color: Colors.black,
                onPressed: () => _comingSoon('Reschedule'),
              ),
            ),
          ],
        ),
      );
    } else {
      actions.add(
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Cancel Booking',
                color: Colors.red,
                onPressed: _confirmCancel,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                label: 'Reschedule',
                color: Colors.black,
                onPressed: () => _comingSoon('Reschedule'),
              ),
            ),
          ],
        ),
      );
    }

    return actions;
  }

  // ── Chat ────────────────────────────────────────────────────────────────
  Future<void> _startChat() async {
    final token = context.read<UserProvider>().token;
    if (token == null || booking.creativeId.isEmpty) return;
    try {
      final result = await context.read<ChatProvider>().createConversation(
        token: token,
        participantId: booking.creativeId,
      );
      final conversationId = result['id'] ?? result['conversation']?['id'];
      if (conversationId != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatConversationScreen(
              conversationId: conversationId,
              recipientId: booking.creativeId,
              title: booking.creativeName,
              avatarUrl: booking.creativeAvatarUrl,
              isCreative: false,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to open chat: $e')));
    }
  }

  // ── Modals ──────────────────────────────────────────────────────────────
  Future<void> _confirmCancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel booking?'),
        content: const Text(
          'Your payment will be refunded according to the cancellation policy.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Booking'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Cancel Booking',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (ok == true) await _deleteSession();
  }

  Future<void> _deleteSession() async {
    final token = context.read<UserProvider>().token;
    if (token == null || booking.id.isEmpty) return;
    final success = await BookingService().deleteSession(
      token: token,
      sessionId: booking.id,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Booking cancelled. Your refund will be processed per the cancellation policy.'
              : 'Could not cancel booking. Please try again.',
        ),
      ),
    );
    if (success) Navigator.pop(context, true);
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature is coming soon')));
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Retry payment (session stuck in "pending") ─────────────────────────
  Future<void> _retryPayment() async {
    if (_submitting) return;
    final token = context.read<UserProvider>().token;
    final amount = booking.price;
    if (token == null || booking.id.isEmpty) return;
    if (amount == null || amount <= 0) {
      _snack('Payment amount unavailable. Please contact support.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final init = await PaymentService().initiatePayment(
        token: token,
        sessionId: booking.id,
        amount: amount,
      );
      final url = init?['paystackAuthorizationUrl'] ??
          init?['authorization_url'] ??
          init?['data']?['authorization_url'];
      final reference = (init?['reference'] ?? '').toString();

      if (url == null || reference.isEmpty) {
        _snack('Could not start payment. Please try again.');
        return;
      }

      _pendingToken = token;
      _pendingReference = reference;

      final launchOk = await launchUrl(
        Uri.parse(url.toString()),
        mode: LaunchMode.externalApplication,
      );
      if (!launchOk) {
        _clearPendingPayment();
        _snack('Could not open the payment page.');
      }
    } catch (e) {
      _clearPendingPayment();
      _snack('Payment failed: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _verifyAndHandlePayment() async {
    final reference = _pendingReference;
    final token = _pendingToken;
    if (reference == null || token == null || !mounted) return;

    try {
      final verify = await PaymentService().verifyPayment(
        token: token,
        reference: reference,
      );
      final status = (verify?['status'] ?? '').toString().toLowerCase();
      final confirmed = status == 'confirmed' ||
          status == 'success' ||
          status == 'successful';

      _clearPendingPayment();

      if (!mounted) return;
      if (confirmed) {
        _snack('Payment successful!');
        Navigator.pop(context, true);
      } else {
        _snack('Payment not confirmed yet — you can retry any time.');
      }
    } catch (e) {
      _clearPendingPayment();
      if (mounted) _snack('Payment verification failed: $e');
    }
  }

  void _clearPendingPayment() {
    _pendingReference = null;
    _pendingToken = null;
  }

  Future<void> _showRatingModal() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ReviewSheet(
        creativeName: booking.creativeName,
        onSubmit: (stars, comment) {
          Navigator.pop(ctx);
          _submitReview(stars, comment);
        },
      ),
    );
  }

  Future<void> _submitReview(int stars, String comment) async {
    final token = context.read<UserProvider>().token;
    if (token == null || booking.id.isEmpty) return;
    final result = await ReviewService().submitReview(
      token: token,
      sessionId: booking.id,
      rating: stars,
      comment: comment,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  Future<void> _showDeliverablesModal() => _outcomeModal(
    title: 'How was the deliverables?',
    subtitle: "Confirm that you've received your deliverables.",
    yesLabel: "Yes, I've received them and I'm satisfied",
    onConfirm: _confirmDeliverables,
  );

  Future<void> _showSessionOutcomeModal() => _outcomeModal(
    title: 'How did your session go?',
    subtitle: 'Let us know if the session went as planned.',
    yesLabel: 'Yes, session took place as planned',
    onConfirm: _confirmSession,
  );

  Future<void> _outcomeModal({
    required String title,
    required String subtitle,
    required String yesLabel,
    required Future<void> Function() onConfirm,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: bookingGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  onConfirm();
                },
                child: Text(
                  yesLabel,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _OutcomeSecondary(
              label: 'Contact Support',
              onTap: () {
                Navigator.pop(ctx);
                _comingSoon('Support');
              },
            ),
            _OutcomeSecondary(
              label: 'Report An Issue',
              onTap: () {
                Navigator.pop(ctx);
                _showNoShowFlow();
              },
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Important: You have 48hrs to confirm the session was '
                'successful. If we don\'t hear from you, the 70% payment will '
                'be released automatically.',
                style: TextStyle(fontSize: 11, color: Color(0xFF8A6D00)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSession() async {
    final token = context.read<UserProvider>().token;
    if (token == null || booking.id.isEmpty) return;
    final success = await BookingService().confirmSession(
      token: token,
      sessionId: booking.id,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Thank you for confirming!'
              : 'Could not confirm. Please try again.',
        ),
      ),
    );
  }

  Future<void> _confirmDeliverables() async {
    final token = context.read<UserProvider>().token;
    if (token == null || booking.id.isEmpty) return;
    final success = await BookingService().confirmDeliverables(
      token: token,
      sessionId: booking.id,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Thank you for confirming!'
              : 'Could not confirm. Please try again.',
        ),
      ),
    );
  }

  Future<void> _showNoShowFlow() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _NoShowSheet(booking: booking),
    );
    if (result == null) return;
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("We've received your report"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "We're reviewing your report and will contact you with an "
              'update. If the creative failed to show up, you may be eligible '
              'for a refund or replacement.',
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3EC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Booking status: Under Review',
                style: TextStyle(
                  color: bookingOrange,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'What happens next?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            const Text(
              '• We\'ll review the details of your report.',
              style: TextStyle(fontSize: 12),
            ),
            const Text(
              '• The creative will be given a chance to respond.',
              style: TextStyle(fontSize: 12),
            ),
            const Text(
              '• You\'ll receive a notification within 48hrs.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: bookingOrange),
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'View Booking',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets ────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final ClientBooking booking;

  const _Header({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
          ),
          Expanded(
            child: Text(
              booking.creativeName,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreativeCard extends StatelessWidget {
  final ClientBooking booking;
  final VoidCallback? onViewProfile;
  final VoidCallback? onChat;

  const _CreativeCard({required this.booking, this.onViewProfile, this.onChat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9F6),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: booking.creativeAvatarUrl != null
                ? Image.network(
                    booking.creativeAvatarUrl!,
                    width: 54,
                    height: 54,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/profileplaceholder.png',
                      width: 54,
                      height: 54,
                    ),
                  )
                : Image.asset(
                    'assets/profileplaceholder.png',
                    width: 54,
                    height: 54,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.creativeName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.black),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onPressed: onViewProfile,
                        child: const Text(
                          'View profile',
                          style: TextStyle(color: Colors.black, fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: bookingOrange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onPressed: onChat,
                        child: const Text(
                          'Chat',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingProtectionBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3EC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_user_outlined,
            color: bookingOrange,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 11, color: Colors.grey[800]),
                children: const [
                  TextSpan(
                    text: 'Booking Protection\n',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),
                  TextSpan(
                    text:
                        'If your creative is unable to fulfil your booking, '
                        'Photobook will refund your payment or replace them '
                        'with an experienced professional. ',
                  ),
                  TextSpan(
                    text: 'Learn More here >',
                    style: TextStyle(
                      color: bookingOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> rows;

  const _SectionCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9F6),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: bookingOrange,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;

  const _DetailRow({required this.icon, required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: Colors.grey[600]),
          const SizedBox(width: 10),
          Expanded(
            child: value == null
                ? Text(label, style: const TextStyle(fontSize: 13))
                : Text('$label: $value', style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _PaymentTimeline extends StatelessWidget {
  final ClientBooking booking;

  const _PaymentTimeline({required this.booking});

  @override
  Widget build(BuildContext context) {
    Widget step(String title, String subtitle, {bool done = false}) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: bookingGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  done ? Icons.check : Icons.circle,
                  size: 13,
                  color: Colors.white,
                ),
              ),
              Container(
                width: 2,
                height: 26,
                color: bookingGreen.withValues(alpha: 0.4),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return _SectionCard(
      title: 'PAYMENT TIMELINE',
      rows: [
        step('Payment Received', booking.dateLabel, done: true),
        step(
          'Session Completed',
          '${booking.dateLabel} - ${booking.timeLabel}',
          done: booking.isCompleted,
        ),
        step(
          'Deliverables Sent',
          'Delivery Time: 3-5 days',
          done: booking.isCompleted,
        ),
        // Booking status chip
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              booking.isCancelled
                  ? Icons.cancel_outlined
                  : booking.isCompleted
                  ? Icons.task_alt
                  : Icons.hourglass_top,
              size: 17,
              color: booking.isCancelled ? Colors.red : bookingOrange,
            ),
            const SizedBox(width: 8),
            Text(
              'Booking status: ${booking.isCancelled
                  ? 'Cancelled'
                  : booking.isCompleted
                  ? 'Completed'
                  : booking.isAwaitingConfirmation
                  ? 'Awaiting Confirmation'
                  : 'Upcoming'}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: booking.isCancelled ? Colors.red : Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionPromptCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonLabel;
  final Color buttonColor;
  final VoidCallback onPressed;

  const _ActionPromptCard({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.buttonColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9F6),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: onPressed,
              child: Text(
                buttonLabel,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _OutcomeSecondary extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _OutcomeSecondary({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey[400]!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: onTap,
        child: Text(
          label,
          style: const TextStyle(color: Colors.black87, fontSize: 13),
        ),
      ),
    );
  }
}

class _NoShowSheet extends StatefulWidget {
  final ClientBooking booking;

  const _NoShowSheet({required this.booking});

  @override
  State<_NoShowSheet> createState() => _NoShowSheetState();
}

class _NoShowSheetState extends State<_NoShowSheet> {
  String? _reason = "The creative didn't show up";
  final _noteController = TextEditingController();

  static const _reasons = [
    "The creative didn't show up",
    'The creative cancelled at the last minute',
    "I couldn't reach the creative",
    'Something else',
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tell us what happened',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'We need to understand the situation to process your report '
              'and resolve it faster.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F9F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${booking.serviceType ?? 'Session'} • ${booking.dateLabel} • '
                '${booking.timeLabel} • ${booking.priceLabel}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            for (final reason in _reasons)
              RadioListTile<String>(
                dense: true,
                contentPadding: EdgeInsets.zero,
                activeColor: bookingOrange,
                title: Text(reason, style: const TextStyle(fontSize: 13)),
                value: reason,
                groupValue: _reason,
                onChanged: (v) => setState(() => _reason = v),
              ),
            const SizedBox(height: 4),
            TextField(
              controller: _noteController,
              maxLength: 500,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Add a note (Optional)',
                hintText: 'Tell us what happened...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context, {
                  'reason': _reason,
                  'note': _noteController.text,
                }),
                child: const Text(
                  'Submit Report',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ReviewSheet extends StatefulWidget {
  final String creativeName;
  final void Function(int stars, String comment) onSubmit;

  const _ReviewSheet({required this.creativeName, required this.onSubmit});

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  int _stars = 0;
  final _reviewController = TextEditingController();

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rate your experience with ${widget.creativeName}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return IconButton(
                    onPressed: () => setState(() => _stars = i + 1),
                    icon: Icon(
                      i < _stars ? Icons.star : Icons.star_border,
                      color: const Color(0xFFFFB020),
                      size: 38,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reviewController,
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: 'Write a review (optional)',
                  hintText:
                      'Share your experience with ${widget.creativeName}...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bookingOrange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (_stars == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a rating')),
                      );
                      return;
                    }
                    widget.onSubmit(_stars, _reviewController.text.trim());
                  },
                  child: const Text(
                    'Submit Rating',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
