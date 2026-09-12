import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A reusable, horizontally-centered empty-state placeholder (icon + title +
/// subtitle + optional action). Used anywhere a list/grid has no content yet,
/// so empty screens look consistent across the app.
class EmptyState extends StatelessWidget {
  /// Path to an `.svg` asset to render as the empty-state illustration.
  final String asset;
  final String title;
  final String subtitle;
  final Widget? action;
  final double imageSize;

  const EmptyState({
    super.key,
    required this.asset,
    required this.title,
    required this.subtitle,
    this.action,
    this.imageSize = 140,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(asset, width: imageSize, height: imageSize),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (action != null) ...[const SizedBox(height: 14), action!],
          ],
        ),
      ),
    );
  }
}
