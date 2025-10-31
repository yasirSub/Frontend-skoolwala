import 'package:flutter/material.dart';
import 'package:skoolwala/features/teacher_attendance/simple/widgets/location_action_row.dart';

class SchoolMobileLocationPanel extends StatelessWidget {
  final Map<String, dynamic>? schoolLocation;
  final double? userLatitude;
  final double? userLongitude;
  final bool isProcessing;
  final bool isFetchingLocation;
  final Future<void> Function()? onRefresh;
  final Future<void> Function()? onDiagnose;

  const SchoolMobileLocationPanel({
    Key? key,
    required this.schoolLocation,
    required this.userLatitude,
    required this.userLongitude,
    required this.isProcessing,
    required this.isFetchingLocation,
    this.onRefresh,
    this.onDiagnose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String schoolLat = (schoolLocation?['latitude'])?.toString() ?? '';
    final String schoolLng = (schoolLocation?['longitude'])?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school, color: Colors.white, size: 14),
            SizedBox(width: 6),
            Text(
              'School location',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          (schoolLat.isEmpty || schoolLng.isEmpty)
              ? 'lat: -, lng: -'
              : 'lat: ' + schoolLat + ', lng: ' + schoolLng,
          style: TextStyle(color: Colors.white70, fontSize: 11),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.smartphone, color: Colors.white, size: 14),
            SizedBox(width: 6),
            Text(
              'Mobile location',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 6),
            LocationActionRow(
              isProcessing: isProcessing,
              isFetchingLocation: isFetchingLocation,
              onRefresh: onRefresh,
              onDiagnose: onDiagnose,
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          (userLatitude == null || userLongitude == null)
              ? 'lat: -, lng: -'
              : 'lat: ' +
                    userLatitude!.toStringAsFixed(6) +
                    ', lng: ' +
                    userLongitude!.toStringAsFixed(6),
          style: TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
}
