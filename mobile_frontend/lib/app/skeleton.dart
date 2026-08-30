import 'package:flutter/material.dart';

/// Base grey used for skeleton placeholders.
const Color skeletonColor = Color(0xFFE6E6E6);

/// Wraps skeleton content in a soft pulsing opacity animation, mimicking the
/// shimmer placeholders used by Instagram and similar apps while data loads.
///
/// Use this to keep a consistent loading look across the app instead of
/// flashing placeholder text ("Creative", blank avatars, etc.) before real
/// data arrives.
class SkeletonPulse extends StatefulWidget {
  final Widget child;

  const SkeletonPulse({super.key, required this.child});

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: widget.child,
    );
  }
}

/// A single grey placeholder box — stands in for avatars, images and buttons.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  final bool circle;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 8,
    this.circle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: skeletonColor,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
      ),
    );
  }
}

/// A grey bar that mimics a single line of text.
class SkeletonLine extends StatelessWidget {
  final double width;
  final double height;

  const SkeletonLine({
    super.key,
    this.width = double.infinity,
    this.height = 12,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(width: width, height: height, radius: height / 2);
  }
}

/// A skeleton row shaped like a booking/creator card (avatar + text lines).
/// Reusable across list screens while their data loads.
class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            const SkeletonBox(width: 52, height: 52, radius: 10),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonLine(width: 150, height: 14),
                  SizedBox(height: 10),
                  SkeletonLine(width: 90, height: 11),
                  SizedBox(height: 8),
                  SkeletonLine(width: 120, height: 11),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
