import 'package:flutter/material.dart';

class ConfirmationDialog {
  static bool _isShowing = false;

  static Future<bool?> showAsync({
    required BuildContext context,
    required String title,
    required String message,
    required bool showCancelButton,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color titleColor = Colors.red,
    Color confirmColor = Colors.red,
    Color cancelColor = Colors.black87,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) async {
    if (_isShowing) return null;
    
    _isShowing = true;
    
    final result = await showDialog<bool>(
      context: context,
      useSafeArea: true,
      barrierDismissible: false,
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
          if(showCancelButton)
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(false);
              if (onCancel != null) onCancel();
            },
            child: Text(
              cancelText,
              style: TextStyle(
                color: cancelColor,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
              if (onConfirm != null) onConfirm();
            },
            child: Text(
              confirmText,
              style: TextStyle(
                color: confirmColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
    
    _isShowing = false;
    return result;
  }
}