import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  bool _isOnline = true;

  ConnectivityService(this._connectivity) {
    _connectivity.onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online != _isOnline) {
        _isOnline = online;
        _controller.add(_isOnline);
      }
    });
    _init();
  }

  Future<void> _init() async {
    await forceCheck();
  }

  Future<void> forceCheck() async {
    final results = await _connectivity.checkConnectivity();
    final online = results.any((r) => r != ConnectivityResult.none);
    if (online != _isOnline) {
      _isOnline = online;
      _controller.add(_isOnline);
    }
  }

  bool get isOnline => _isOnline;
  Stream<bool> get onStatusChange => _controller.stream;

  void dispose() => _controller.close();
}
