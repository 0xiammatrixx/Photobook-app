import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'connectivity_provider.dart';

const _orange = Color(0xFFFF7A33);

/// Wraps the app's Navigator (via `MaterialApp.builder`) so an "offline"
/// banner shows on every screen without touching individual pages.
///
/// When online the child renders untouched. When offline, a slim banner is
/// inserted above the Navigator and the Navigator's top safe-area padding is
/// removed so screens don't double-pad below the status bar.
class ConnectivityOverlay extends StatelessWidget {
  final Widget child;

  const ConnectivityOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final online = context.watch<ConnectivityProvider>().isOnline;

    final Widget navigator = online
        ? child
        : MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: child,
          );

    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) =>
              SizeTransition(sizeFactor: animation, child: child),
          child: online
              ? const SizedBox.shrink(key: ValueKey('online'))
              : const _OfflineStrip(key: ValueKey('offline')),
        ),
        Expanded(child: navigator),
      ],
    );
  }
}

class _OfflineStrip extends StatelessWidget {
  const _OfflineStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF181818),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.wifi_off, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'No internet connection',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                'Some features may be unavailable',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen "no connection" state for pages that need the network to show
/// anything meaningful. Drop it into a page body when `isOnline == false`:
///
/// ```dart
/// if (!context.watch<ConnectivityProvider>().isOnline) {
///   return const NoInternetView(onRetry: _load);
/// }
/// ```
class NoInternetView extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? message;

  const NoInternetView({super.key, this.onRetry, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3EC),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off, size: 44, color: _orange),
            ),
            const SizedBox(height: 16),
            const Text(
              'No internet connection',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message ?? 'Check your connection and try again.',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
