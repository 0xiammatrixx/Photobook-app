import 'package:flutter/material.dart';
import 'package:mobile_frontend/features/shared/offer_details_screen.dart';
import 'package:mobile_frontend/features/shared/offer_message_payload.dart';

/// Same layout language as `_RateCardBubble`: an icon, a bold title, then
/// plain lines underneath. Wrapped in a tap target that opens the
/// acceptance/decline screen. When [isDeclined] is true it renders as a
/// muted, struck-through "Offer Declined" version of itself instead.
class OfferBubble extends StatelessWidget {
  final OfferMessagePayload payload;
  final bool isDeclined;
  final String token;
  final String counterpartyName;
  final String? counterpartyAvatarUrl;
  final void Function(String offerId) onDeclined;

  const OfferBubble({
    super.key,
    required this.payload,
    required this.isDeclined,
    required this.token,
    required this.counterpartyName,
    required this.onDeclined,
    this.counterpartyAvatarUrl,
  });

  Future<void> _open(BuildContext context) async {
    if (isDeclined) return;
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => OfferDetailsScreen(
          token: token,
          payload: payload,
          offeredByName: counterpartyName,
          offeredByAvatarUrl: counterpartyAvatarUrl,
        ),
      ),
    );
    if (result != null && result['declined'] == true) {
      onDeclined(result['offerId'] as String);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _open(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isDeclined ? '🚫' : '💼', style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDeclined ? 'Offer Declined' : 'Custom Offer',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDeclined ? Colors.grey : Colors.black,
                    decoration:
                        isDeclined ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  payload.formattedPrice +
                      (payload.validFor != null
                          ? ' · Valid for ${payload.validFor}'
                          : ''),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDeclined ? Colors.grey : Colors.black87,
                    decoration:
                        isDeclined ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (!isDeclined) ...[
                  const SizedBox(height: 4),
                  ...payload.whatsIncluded.map(
                    (item) => Text(
                      '• $item',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap to view offer',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
