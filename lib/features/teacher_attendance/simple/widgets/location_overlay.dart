import 'package:flutter/material.dart';

enum OverlaySeverity { warning, error }

Future<void> showLocationOverlayDialog({
  required BuildContext context,
  required String message,
  required double distanceMeters,
  required Map<String, dynamic>? schoolLocation,
  required double? userLatitude,
  required double? userLongitude,
  OverlaySeverity severity = OverlaySeverity.warning,
}) async {
  final bool isError = severity == OverlaySeverity.error;
  final Color color = isError ? Colors.red : Colors.orange;
  final String distanceText = distanceMeters >= 1000
      ? (distanceMeters / 1000).toStringAsFixed(2) + ' km'
      : distanceMeters.toStringAsFixed(0) + ' m';

  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: [
          Icon(isError ? Icons.location_off : Icons.location_on, color: color),
          SizedBox(width: 8),
          Text(isError ? 'Too Far' : 'Outside Radius'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.straighten, size: 18, color: Colors.grey[700]),
              SizedBox(width: 6),
              Text('Distance: '),
              Text(distanceText, style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 8),
          if (userLatitude != null && userLongitude != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.my_location, size: 18, color: Colors.grey[700]),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Mobile location: ' +
                        userLatitude.toStringAsFixed(6) + ', ' +
                        userLongitude.toStringAsFixed(6),
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
              ],
            ),
          if (schoolLocation != null) ...[
            SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.school, size: 18, color: Colors.grey[700]),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'School (' +
                        (schoolLocation['name']?.toString() ?? 'Location') +
                        ') : ' +
                        (schoolLocation['latitude']?.toString() ?? '') +
                        ', ' +
                        (schoolLocation['longitude']?.toString() ?? ''),
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('OK'),
        ),
      ],
    ),
  );
}


