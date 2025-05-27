import 'package:flutter/material.dart';

class LoadingDialog {
  static bool isShowing = false;

  static Future<void> showAsync({
    required BuildContext context,
    String message = 'Loading...',
  }) async {
    if (isShowing) return;

    isShowing = true;

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: SizedBox(
          height: 150,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(message),
            ],
          ),
        ),
      ),
    );

    isShowing = false;
  }

  static Future<void> hideAsync(BuildContext context) async {
    if (isShowing && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      isShowing = false;
    }
  }
}