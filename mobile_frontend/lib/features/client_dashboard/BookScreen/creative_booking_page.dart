import 'package:flutter/cupertino.dart' show CupertinoPicker;
import 'package:flutter/material.dart';
import 'package:mobile_frontend/features/client_dashboard/PaymentScreen/payment_success_screen.dart';
import 'package:mobile_frontend/features/shared/offer_message_payload.dart';
import 'package:mobile_frontend/providers/booking_provider.dart';
import 'package:mobile_frontend/providers/user_provider.dart';
import 'package:mobile_frontend/services/booking_service.dart';
import 'package:mobile_frontend/services/offer_service.dart';
import 'package:mobile_frontend/services/payment_service.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';

const _orange = Color(0xFFFF7A33);

/// Role-specific booking form configuration.
class _RoleConfig {
  final String typeFieldLabel; // "Event Type" or "Content Type"
  final List<String> typeOptions;
  final bool hasOutfits;
  final bool hasShootingLocations;
  final bool hasDeliverables;
  final List<String>? deliverableOptions;
  final bool hasRemoteOption;

  const _RoleConfig({
    required this.typeFieldLabel,
    required this.typeOptions,
    this.hasOutfits = false,
    this.hasShootingLocations = false,
    this.hasDeliverables = false,
    this.deliverableOptions,
    this.hasRemoteOption = false,
  });
}

const _roleConfigs = <String, _RoleConfig>{
  'photographer': _RoleConfig(
    typeFieldLabel: 'Event Type',
    typeOptions: [
      'Event', 'Fashion', 'Photo Coverage', 'Portrait', 'Wedding',
      'Street Photography',
    ],
    hasOutfits: true,
  ),
  'videographer': _RoleConfig(
    typeFieldLabel: 'Event Type',
    typeOptions: ['Event', 'Fashion', 'Video Coverage', 'Wedding'],
    hasShootingLocations: true,
    hasDeliverables: true,
    deliverableOptions: [
      'Highlight Video', 'Full Coverage', 'Social Media Reel', 'Documentary',
    ],
  ),
  'content_creator': _RoleConfig(
    typeFieldLabel: 'Content Type',
    typeOptions: [
      'Behind-the-scenes content', 'Event highlights', 'Instagram reels',
      'Social media content', 'Same-day content', 'Short-form content',
      'Photo & video coverage',
    ],
    hasOutfits: true,
    hasRemoteOption: true,
  ),
};

class BookingPage extends StatefulWidget {
  final String creativeId;
  final String name;
  final String avatarUrl;
  final double rating;

  /// Creative's roles, e.g. ['photographer'] or multiple.
  final List<String> roles;

  /// Custom offer mode — price locked, type field greyed out.
  final OfferMessagePayload? offer;

  const BookingPage({
    super.key,
    required this.creativeId,
    required this.name,
    required this.avatarUrl,
    required this.rating,
    this.roles = const ['photographer'],
    this.offer,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();

  /// Derive booking roles from the creative's profile tags.
  /// Falls back to photographer when no recognized tags exist.
  static List<String> rolesFromTags(List<String> tags) {
    const known = {'photographer', 'videographer', 'content_creator'};
    final roles = tags
        .map((t) => t.toLowerCase())
        .where(known.contains)
        .toList();
    return roles.isEmpty ? const ['photographer'] : roles;
  }
}

class _BookingPageState extends State<BookingPage> with WidgetsBindingObserver {
  bool showCalendar = false;
  bool _submitting = false;
  bool _manualAddress = false;
  bool _searchingAddress = false;
  List<Map<String, dynamic>> _addressSuggestions = [];
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();
  final TextEditingController _outfitsCtrl = TextEditingController();
  final TextEditingController _locationsCtrl = TextEditingController();

  List<Map<String, dynamic>> _packages = [];
  List<Map<String, dynamic>> _eventTypes = [];
  bool _loadingPackages = false;
  late String _role;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // Pending payment state — set when Paystack opens, cleared after verify.
  String? _pendingReference;
  String? _pendingToken;
  double _pendingAmount = 0;
  String? _pendingServiceType;
  String? _pendingDateLabel;
  String? _pendingTimeLabel;

  _RoleConfig get _config => _roleConfigs[_role] ?? _roleConfigs['photographer']!;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final b = context.read<BookingProvider>();
    b.booking.creativeId = widget.creativeId;
    _role = widget.roles.first;

    // Defer provider mutations that call notifyListeners() until after the
    // first frame — calling them in initState marks widgets dirty mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      b.setRole(_role);
      if (widget.offer != null) {
        b.loadFromOffer(
          creativeId: widget.creativeId,
          price: widget.offer!.price.toDouble(),
          priceLabel: widget.offer!.formattedPrice,
          offerId: widget.offer!.offerId,
          note: widget.offer!.note,
        );
        _noteCtrl.text = widget.offer!.note ?? '';
      }
      _loadEventTypes();
      _loadPackages();
    });
  }

  Future<void> _loadPackages() async {
    setState(() => _loadingPackages = true);
    try {
      final list = await BookingService()
          .getPublicRateCard(photographerId: widget.creativeId);
      if (mounted) {
        setState(() => _packages = List<Map<String, dynamic>>.from(list));
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingPackages = false);
    }
  }

  Future<void> _loadEventTypes() async {
    final token = context.read<UserProvider>().token;
    if (token == null) return;
    try {
      final list = await BookingService().getEventTypes(token: token);
      if (mounted) {
        setState(() {
          _eventTypes = list
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        });
      }
    } catch (_) {}
  }

  List<String> get _eventTypeOptions {
    if (_eventTypes.isEmpty) return _config.typeOptions;
    return _eventTypes
        .map((e) => (e['display_name'] ?? e['displayName'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  void _onEventTypeSelected(String? v) {
    if (v == null) return;
    context.read<BookingProvider>().setEventType(v);
    for (final e in _eventTypes) {
      final name = (e['display_name'] ?? e['displayName'] ?? '').toString();
      if (name == v && e['id'] != null) {
        context
            .read<BookingProvider>()
            .setEventTypeId(int.tryParse(e['id'].toString()));
        break;
      }
    }
  }

  String _formatMoney(dynamic amount) {
    final n = double.tryParse(amount.toString()) ?? 0;
    if (n >= 1000000) return '₦${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '₦${(n / 1000).toStringAsFixed(0)}k';
    return '₦${n.toStringAsFixed(0)}';
  }

  /// Read the chargeable amount from a create-session response, preferring the
  /// backend's `agreed_amount` (which POST /api/payments/initiate validates
  /// against and charges).
  double? _sessionAmount(Map<String, dynamic> session) {
    for (final key in [
      'agreed_amount', 'amount', 'price', 'total_amount', 'total_price',
      'pricing_amount',
    ]) {
      final v = session[key];
      if (v != null) {
        final n = double.tryParse(v.toString());
        if (n != null && n > 0) return n;
      }
    }
    return null;
  }

  String _packageLabel(Map<String, dynamic> p) {
    final name = (p['service_name'] ?? p['serviceName'] ?? 'Package');
    final price = p['pricing_amount'] ?? p['pricingAmount'];
    final mode = (p['pricing_mode'] ?? p['pricingMode'] ?? 'fixed').toString();
    final priceText = mode == 'contact' ? 'Contact' : _formatMoney(price);
    return '$name — $priceText';
  }

  Future<void> _pickTimeRange() async {
    final start = await _pickTime('Start Time', widget.offer == null ? null : null);
    if (start == null || !mounted) return;
    final end = await _pickTime('End Time', start);
    if (end == null || !mounted) return;
    context.read<BookingProvider>().setTimeRange(start, end);
  }

  Future<String?> _pickTime(String title, String? after) {
    return showModalBottomSheet<String>(
      context: context,
      builder: (ctx) {
        int hour = after != null ? int.parse(after.split(':')[0]) : 9;
        int minute = after != null ? int.parse(after.split(':')[1]) : 0;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 160,
                    child: Row(
                      children: [
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                                initialItem: hour),
                            itemExtent: 32,
                            onSelectedItemChanged: (v) => hour = v,
                            children: List.generate(
                              24,
                              (i) => Center(
                                  child: Text('${i.toString().padLeft(2, '0')}')),
                            ),
                          ),
                        ),
                        const Text(':'),
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                                initialItem: minute ~/ 5),
                            itemExtent: 32,
                            onSelectedItemChanged: (v) => minute = v * 5,
                            children: List.generate(
                              12,
                              (i) => Center(
                                  child: Text('${(i * 5).toString().padLeft(2, '0')}')),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.pop(
                        ctx,
                        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                      ),
                      child: const Text('Done',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _onAddressChanged(String q) async {
    if (q.trim().length < 3) {
      setState(() => _addressSuggestions = []);
      return;
    }
    setState(() => _searchingAddress = true);
    final results = await BookingService().searchAddress(q);
    if (mounted) {
      setState(() {
        _addressSuggestions = results;
        _searchingAddress = false;
      });
    }
  }

  Future<void> _submit() async {
    final booking = context.read<BookingProvider>().booking;
    final token = context.read<UserProvider>().token;
    if (token == null) return;

    if (!booking.isFromOffer && booking.eventType == null) {
      _snack('Please select ${_config.typeFieldLabel}');
      return;
    }
    if (booking.package == null) {
      _snack('Please select a package');
      return;
    }
    if (booking.date == null || booking.timeStart == null || booking.timeEnd == null) {
      _snack('Please select date and time range');
      return;
    }
    if (booking.locationType == null) {
      _snack('Please select location type');
      return;
    }
    if (!booking.useStudioLocation &&
        (booking.location == null || booking.location!.isEmpty)) {
      _snack('Please enter the location');
      return;
    }

    setState(() => _submitting = true);
    try {
      final sessionDate =
          '${booking.date!.year}-${booking.date!.month.toString().padLeft(2, '0')}-${booking.date!.day.toString().padLeft(2, '0')}';
      final locationText = booking.useStudioLocation
          ? "Creative's studio"
          : booking.location!;

      final session = await BookingService().createSession(
        token: token,
        photographerId: widget.creativeId,
        creativeType: booking.role ?? 'photographer',
        eventTypeId: booking.eventTypeId ?? 1, // TODO: backend add type->id map
        rateCardItemId: booking.rateCardItemId ?? '',
        sessionDate: sessionDate,
        sessionTime: booking.timeStart!,
        sessionEndTime: booking.timeEnd ?? booking.timeStart!,
        locationType: booking.locationType!.toLowerCase().replaceAll(' ', '_'),
        locationText: locationText,
        useCreativeStudio: booking.useStudioLocation,
        numberOfOutfits: booking.numberOfOutfits,
        numberOfShootingLocations: booking.numberOfShootingLocations,
        deliverableType: booking.deliverableType,
        notes: booking.note,
      );

      if (session == null) {
        if (mounted) _snack('Failed to book. Try again.');
        return;
      }

      // Custom offer: accepting also marks the offer accepted server-side.
      if (booking.isFromOffer && booking.offerId != null) {
        try {
          await OfferService().acceptOffer(token: token, id: booking.offerId!);
        } catch (e) {
          print('⚠️ Offer accept failed (session created): $e');
        }
      }

      if (!mounted) return;

      final sessionId = (session['id'] ??
              session['session_id'] ??
              session['sessionId'] ??
              session['session']?['id'] ??
              session['data']?['id'])
          ?.toString();
      // Prefer the session's agreed amount (what the backend charges) over the
      // rate-card price — POST /api/payments/initiate validates `amount`
      // against the session's agreed amount and never trusts the client value.
      final amount = _sessionAmount(session) ?? booking.packagePrice;

      if (sessionId != null && sessionId.isNotEmpty && amount != null && amount > 0) {
        await _startPaymentFlow(token, sessionId, amount);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Booking request sent!')),
        );
        context.read<BookingProvider>().reset();
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) _snack('❌ Failed to book: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _startPaymentFlow(
    String token,
    String sessionId,
    double amount,
  ) async {
    final proceed = await _showBeforeYouPaySheet();
    if (!proceed || !mounted) return;

    setState(() => _submitting = true);
    try {
      final init = await PaymentService().initiatePayment(
        token: token,
        sessionId: sessionId,
        amount: amount,
      );
      final url = init?['paystackAuthorizationUrl'] ??
          init?['authorization_url'] ??
          init?['data']?['authorization_url'];
      final reference = (init?['reference'] ?? '').toString();

      if (url == null || reference.isEmpty) {
        if (mounted) _snack('Could not start payment. Try again.');
        return;
      }

      // Capture everything needed to show the success screen later, since the
      // booking gets reset once payment is confirmed.
      final booking = context.read<BookingProvider>().booking;
      _pendingToken = token;
      _pendingAmount = amount;
      _pendingReference = reference;
      _pendingServiceType = booking.eventType ?? booking.package ?? 'Session';
      _pendingDateLabel = booking.date == null
          ? ''
          : '${booking.date!.year}-${booking.date!.month.toString().padLeft(2, '0')}-${booking.date!.day.toString().padLeft(2, '0')}';
      _pendingTimeLabel =
          '${booking.timeStart ?? ''} - ${booking.timeEnd ?? ''}';

      final launchOk = await launchUrl(
        Uri.parse(url.toString()),
        mode: LaunchMode.externalApplication,
      );
      if (!launchOk) {
        _clearPendingPayment();
        if (mounted) _snack('Could not open the payment page.');
        return;
      }
      // Do NOT verify here — the user is still completing payment in the
      // external browser. Verification happens on app resume, via
      // didChangeAppLifecycleState.
    } catch (e) {
      _clearPendingPayment();
      if (mounted) _snack('Payment failed: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the app returns from the Paystack browser, verify the payment.
    if (state == AppLifecycleState.resumed && _pendingReference != null) {
      _verifyAndHandlePayment();
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

      final serviceType = _pendingServiceType ?? 'Session';
      final dateLabel = _pendingDateLabel ?? '';
      final timeLabel = _pendingTimeLabel ?? '';
      final amount = _pendingAmount;

      _clearPendingPayment();

      if (!mounted) return;
      if (confirmed) {
        context.read<BookingProvider>().reset();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentSuccessScreen(
              serviceType: serviceType,
              creativeName: widget.name,
              dateLabel: dateLabel,
              timeLabel: timeLabel,
              amountLabel: _formatMoney(amount),
            ),
          ),
        );
      } else {
        _snack('Payment not confirmed yet — you can retry from your bookings.');
      }
    } catch (e) {
      _clearPendingPayment();
      if (mounted) _snack('Payment verification failed: $e');
    }
  }

  void _clearPendingPayment() {
    _pendingReference = null;
    _pendingToken = null;
    _pendingAmount = 0;
    _pendingServiceType = null;
    _pendingDateLabel = null;
    _pendingTimeLabel = null;
  }

  Future<bool> _showBeforeYouPaySheet() async {
    final proceed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Before You Pay',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Please review how payments work on PhotoBook',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              _bullet('You pay the full booking amount today.'),
              _bullet('PhotoBook securely holds your payment.'),
              _bullet(
                'Your creative receives payment after your session is completed.',
              ),
              _bullet(
                "If your creative doesn't show up, you'll receive a full refund.",
              ),
              const SizedBox(height: 20),
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
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text(
                    'Proceed to Payment',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return proceed ?? false;
  }

  Widget _bullet(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '•  ',
              style: TextStyle(color: _orange, fontWeight: FontWeight.bold),
            ),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
          ],
        ),
      );

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _addressCtrl.dispose();
    _noteCtrl.dispose();
    _outfitsCtrl.dispose();
    _locationsCtrl.dispose();
    super.dispose();
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
          'Book a Session',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Creative info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: widget.avatarUrl.isNotEmpty
                      ? Image.network(widget.avatarUrl,
                          width: 90, height: 90, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.asset(
                              'assets/profileplaceholder.png',
                              width: 90, height: 90, fit: BoxFit.cover))
                      : Image.asset('assets/profileplaceholder.png',
                          width: 90, height: 90, fit: BoxFit.cover),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < widget.rating.round()
                              ? Icons.star
                              : Icons.star_border,
                          size: 16,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                    Text(
                      booking.isFromOffer
                          ? 'From custom offer'
                          : 'Book a session',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Role selector (multi-role creatives) ──
            if (widget.roles.length > 1) ...[
              const Text('I want to book:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: widget.roles.map((r) {
                  final label = r == 'content_creator'
                      ? 'Content Creator'
                      : r[0].toUpperCase() + r.substring(1);
                  return ChoiceChip(
                    label: Text(label),
                    selected: _role == r,
                    onSelected: (_) {
                      setState(() => _role = r);
                      context.read<BookingProvider>().setRole(r);
                    },
                    selectedColor: _orange.withOpacity(0.2),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // ── Offer price banner ──
            if (booking.isFromOffer && booking.offerPriceLabel != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F9F6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF047418)),
                ),
                child: Text(
                  'Agreed price: ${booking.offerPriceLabel}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Event / Content type ──
            _dropdown(
              title: _config.typeFieldLabel,
              value: booking.isFromOffer
                  ? 'Agreed in offer'
                  : booking.eventType,
              enabled: !booking.isFromOffer,
              items: booking.isFromOffer
                  ? ['Agreed in offer']
                  : _eventTypeOptions,
              onChange: booking.isFromOffer
                  ? null
                  : _onEventTypeSelected,
            ),

            // ── Package (from rate card) ──
            _dropdown(
              title: 'Package',
              value: booking.package,
              items: _loadingPackages
                  ? ['Loading packages...']
                  : _packages.isEmpty
                      ? ['No packages available']
                      : _packages.map(_packageLabel).toList(),
              onChange: (v) {
                if (v == null || _packages.isEmpty) return;
                final idx = _packages.indexWhere((p) => _packageLabel(p) == v);
                if (idx != -1) {
                  final p = _packages[idx];
                  context.read<BookingProvider>().setPackage(v);
                  context.read<BookingProvider>().setRateCardItemId(
                      (p['id'] ?? p['_id'] ?? '').toString());
                  context.read<BookingProvider>().setPackagePrice(
                      double.tryParse((p['pricing_amount'] ??
                              p['pricingAmount'] ??
                              '0')
                          .toString()));
                }
              },
            ),
            if (booking.packagePrice != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Package price: ${_formatMoney(booking.packagePrice)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),

            // ── Date ──
            GestureDetector(
              onTap: () => setState(() => showCalendar = !showCalendar),
              child: _dropdownDisplay(
                title: 'Date',
                value: booking.date == null
                    ? 'DD / MM / YYYY'
                    : '${booking.date!.day}/${booking.date!.month}/${booking.date!.year}',
              ),
            ),
            if (showCalendar) _calendar(),

            // ── Time range ──
            const Text('Time',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickTimeRange,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      booking.timeStart == null || booking.timeEnd == null
                          ? 'Select time range'
                          : '${booking.timeStart} — ${booking.timeEnd}',
                      style: TextStyle(
                        color: booking.timeStart == null
                            ? Colors.grey
                            : Colors.black,
                      ),
                    ),
                    const Icon(Icons.schedule, size: 18, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Location type ──
            _dropdown(
              title: 'Location Type',
              value: booking.locationType,
              items: _config.hasRemoteOption
                  ? ['Indoor', 'Outdoor', 'Remote']
                  : ['Indoor', 'Outdoor'],
              onChange: (v) =>
                  context.read<BookingProvider>().setLocationType(v ?? ''),
            ),

            // ── Location with autocomplete ──
            const Text('Location',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            if (!booking.useStudioLocation) ...[
              TextField(
                controller: _addressCtrl,
                onChanged: _onAddressChanged,
                decoration: InputDecoration(
                  hintText: _manualAddress
                      ? 'Type address manually'
                      : 'Type an address...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: _orange),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: _searchingAddress
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                ),
              ),
              if (_addressSuggestions.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      ..._addressSuggestions.map((s) => ListTile(
                            dense: true,
                            title: Text(
                              s['display_name']?.toString() ?? '',
                              style: const TextStyle(fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              final full = s['display_name']?.toString() ?? '';
                              _addressCtrl.text = full;
                              context
                                  .read<BookingProvider>()
                                  .setLocation(full);
                              setState(() => _addressSuggestions = []);
                            },
                          )),
                      // Manual fallback option
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.edit, size: 18),
                        title: Text(
                          'No match? Enter "$_addressCtrlValue" manually',
                          style: const TextStyle(
                              fontSize: 13, color: _orange),
                        ),
                        onTap: () {
                          context.read<BookingProvider>().setLocation(
                              _addressCtrl.text.trim());
                          setState(() {
                            _manualAddress = true;
                            _addressSuggestions = [];
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
            CheckboxListTile(
              value: booking.useStudioLocation,
              onChanged: (v) {
                context
                    .read<BookingProvider>()
                    .setUseStudioLocation(v ?? false);
                setState(() {});
              },
              title: const Text(
                "Use creative's studio/location",
                style: TextStyle(fontSize: 13),
              ),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),

            // ── Role-specific fields ──
            if (_config.hasOutfits) ...[
              _numberField(
                controller: _outfitsCtrl,
                label: 'Number of Outfits',
                onChanged: (v) => context
                    .read<BookingProvider>()
                    .setNumberOfOutfits(int.tryParse(v)),
              ),
              const SizedBox(height: 16),
            ],
            if (_config.hasShootingLocations) ...[
              _numberField(
                controller: _locationsCtrl,
                label: 'Number of Shooting Locations',
                onChanged: (v) => context
                    .read<BookingProvider>()
                    .setNumberOfShootingLocations(int.tryParse(v)),
              ),
              const SizedBox(height: 16),
            ],
            if (_config.hasDeliverables)
              _dropdown(
                title: 'Deliverable Type',
                value: booking.deliverableType,
                items: _config.deliverableOptions ?? [],
                onChange: (v) => context
                    .read<BookingProvider>()
                    .setDeliverableType(v),
              ),

            // ── Note ──
            const Text('Add Note',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            SizedBox(
              height: 120,
              child: TextField(
                controller: _noteCtrl,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                onChanged: (v) =>
                    context.read<BookingProvider>().setNote(v),
                decoration: InputDecoration(
                  hintText: 'Anything the creative should know...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: _orange),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ),
            const SizedBox(height: 60),

            // ── Book button ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
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
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Book Session',
                        style:
                            TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _addressCtrlValue => _addressCtrl.text.trim();

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Enter number',
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: _orange),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dropdown({
    required String title,
    required String? value,
    required List<String> items,
    required Function(String?)? onChange,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : null,
              hint: const Text('Select'),
              isExpanded: true,
              items: items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: enabled ? onChange : null,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _dropdownDisplay({required String title, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
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
        onFormatChanged: (format) => setState(() => _calendarFormat = format),
        onDaySelected: (selected, _) {
          context.read<BookingProvider>().setDate(selected);
          setState(() => showCalendar = false);
        },
      ),
    );
  }
}
