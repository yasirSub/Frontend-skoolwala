import 'package:flutter/material.dart';

import '../../../attendance/services/attendance_service.dart';

Future<void> showFaceMismatchDialog(
  BuildContext context, {
  VoidCallback? onConfirmed,
}) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      bool isRequesting = false;

      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
                'If your face is not working properly, you can send a face change request to your branch admin. After approval, your old face will be deleted and you can register again (one time).',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
          actionsPadding: EdgeInsets.fromLTRB(16, 0, 16, 12),
          actions: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: isRequesting
                    ? null
                    : () async {
                        setState(() {
                          isRequesting = true;
                        });
                        try {
                          await AttendanceService.createFaceChangeRequest(
                            reason: 'Face mismatch during attendance',
                          );
                          if (ctx.mounted) Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Face change request sent to admin.',
                              ),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(e.toString())));
                        } finally {
                          if (ctx.mounted) {
                            setState(() {
                              isRequesting = false;
                            });
                          }
                        }
                      },
                child: isRequesting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('REQUEST FACE CHANGE'),
              ),
            ),
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
    },
  );
}
