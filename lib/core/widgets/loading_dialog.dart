import 'package:flutter/material.dart';

class LoadingDialog {
  static bool isShowing = false;

  static Future<void> showAsync({
    required BuildContext context,
    String message = 'Loading...',
  }) async {
    if (isShowing) return;

    isShowing = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  static Future<void> hideAsync(BuildContext context) async {
    if (isShowing && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      isShowing = false;
    }
  }
}