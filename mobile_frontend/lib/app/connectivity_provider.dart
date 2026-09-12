import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Tracks device connectivity so the rest of the app can react to going
/// offline / coming back online.
///
/// NOTE: `connectivity_plus` reports whether a network *interface* is up
/// (wifi / cellular / none) — not whether the internet is actually reachable.
/// That's the standard, lightweight signal used for a global "you're offline"
/// banner; deeper reachability checks can be layered on top if required.
class ConnectivityProvider extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  ConnectivityProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _apply(results);
    } catch (_) {
      // If the platform check fails, stay optimistic (assume online).
    }
    _sub = _connectivity.onConnectivityChanged.listen(_apply);
  }

  void _apply(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (online == _isOnline) return;
    _isOnline = online;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
