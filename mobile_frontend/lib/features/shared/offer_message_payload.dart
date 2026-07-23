import 'dart:convert';

/// The rate card bubble is detected by a text prefix + plain lines.
/// We do the same for offers: a marker line, then a JSON blob with just
/// enough data to render the bubble and open the details screen without
/// another network round trip.
const String offerMessageMarker = '💼 *Custom Offer*';

class OfferMessagePayload {
  final String offerId;
  final num price;
  final String currencyCode;
  final String pricingMode; // 'fixed' | 'contact'
  final List<String> whatsIncluded;
  final DateTime? expiresAt; // drives the live countdown
  final String? validFor; // legacy label, kept for messages sent before expiresAt existed
  final String? note;

  OfferMessagePayload({
    required this.offerId,
    required this.price,
    required this.currencyCode,
    required this.pricingMode,
    required this.whatsIncluded,
    this.expiresAt,
    this.validFor,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'offerId': offerId,
        'price': price,
        'currencyCode': currencyCode,
        'pricingMode': pricingMode,
        'whatsIncluded': whatsIncluded,
        if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
        if (validFor != null) 'validFor': validFor,
        if (note != null) 'note': note,
      };

  /// Builds the full chat message content string to send.
  String encodeAsMessage() => '$offerMessageMarker\n${jsonEncode(toJson())}';

  static OfferMessagePayload? tryParse(String content) {
    if (!content.startsWith(offerMessageMarker)) return null;
    try {
      final jsonPart = content.substring(offerMessageMarker.length).trim();
      final data = jsonDecode(jsonPart) as Map<String, dynamic>;
      return OfferMessagePayload(
        offerId: data['offerId'],
        price: data['price'],
        currencyCode: data['currencyCode'] ?? 'NGN',
        pricingMode: data['pricingMode'] ?? 'fixed',
        whatsIncluded: List<String>.from(data['whatsIncluded'] ?? const []),
        expiresAt: data['expiresAt'] != null
            ? DateTime.tryParse(data['expiresAt'])
            : null,
        validFor: data['validFor'],
        note: data['note'],
      );
    } catch (_) {
      return null;
    }
  }

  /// Human-readable remaining time, e.g. "2d 3h left" / "45m left" /
  /// "Expired". Falls back to the legacy [validFor] label if there's no
  /// [expiresAt] on this payload (older messages).
  String? remainingLabel({DateTime? now}) {
    if (expiresAt == null) {
      return validFor == null ? null : 'Valid for $validFor';
    }
    final n = now ?? DateTime.now();
    final diff = expiresAt!.difference(n);
    if (diff.isNegative) return 'Expired';
    if (diff.inDays >= 1) {
      return '${diff.inDays}d ${diff.inHours % 24}h left';
    }
    if (diff.inHours >= 1) {
      return '${diff.inHours}h ${diff.inMinutes % 60}m left';
    }
    return '${diff.inMinutes}m left';
  }

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  String get formattedPrice {
    if (pricingMode == 'contact') return 'Contact for price';
    final s = price.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final posFromEnd = s.length - i;
      buf.write(s[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) buf.write(',');
    }
    return '₦$buf';
  }
}
