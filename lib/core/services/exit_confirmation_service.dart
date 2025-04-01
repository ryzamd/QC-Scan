import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BackButtonService {
  // Singleton instance
  static final BackButtonService _instance = BackButtonService._internal();
  factory BackButtonService() => _instance;
  BackButtonService._internal();

  // Event channel để nhận sự kiện từ native
  static const EventChannel _eventChannel = EventChannel(
    'com.example.architecture_scan_app/back_button',
  );

  // Stream subscription để lắng nghe sự kiện
  StreamSubscription? _subscription;

  // Khởi tạo service và lắng nghe sự kiện back button
  void initialize(BuildContext context) {
    _subscription?.cancel();
    _subscription = _eventChannel.receiveBroadcastStream().listen(
      (_) {
        if (context.mounted) {
          _showExitConfirmationDialog(context);
        }
      },
    );
  }

  // Dọn dẹp resource khi không cần thiết
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  // Hiển thị dialog xác nhận thoát
  void _showExitConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            title: const Text('EXIT', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),),
            content: const Text('Are you sure to exit the application?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => SystemNavigator.pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
