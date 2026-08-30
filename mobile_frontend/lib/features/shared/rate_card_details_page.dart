import 'package:flutter/material.dart';
import 'package:mobile_frontend/features/shared/rate_card_payload.dart';

class RateCardDetailsPage extends StatelessWidget {
  final RateCardPayload? payload;
  final List<String> fallbackItems;

  const RateCardDetailsPage({
    super.key,
    this.payload,
    this.fallbackItems = const [],
  });

  @override
  Widget build(BuildContext context) {
    final hasStructured = payload != null && payload!.items.isNotEmpty;

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
          'Rate Card',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F9F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF047418), width: 0.8),
              ),
              child: Row(
                children: [
                  const Text('📋', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'My Rate Card',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (hasStructured)
              ...payload!.items.map((item) => _RateCardItemTile(item: item))
            else
              ...fallbackItems.map((line) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF7A33),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            line.replaceFirst('• ', ''),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _RateCardItemTile extends StatelessWidget {
  final RateCardItem item;
  const _RateCardItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final priceText = item.pricingMode == 'contact'
        ? 'Contact for price'
        : '₦${item.pricingAmount ?? '0'}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + price row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.serviceName,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF047418).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  priceText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF047418),
                  ),
                ),
              ),
            ],
          ),
          // Description
          if (item.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.description,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
          // What's Included
          if (item.whatsIncluded.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              "What's Included",
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87),
            ),
            const SizedBox(height: 4),
            ...item.whatsIncluded.map(
              (inc) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle,
                        size: 14, color: Color(0xFF047418)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(inc,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54)),
                    ),
                  ],
                ),
              ),
            ),
          ],
          // Delivery time
          if (item.deliveryTime.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time,
                    size: 14, color: Colors.black54),
                const SizedBox(width: 4),
                Text(
                  item.deliveryTime,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
