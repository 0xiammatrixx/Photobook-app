import 'package:flutter/material.dart';
import 'package:mobile_frontend/providers/chat_provider.dart';
import 'package:mobile_frontend/providers/sessions_provider.dart';
import 'package:mobile_frontend/providers/user_provider.dart';
import 'package:mobile_frontend/services/booking_service.dart';
import 'package:mobile_frontend/features/shared/chat_conversation_screen.dart';
import 'package:provider/provider.dart';

const _orange = Color(0xFFFF7A33);
const _green = Color(0xFF047418);

/// Creative-side booking detail page. The action button and payment-progress
/// timeline are driven by the session's `status`, so they reflect what the
/// other party has confirmed on their end.
class CreativeBookingDetailPage extends StatefulWidget {
  final BookingSession session;

  const CreativeBookingDetailPage({super.key, required this.session});

  @override
  State<CreativeBookingDetailPage> createState() =>
      _CreativeBookingDetailPageState();
}

class _CreativeBookingDetailPageState
    extends State<CreativeBookingDetailPage> {
  bool _busy = false;

  BookingSession get session => widget.session;

  bool get _isCancelled {
    final s = session.status.toLowerCase();
    return s.contains('cancel') || s.contains('decline');
  }

  bool get _isCompleted {
    final s = session.status.toLowerCase();
    return s.contains('complete') || s.contains('deliver');
  }

  bool get _isDelivered {
    final s = session.status.toLowerCase();
    return s.contains('deliver') || s.contains('done') || s.contains('closed');
  }

  bool get _isAccepted {
    final s = session.status.toLowerCase();
    return s.contains('accept') || s.contains('confirm') || _isCompleted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Booking Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _clientHeader(),
            const SizedBox(height: 16),
            _section('Booking Details', _bookingDetails()),
            const SizedBox(height: 16),
            if (session.notes != null && session.notes!.isNotEmpty)
              _section('Client Request', _clientRequest()),
            const SizedBox(height: 16),
            _section('Payment Progress', _PaymentTimeline(status: session.status)),
            const SizedBox(height: 24),
            ..._buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _clientHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: _orange.withValues(alpha: 0.15),
          backgroundImage: session.clientAvatarUrl != null
              ? NetworkImage(session.clientAvatarUrl!)
              : null,
          child: session.clientAvatarUrl == null
              ? const Icon(Icons.person, color: _orange)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session.clientName,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Client',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: _startChat,
          icon: const Icon(Icons.chat_bubble_outline, size: 16),
          label: const Text('Chat'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _orange,
            side: const BorderSide(color: _orange),
          ),
        ),
      ],
    );
  }

  Widget _bookingDetails() {
    final date = session.scheduledAt;
    final dateStr =
        '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailRow(Icons.event_note_outlined, 'Event', session.notes ?? '—'),
        _detailRow(Icons.calendar_today_outlined, 'Date', dateStr),
        if (session.location != null && session.location!.isNotEmpty)
          _detailRow(Icons.location_on_outlined, 'Location', session.location!),
      ],
    );
  }

  Widget _clientRequest() {
    return Text(
      session.notes!,
      style: const TextStyle(fontSize: 13, height: 1.5),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
              color: Color(0xFF047418),
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  List<Widget> _buildActions() {
    if (_isCancelled) {
      return [
        Center(
          child: Text(
            'This booking was cancelled.',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ),
      ];
    }

    if (_isDelivered) {
      return [
        Center(
          child: Text(
            'Booking complete. Payout released.',
            style: const TextStyle(
              color: _green,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ];
    }

    if (_isCompleted) {
      // Session complete + client confirmed → next is deliverables.
      return [
        _primaryButton(
          label: 'Mark Deliverables As Sent',
          onPressed: _markDeliverablesSent,
        ),
      ];
    }

    if (_isAccepted) {
      // Accepted → next is mark complete.
      return [
        _primaryButton(
          label: 'Mark Session As Complete',
          onPressed: _markComplete,
        ),
      ];
    }

    // Pending → accept / decline / reschedule.
    return [
      _primaryButton(label: 'Accept Booking', onPressed: _showBeforeAccept),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: _secondaryButton(
              label: 'Decline Booking',
              color: Colors.red,
              onPressed: _declineSession,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _secondaryButton(
              label: 'Reschedule',
              color: Colors.black,
              onPressed: () => _comingSoon('Reschedule'),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _primaryButton({required String label, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _orange,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _busy ? null : onPressed,
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _secondaryButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.6)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }

  Future<void> _markComplete() async {
    final token = context.read<UserProvider>().token;
    if (token == null || session.id.isEmpty) return;
    setState(() => _busy = true);
    final success = await BookingService().completeSession(
      token: token,
      sessionId: session.id,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Session marked complete. Waiting for the client to confirm.'
              : 'Could not mark complete. Please try again.',
        ),
      ),
    );
    if (success) Navigator.pop(context, true);
  }

  Future<void> _runSessionAction(
    String successMessage,
    String failureMessage,
    Future<bool> Function(String token, String sessionId) action,
  ) async {
    final token = context.read<UserProvider>().token;
    if (token == null || session.id.isEmpty) return;
    setState(() => _busy = true);
    final success = await action(token, session.id);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? successMessage : failureMessage)),
    );
    if (success) Navigator.pop(context, true);
  }

  Future<void> _acceptSession() => _runSessionAction(
        'Booking accepted.',
        'Could not accept booking. Please try again.',
        (token, id) =>
            BookingService().acceptSession(token: token, sessionId: id),
      );

  Future<void> _declineSession() => _runSessionAction(
        'Booking declined.',
        'Could not decline booking. Please try again.',
        (token, id) =>
            BookingService().declineSession(token: token, sessionId: id),
      );

  Future<void> _markDeliverablesSent() => _runSessionAction(
        'Deliverables marked as sent.',
        'Could not mark deliverables. Please try again.',
        (token, id) => BookingService()
            .markDeliverablesSent(token: token, sessionId: id),
      );

  Future<void> _showBeforeAccept() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Before You Accept!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _beforeAcceptBullet(
                  'The client pays the full amount before the service.'),
              _beforeAcceptBullet(
                  'You confirm your availability for the event date and time.'),
              _beforeAcceptBullet(
                  'Your payout is released after the client confirms the session and deliverables.'),
              _beforeAcceptBullet(
                  'If the client no-shows, the funds stay protected in escrow.'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _acceptSession();
                  },
                  child: const Text(
                    'Accept Booking',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _beforeAcceptBullet(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('•  ',
                style: TextStyle(color: _orange, fontWeight: FontWeight.bold)),
            Expanded(
                child: Text(text, style: const TextStyle(fontSize: 13))),
          ],
        ),
      );

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature is coming soon')));
  }

  Future<void> _startChat() async {
    final token = context.read<UserProvider>().token;
    if (token == null || session.clientId.isEmpty) return;
    try {
      final result = await context.read<ChatProvider>().createConversation(
            token: token,
            participantId: session.clientId,
          );
      final conversationId = result['id'] ?? result['conversation']?['id'];
      if (conversationId != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatConversationScreen(
              conversationId: conversationId,
              recipientId: session.clientId,
              title: session.clientName,
              avatarUrl: session.clientAvatarUrl,
              isCreative: true,
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
}

/// Seven-step escrow timeline, driven by the session `status` string.
/// NOTE: needs the backend to expose per-step state; this is a best-effort
/// mapping until the session payload carries the step timestamps.
class _PaymentTimeline extends StatelessWidget {
  final String status;

  const _PaymentTimeline({required this.status});

  static const _steps = [
    'Payment Received',
    'Session Completed',
    'Client Confirms Session',
    '70% Released',
    'Deliverables Sent',
    'Client Confirms Deliverables',
    '30% Released',
  ];

  int get _completedCount {
    final s = status.toLowerCase();
    if (s.contains('cancel') || s.contains('decline')) return 0;
    if (s.contains('deliver') || s.contains('done') || s.contains('closed')) {
      return 7;
    }
    if (s.contains('complete')) return 2;
    if (s.contains('confirm') || s.contains('accept')) return 1;
    return 1; // payment received once a session exists
  }

  @override
  Widget build(BuildContext context) {
    final done = _completedCount;
    return Column(
      children: List.generate(_steps.length, (i) {
        final isDone = i < done;
        final isCurrent = i == done;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? _green
                      : isCurrent
                          ? _orange
                          : Colors.grey.shade300,
                ),
                child: isDone
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : isCurrent
                        ? const Icon(Icons.circle,
                            size: 10, color: Colors.white)
                        : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _steps[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isDone || isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isDone
                        ? Colors.black
                        : isCurrent
                            ? _orange
                            : Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
