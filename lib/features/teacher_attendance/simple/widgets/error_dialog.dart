import 'package:flutter/material.dart';

Future<void> showErrorDialog(BuildContext context, String message) async {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.error, color: Colors.red),
          SizedBox(width: 10),
          Text('Error'),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('OK')),
      ],
    ),
  );
}
