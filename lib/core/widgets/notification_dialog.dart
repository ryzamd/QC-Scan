import 'package:flutter/material.dart';

class NotificationDialog {
  static bool _isShowing = false;

  static Future<void> showAsync({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
    Color titleColor = Colors.blue,
    Color buttonColor = Colors.blue,
    VoidCallback? onButtonPressed,
  }) async {
    if (_isShowing) return;

    _isShowing = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      useSafeArea: true,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: titleColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (onButtonPressed != null) onButtonPressed();
            },
            child: Text(
              buttonText,
              style: TextStyle(
                color: buttonColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
    
    _isShowing = false;
  }
}