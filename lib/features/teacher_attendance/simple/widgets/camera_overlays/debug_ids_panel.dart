import 'package:flutter/material.dart';

class DebugIdsPanel extends StatelessWidget {
  final String? loggedInStaffId;
  final String? faceStaffId;

  const DebugIdsPanel({
    super.key,
    required this.loggedInStaffId,
    required this.faceStaffId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Logged-in ID: ' + (loggedInStaffId ?? '-'),
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2),
          Text(
            'Face ID: ' + (faceStaffId ?? '-'),
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
