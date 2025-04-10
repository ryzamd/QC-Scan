import 'package:flutter/material.dart';

class ErrorDialog extends StatelessWidget {
  static bool _isShowing = false;
  
  final String title;
  final String message;
  final VoidCallback? onDismiss;
  
  const ErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.onDismiss,
  });
  
  static void show(
    BuildContext context, {
    String title = 'Error',
    String message = 'An error occurred.',
    VoidCallback? onDismiss,
  }) {
    if (!_isShowing && context.mounted) {
      _isShowing = true;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => ErrorDialog(
          title: title,
          message: message,
          onDismiss: onDismiss,
        ),
      ).then((_) {

        _isShowing = false;
        
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && onDismiss != null) {
          onDismiss!();
        }
      },
      child: AlertDialog(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _isShowing = false;
              if (onDismiss != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  onDismiss!();
                });
              }
            },
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}