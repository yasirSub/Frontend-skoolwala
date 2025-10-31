import 'package:flutter/material.dart';

class VerifiedUserBadge extends StatelessWidget {
  final String? name;
  final double? lastDistanceMeters;
  final bool isWithinSchoolRadius;
  final double? confidencePercent;

  const VerifiedUserBadge({
    Key? key,
    required this.name,
    required this.lastDistanceMeters,
    required this.isWithinSchoolRadius,
    required this.confidencePercent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(
          0.7,
        ), // Dark semi-transparent background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWithinSchoolRadius
              ? Colors.green.withOpacity(0.5)
              : Colors.orange.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verified checkmark and name row
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_user_rounded,
                color: Colors.green[300],
                size: 18,
              ),
              SizedBox(width: 8),
              if (name != null && name!.trim().isNotEmpty)
                Flexible(
                  child: Text(
                    name!,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          SizedBox(height: 8),
          // Distance and confidence in organized rows
          if (lastDistanceMeters != null || confidencePercent != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (lastDistanceMeters != null) ...[
                  Icon(
                    Icons.location_on_rounded,
                    color: isWithinSchoolRadius
                        ? Colors.green[400]
                        : Colors.orange[400],
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    lastDistanceMeters! >= 1000
                        ? (lastDistanceMeters! / 1000).toStringAsFixed(2) +
                              ' km'
                        : lastDistanceMeters!.toStringAsFixed(0) + ' m',
                    style: TextStyle(
                      color: isWithinSchoolRadius
                          ? Colors.green[300]
                          : Colors.orange[300],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (confidencePercent != null) ...[
                    SizedBox(width: 12),
                    Container(
                      width: 1,
                      height: 12,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    SizedBox(width: 12),
                  ],
                ],
                if (confidencePercent != null) ...[
                  Icon(
                    Icons.percent_rounded,
                    color: Colors.cyan[300],
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    confidencePercent!.toStringAsFixed(1) + '%',
                    style: TextStyle(
                      color: Colors.cyan[300],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
