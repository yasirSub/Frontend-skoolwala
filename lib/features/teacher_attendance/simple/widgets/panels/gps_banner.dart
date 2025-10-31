import 'package:flutter/material.dart';

class GpsBanner extends StatelessWidget {
  final double latitude;
  final double longitude;

  const GpsBanner({Key? key, required this.latitude, required this.longitude})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.blue[800],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[400]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gps_fixed, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text(
                'GPS Location Obtained',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.white70, size: 14),
              SizedBox(width: 6),
              Text(
                'Latitude: ' + latitude.toStringAsFixed(6),
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.white70, size: 14),
              SizedBox(width: 6),
              Text(
                'Longitude: ' + longitude.toStringAsFixed(6),
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
