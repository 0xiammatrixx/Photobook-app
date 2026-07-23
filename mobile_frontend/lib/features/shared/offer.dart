class Offer {
  final String id;
  final String createdBy;
  final String sentTo;
  final String serviceName;
  final String? description;
  final num pricingAmount;
  final String currencyCode; // e.g. "NGN"
  final String pricingMode; // "fixed" | "contact"
  final List<String> categories;
  final List<String> whatsIncluded;
  final String? deliveryTime;
  final String? quantityLabel;
  final int? quantityMax;
  final String status; // "pending" | "accepted" | "declined" | "cancelled"
  final String? sessionId;
  final String? sessionDate;
  final String? sessionTime;
  final String? locationType; // "indoor" | "outdoor" etc
  final String? locationText;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? counterparty;
  final String? direction; // "sent" | "received"

  Offer({
    required this.id,
    required this.createdBy,
    required this.sentTo,
    required this.serviceName,
    this.description,
    required this.pricingAmount,
    required this.currencyCode,
    required this.pricingMode,
    required this.categories,
    required this.whatsIncluded,
    this.deliveryTime,
    this.quantityLabel,
    this.quantityMax,
    required this.status,
    this.sessionId,
    this.sessionDate,
    this.sessionTime,
    this.locationType,
    this.locationText,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    this.counterparty,
    this.direction,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    final id = json['id'] ?? json['_id'] ?? json['offerId'] ?? '';
    if (id == '') {
      // ignore: avoid_print
      print('Offer.fromJson: no id field found in: $json');
    }
    return Offer(
      id: id,
      createdBy: json['created_by'] ?? json['createdBy'] ?? '',
      sentTo: json['sent_to'] ?? json['sentTo'] ?? '',
      serviceName: json['service_name'] ?? '',
      description: json['description'],
      pricingAmount: _parseNum(json['pricing_amount']),
      currencyCode: json['currency_code'] ?? 'NGN',
      pricingMode: json['pricing_mode'] ?? 'fixed',
      categories: List<String>.from(json['categories'] ?? const []),
      whatsIncluded: List<String>.from(json['whats_included'] ?? const []),
      deliveryTime: json['delivery_time'],
      quantityLabel: json['quantity_label'],
      quantityMax: json['quantity_max'],
      status: json['status'] ?? 'pending',
      sessionId: json['session_id'],
      sessionDate: json['session_date'],
      sessionTime: json['session_time'],
      locationType: json['location_type'],
      locationText: json['location_text'],
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'])
          : null,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      counterparty: json['counterparty'] is Map<String, dynamic>
          ? json['counterparty']
          : null,
      direction: json['direction'],
    );
  }

  /// Formatted price like "₦450,000" — falls back to "Contact for price".
  String get formattedPrice {
    if (pricingMode == 'contact') return 'Contact for price';
    final s = pricingAmount.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final posFromEnd = s.length - i;
      buf.write(s[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) buf.write(',');
    }
    return '₦$buf';
  }
}

/// The API sometimes returns pricing_amount as a decimal string
/// (e.g. "500000.00") instead of a JSON number — handle both.
num _parseNum(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value;
  if (value is String) return num.tryParse(value) ?? 0;
  return 0;
}
