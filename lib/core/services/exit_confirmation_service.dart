import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BackButtonService {
  static final BackButtonService _instance = BackButtonService._internal();
  factory BackButtonService() => _instance;
  BackButtonService._internal();

  static const EventChannel _eventChannel = EventChannel('com.example.architecture_scan_app/back_button');

  StreamSubscription? _subscription;

  bool _isDialogShowing = false;

  void initialize(BuildContext context) {
    _subscription?.cancel();
    _subscription = _eventChannel.receiveBroadcastStream().listen(
      (_) {
        try {
          if(!context.mounted){
            return;
          }

          context.widget;
          _showExitConfirmationDialog(context);
        } catch (e) {
          debugPrint("BackButtonService: Context is no longer valid. Skipping dialog.");
        }
      },
      onError: (error) {
        debugPrint("BackButtonService: Error receiving back button event: $error");
        _isDialogShowing = false;
      },
       onDone: () {
        debugPrint("BackButtonService: Event channel stream closed.");
        _isDialogShowing = false;
      },
      cancelOnError: false,
    );
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _isDialogShowing = false;
  }

  Future<void> _showExitConfirmationDialog(BuildContext context) async {
    if(!context.mounted){
      return;
    }

    if (_isDialogShowing) {
      return;
    }

    _isDialogShowing = true;

    try {
      if (!context.mounted) {
         _isDialogShowing = false; // Reset cờ vì không hiển thị dialog
         return;
       }

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: const Text(
            'EXIT',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          content: const Text('Are you sure to exit the application?'),
          actions: [
            TextButton(
              onPressed: () {
                  if(Navigator.of(dialogContext).canPop()){
                     Navigator.of(dialogContext).pop();
                 }
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                SystemNavigator.pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint("BackButtonService: Error showing: $e");
    } finally {
      _isDialogShowing = false;
    }
  }
}
