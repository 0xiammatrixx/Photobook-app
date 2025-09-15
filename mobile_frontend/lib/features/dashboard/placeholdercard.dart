import 'package:flutter/material.dart';

class PlaceholderCard extends StatelessWidget {
  final String title;
  final int rating;

  const PlaceholderCard({super.key, required this.title, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Container(
            height: 80,
            color: Colors.grey.shade200,
            alignment: Alignment.center,
            child: const Text("SVG"),
          ),
          const SizedBox(height: 8),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text("⭐" * rating),
          const SizedBox(height: 4),
          Text("View Profile", style: TextStyle(color: Colors.deepOrange.shade400)),
        ],
      ),
    );
  }
}
