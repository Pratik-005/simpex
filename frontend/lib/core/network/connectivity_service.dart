import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  final Connectivity _connectivity;
  final ValueNotifier<bool> isOnlineNotifier = ValueNotifier<bool>(true);
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  VoidCallback? onConnectionRestored;

  ConnectivityService({
    Connectivity? connectivity,
    this.onConnectionRestored,
  }) : _connectivity = connectivity ?? Connectivity();

  bool get isOnline => isOnlineNotifier.value;

  Future<void> init() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateStatus(results);
    } catch (e) {
      debugPrint('[ConnectivityService] Error checking initial status: $e');
      isOnlineNotifier.value = true;
    }

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final wasOffline = !isOnlineNotifier.value;
      _updateStatus(results);
      if (wasOffline && isOnlineNotifier.value) {
        debugPrint('[ConnectivityService] Connection restored. Triggering callback.');
        onConnectionRestored?.call();
      }
    });
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    isOnlineNotifier.value = online;
  }

  void dispose() {
    _subscription?.cancel();
  }
}

