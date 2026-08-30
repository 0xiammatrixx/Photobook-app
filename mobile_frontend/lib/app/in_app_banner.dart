import 'package:flutter/material.dart';

/// Brand colors used across the app (keep in sync with the booking/notification
/// styling in `notification_service.dart`).
const Color brandOrange = Color(0xFFFF7A33);
const Color brandGreen = Color(0xFF047418);

/// Shows a branded, animated in-app banner at the top of the screen.
///
/// Auto-dismisses after [duration]. If [onTap] is provided, the banner is
/// tappable and invokes it (used for deep-linking from a foreground push).
void showInAppBanner(
  BuildContext context, {
  required String title,
  required String body,
  IconData icon = Icons.notifications_outlined,
  Color color = brandOrange,
  Duration duration = const Duration(seconds: 4),
  VoidCallback? onTap,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _InAppBanner(
      title: title,
      body: body,
      icon: icon,
      color: color,
      onTap: onTap == null
          ? null
          : () {
              entry.remove();
              onTap();
            },
    ),
  );
  overlay.insert(entry);

  Future.delayed(duration, () {
    if (entry.mounted) entry.remove();
  });
}

class _InAppBanner extends StatefulWidget {
  final String title;
  final String body;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _InAppBanner({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  State<_InAppBanner> createState() => _InAppBannerState();
}

class _InAppBannerState extends State<_InAppBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top + 8;
    return Positioned(
      top: top,
      left: 12,
      right: 12,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(14),
            color: Colors.white,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(widget.icon, color: widget.color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
