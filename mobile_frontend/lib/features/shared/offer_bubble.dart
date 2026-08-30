import 'package:flutter/material.dart';
import 'package:mobile_frontend/features/shared/offer_details_screen.dart';
import 'package:mobile_frontend/features/shared/offer_message_payload.dart';
import 'package:mobile_frontend/features/shared/send_custom_offer_screen.dart';

const _green = Color(0xFF047418);

/// Same layout language as `_RateCardBubble`: an icon, a bold title, then
/// plain lines underneath.
///
/// - Recipient (client) view: tapping opens the acceptance/decline screen.
/// - Sender (creative, [isMe]) view: no accept/decline — instead shows an
///   "Edit Offer" button that reopens the custom-offer form pre-filled,
///   so they can send an updated offer for the same negotiation.
///
/// [resolvedStatus] should be the *actual backend* offer status
/// ('pending' | 'declined' | 'cancelled' | 'accepted' | null if not yet
/// loaded) — not just something remembered locally, since local-only
/// state disappears the moment the screen is rebuilt (app restart, next
/// day, etc.) while the backend still correctly remembers it. Pass
/// [isLocallyEdited] true only when *this session* is the one that just
/// cancelled this specific offer via the edit flow, purely so the label
/// can say "Offer Updated" instead of a bare "Offer Cancelled".
class OfferBubble extends StatelessWidget {
  final OfferMessagePayload payload;
  final bool isMe;
  final String? resolvedStatus;
  final bool isLocallyEdited;
  final String token;
  final String conversationId;
  final String recipientId;
  final String counterpartyName;
  final String? counterpartyAvatarUrl;
  final void Function(String offerId) onDeclined;
  final void Function(String oldOfferId) onEdited;

  const OfferBubble({
    super.key,
    required this.payload,
    required this.isMe,
    required this.resolvedStatus,
    required this.isLocallyEdited,
    required this.token,
    required this.conversationId,
    required this.recipientId,
    required this.counterpartyName,
    required this.onDeclined,
    required this.onEdited,
    this.counterpartyAvatarUrl,
  });

  bool get _isClosed =>
      resolvedStatus == 'declined' ||
      resolvedStatus == 'cancelled' ||
      resolvedStatus == 'accepted';

  Future<void> _openDetails(BuildContext context) async {
    if (_isClosed) return;
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => OfferDetailsScreen(
          token: token,
          payload: payload,
          offeredByName: counterpartyName,
          offeredByAvatarUrl: counterpartyAvatarUrl,
          offeredById: recipientId,
        ),
      ),
    );
    if (result != null && result['declined'] == true) {
      onDeclined(result['offerId'] as String);
    }
  }

  Future<void> _openEdit(BuildContext context) async {
    if (_isClosed) return;
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => SendCustomOfferScreen(
          token: token,
          conversationId: conversationId,
          recipientId: recipientId,
          recipientName: counterpartyName,
          editingOfferId: payload.offerId,
          initialPrice: payload.price,
          initialWhatsIncluded: payload.whatsIncluded,
          initialNote: payload.note,
          initialValidFor: payload.validFor,
        ),
      ),
    );
    if (result != null && result['editedOfferId'] != null) {
      onEdited(result['editedOfferId'] as String);
    }
  }

  String get _title {
    switch (resolvedStatus) {
      case 'declined':
        return 'Offer Declined';
      case 'cancelled':
        return isLocallyEdited ? 'Offer Updated' : 'Offer Cancelled';
      case 'accepted':
        return 'Offer Accepted';
      default:
        return 'Custom Offer';
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: (_isClosed || isMe) ? null : () => _openDetails(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_isClosed ? '🚫' : '💼', style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _isClosed ? Colors.grey : Colors.black,
                    decoration:
                        _isClosed ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  payload.formattedPrice +
                      (payload.remainingLabel() != null
                          ? ' · ${payload.remainingLabel()}'
                          : ''),
                  style: TextStyle(
                    fontSize: 12,
                    color: _isClosed ? Colors.grey : Colors.black87,
                    decoration:
                        _isClosed ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (!_isClosed) ...[
                  const SizedBox(height: 4),
                  ...payload.whatsIncluded.map(
                    (item) => Text(
                      '• $item',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isMe)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton(
                        onPressed: () => _openEdit(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _green),
                          foregroundColor: _green,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Edit Offer',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    )
                  else
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