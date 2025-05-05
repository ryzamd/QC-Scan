import 'dart:async';
import 'package:architecture_scan_app/core/localization/context_extension.dart';
import 'package:architecture_scan_app/core/widgets/confirmation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BackButtonService {
  static final BackButtonService _instance = BackButtonService._internal();
  factory BackButtonService() => _instance;
  BackButtonService._internal();

  static const EventChannel _eventChannel = EventChannel('com.example.architecture_scan_app/back_button');

  StreamSubscription? _subscription;

  bool _isDialogShowing = false;

  Future<void> initializeAsync(BuildContext context) async {
    _subscription?.cancel();
    _subscription = _eventChannel.receiveBroadcastStream().listen(
      (_) {
        try {
          if(!context.mounted){
            return;
          }

          context.widget;
          _showExitConfirmationDialogAsync(context);
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

  Future<void> disposeAsync() async {
    _subscription?.cancel();
    _subscription = null;
    _isDialogShowing = false;
  }

  Future<void> _showExitConfirmationDialogAsync(BuildContext context) async {
    if(!context.mounted){
      return;
    }

    if (_isDialogShowing) {
      return;
    }

    _isDialogShowing = true;

    try {
      if (!context.mounted) {
         _isDialogShowing = false;
         return;
       }

      ConfirmationDialog.showAsync(
        context: context,
        title: context.multiLanguage.exitTitleUPCASE,
        message: context.multiLanguage.exitTheAppMessage,
        confirmText: context.multiLanguage.okButtonUPCASE,
        cancelText: context.multiLanguage.cancelButton,
        showCancelButton: true,
        titleColor: Colors.red,
        confirmColor: Colors.red,
        cancelColor: Colors.black87,
        onConfirm: () {
          SystemNavigator.pop();
        },
      );
    } catch (e) {
      debugPrint("BackButtonService: Error showing: $e");
    } finally {
      _isDialogShowing = false;
    }
  }
}
