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
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Colors.black,
                    size: 12,
                  ),
                ),
                SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (name != null && name!.trim().isNotEmpty)
                      Text(
                        name!,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (lastDistanceMeters != null)
                      Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Text(
                          lastDistanceMeters! >= 1000
                              ? (lastDistanceMeters! / 1000).toStringAsFixed(
                                      2,
                                    ) +
                                    ' km'
                              : lastDistanceMeters!.toStringAsFixed(0) + ' m',
                          style: TextStyle(
                            color: isWithinSchoolRadius
                                ? Colors.green[700]
                                : Colors.red[700],
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (confidencePercent != null)
                      Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Text(
                          confidencePercent!.toStringAsFixed(2) + '%',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
