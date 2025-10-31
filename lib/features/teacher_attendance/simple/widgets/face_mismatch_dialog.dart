import 'package:flutter/material.dart';

Future<void> showFaceMismatchDialog(
  BuildContext context, {
  VoidCallback? onConfirmed,
}) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.block, color: Colors.red, size: 20),
          ),
          SizedBox(width: 10),
          Text('Face Mismatch'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The detected face does not match the logged-in user.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text(
            'Please ensure the correct account is logged in and try again.',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
      actionsPadding: EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (onConfirmed != null) onConfirmed();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text('OK'),
          ),
        ),
      ],
    ),
  );
}


