import 'package:flutter/material.dart';
import 'dart:ui';

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
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isWithinSchoolRadius
                  ? Colors.greenAccent.withOpacity(0.3)
                  : Colors.orangeAccent.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Verified row
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.greenAccent,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (name != null && name!.trim().isNotEmpty)
                    Flexible(
                      child: Text(
                        name!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              // Stats row
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (lastDistanceMeters != null) ...[
                    Icon(
                      Icons.location_on_rounded,
                      color: isWithinSchoolRadius
                          ? Colors.greenAccent[400]
                          : Colors.orangeAccent[400],
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      lastDistanceMeters! >= 1000
                          ? '${(lastDistanceMeters! / 1000).toStringAsFixed(2)} km'
                          : '${lastDistanceMeters!.toStringAsFixed(0)} m',
                      style: TextStyle(
                        color: isWithinSchoolRadius
                            ? Colors.greenAccent[400]
                            : Colors.orangeAccent[400],
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  if (confidencePercent != null) ...[
                    const SizedBox(width: 12),
                    Container(
                      width: 1.5,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.radar_rounded,
                      color: Colors.cyanAccent,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${confidencePercent!.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
