import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        'icon': Icons.check_circle_outline,
        'color': Color(0xFF047418),
        'title': 'Booking Confirmed',
        'body': 'Your booking with Timmon Photography has been confirmed for October 13 at 3:00 PM.',
        'time': '5 mins ago',
      },
      {
        'icon': Icons.payments_outlined,
        'color': Color(0xFF047418),
        'title': 'Payment Successful',
        'body': 'Your payment of ₦450,000 has been received and your booking is confirmed.',
        'time': '1 day ago',
      },
      {
        'icon': Icons.chat_bubble_outline,
        'color': Color(0xFFFF7A33),
        'title': 'New Message',
        'body': 'Timmon Photography sent you a new message.',
        'time': '1 day ago',
      },
      {
        'icon': Icons.alarm,
        'color': Color(0xFFFF7A33),
        'title': 'Booking Reminder',
        'body': 'Your session with Timmon Photography starts in 2 hours.',
        'time': '1 day ago',
      },
      {
        'icon': Icons.account_balance_wallet_outlined,
        'color': Color(0xFF047418),
        'title': 'Refund Processed',
        'body': 'Your refund has been processed and should reflect in your account shortly.',
        'time': '1 day ago',
      },
      {
        'icon': Icons.local_offer_outlined,
        'color': Color(0xFFFF7A33),
        'title': 'New Custom Offer',
        'body': 'Timmon Photography sent you a custom offer. Review and accept if you\'re happy with the terms.',
        'time': '1 day ago',
      },
      {
        'icon': Icons.star_outline,
        'color': Colors.orange,
        'title': 'Leave a Review',
        'body': 'How was your experience with Timmon Photography? Share your feedback.',
        'time': '1 day ago',
      },
      {
        'icon': Icons.cancel_outlined,
        'color': Colors.red,
        'title': 'Booking Cancelled',
        'body': 'Your booking has been cancelled. Any eligible refund will be processed shortly.',
        'time': '1 day ago',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notifications',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Mark all as read',
                style: TextStyle(color: Color(0xFFFF7A33), fontSize: 12)),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (context, index) {
          final n = notifications[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (n['color'] as Color).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(n['icon'] as IconData, color: n['color'] as Color, size: 20),
            ),
            title: Text(n['title'] as String,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(n['body'] as String,
                    style: const TextStyle(fontSize: 12, color: Colors.black87)),
                const SizedBox(height: 4),
                Text(n['time'] as String,
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          );
        },
      ),
    );
  }
}