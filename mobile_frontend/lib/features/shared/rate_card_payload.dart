import 'dart:convert';

/// Embedded in chat messages when a creative sends their rate card.
/// Format: 📋 [RATECARD]{"items":[{"serviceName":"...","pricingAmount":"...","pricingMode":"..."}]}
class RateCardPayload {
  static const prefix = '📋 [RATECARD]';

  final List<RateCardItem> items;

  RateCardPayload({required this.items});

  Map<String, dynamic> toJson() => {
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory RateCardPayload.fromJson(Map<String, dynamic> json) {
    return RateCardPayload(
      items: (json['items'] as List)
          .map((i) => RateCardItem.fromJson(i))
          .toList(),
    );
  }

  /// Tries to parse a [RateCardPayload] from raw message [content].
  /// Returns null if the message doesn't contain a rate card payload.
  static RateCardPayload? tryParse(String content) {
    if (!content.startsWith(prefix)) return null;
    try {
      final jsonStr = content.substring(prefix.length);
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return RateCardPayload.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Builds a message string that embeds the payload.
  String toMessageString() {
    return '$prefix${jsonEncode(toJson())}';
  }

  /// Returns a human-readable preview for the bubble.
  String get previewText {
    final lines = items.map((item) {
      final name = item.serviceName;
      final price = item.pricingMode == 'contact'
          ? 'Contact for price'
          : '₦${item.pricingAmount}';
      return '• $name — $price';
    }).join('\n');
    return '📋 *My Rate Card*\n$lines';
  }
}

class RateCardItem {
  final String serviceName;
  final String? pricingAmount;
  final String? pricingMode;
  final List<String> whatsIncluded;
  final String description;
  final String deliveryTime;

  RateCardItem({
    required this.serviceName,
    this.pricingAmount,
    this.pricingMode,
    this.whatsIncluded = const [],
    this.description = '',
    this.deliveryTime = '',
  });

  Map<String, dynamic> toJson() => {
        'serviceName': serviceName,
        if (pricingAmount != null) 'pricingAmount': pricingAmount,
        if (pricingMode != null) 'pricingMode': pricingMode,
        if (whatsIncluded.isNotEmpty) 'whatsIncluded': whatsIncluded,
        if (description.isNotEmpty) 'description': description,
        if (deliveryTime.isNotEmpty) 'deliveryTime': deliveryTime,
      };

  factory RateCardItem.fromJson(Map<String, dynamic> json) {
    return RateCardItem(
      serviceName: json['serviceName'] ?? '',
      pricingAmount: json['pricingAmount']?.toString(),
      pricingMode: json['pricingMode']?.toString(),
      whatsIncluded: List<String>.from(json['whatsIncluded'] ?? []),
      description: json['description'] ?? '',
      deliveryTime: json['deliveryTime'] ?? '',
    );
  }
}
