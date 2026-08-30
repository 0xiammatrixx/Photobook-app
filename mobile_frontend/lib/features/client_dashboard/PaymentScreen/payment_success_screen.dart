import 'package:flutter/material.dart';
import 'package:mobile_frontend/features/client_dashboard/bottom_nav_bar.dart';

const _orange = Color(0xFFFF7A33);
const _green = Color(0xFF047418);

class PaymentSuccessScreen extends StatelessWidget {
  final String serviceType;
  final String creativeName;
  final String dateLabel;
  final String timeLabel;
  final String amountLabel;
  final String paymentMethod;

  const PaymentSuccessScreen({
    super.key,
    required this.serviceType,
    required this.creativeName,
    required this.dateLabel,
    required this.timeLabel,
    required this.amountLabel,
    this.paymentMethod = 'Card Payment',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: _green, size: 64),
              ),
              const SizedBox(height: 16),
              const Text(
                'Payment Successful!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                "Your booking has been confirmed. We've sent the details to your email.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F9F6),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    _row('Service', serviceType),
                    _row('Creative', creativeName),
                    _row('Date', dateLabel),
                    _row('Time', timeLabel),
                    _row('Amount Paid', amountLabel),
                    _row('Payment Method', paymentMethod),
                  ],
                ),
              ),
              const Spacer(),
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
                    BottomTabs.tabIndex.value = 1; // Bookings tab
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                  child: const Text(
                    'View In Bookings',
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
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            Flexible(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      );
}
