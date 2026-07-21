import 'package:flutter/material.dart';
import 'package:mobile_frontend/features/shared/offer_message_payload.dart';
import 'package:mobile_frontend/services/offer_service.dart';

const _orange = Color(0xFFFF7A33);
const _green = Color(0xFF047418);

class OfferDetailsScreen extends StatefulWidget {
  final String token;
  final OfferMessagePayload payload;
  final String offeredByName;
  final String? offeredByAvatarUrl;

  const OfferDetailsScreen({
    super.key,
    required this.token,
    required this.payload,
    required this.offeredByName,
    this.offeredByAvatarUrl,
  });

  @override
  State<OfferDetailsScreen> createState() => _OfferDetailsScreenState();
}

class _OfferDetailsScreenState extends State<OfferDetailsScreen> {
  bool _declining = false;

  Future<void> _decline() async {
    setState(() => _declining = true);
    try {
      await OfferService().declineOffer(
        token: widget.token,
        id: widget.payload.offerId,
      );
      if (!mounted) return;
      // Let the chat screen know so it can swap this bubble to a
      // "declined" state.
      Navigator.pop(context, {
        'declined': true,
        'offerId': widget.payload.offerId,
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _declining = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  void _accept() {
    // Booking flow isn't wired up yet — intentionally a no-op for now.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Booking is coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.payload;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const CircleAvatar(
            backgroundColor: Color(0xFFF0F0F0),
            child: Icon(Icons.arrow_back, color: Colors.black, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Offer Details',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Offered by',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: widget.offeredByAvatarUrl != null
                        ? NetworkImage(widget.offeredByAvatarUrl!)
                        : null,
                    child: widget.offeredByAvatarUrl == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.offeredByName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Price',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(
                              p.formattedPrice,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (p.validFor != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Valid For',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text(
                                p.validFor!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const Divider(height: 28),
                    const Text(
                      "What's Included",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ...p.whatsIncluded.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: _green, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(item)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (p.note != null && p.note!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDECE1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NOTE FROM PHOTOGRAPHER',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(p.note!, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _declining ? null : _decline,
                  icon: _declining
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.close, color: Colors.red),
                  label: const Text(
                    'Decline Offer',
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _accept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Accept and Book Session',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
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
