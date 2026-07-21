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
    required this.createdAt,
    required this.updatedAt,
    this.counterparty,
    this.direction,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['id'] ?? '',
      createdBy: json['created_by'] ?? '',
      sentTo: json['sent_to'] ?? '',
      serviceName: json['service_name'] ?? '',
      description: json['description'],
      pricingAmount: json['pricing_amount'] ?? 0,
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
