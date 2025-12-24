import 'package:flutter/material.dart';
import 'dart:ui';

class VerifiedUserBadge extends StatefulWidget {
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
  State<VerifiedUserBadge> createState() => _VerifiedUserBadgeState();
}

class _VerifiedUserBadgeState extends State<VerifiedUserBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color:
                    (widget.isWithinSchoolRadius
                            ? Colors.greenAccent
                            : Colors.orangeAccent)
                        .withOpacity(0.15 * _pulseController.value),
                blurRadius: 20,
                spreadRadius: 5 * _pulseController.value,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color:
                        (widget.isWithinSchoolRadius
                                ? Colors.greenAccent
                                : Colors.orangeAccent)
                            .withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon/Avatar Area
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: widget.isWithinSchoolRadius
                              ? Colors.greenAccent.withOpacity(0.2)
                              : Colors.orangeAccent.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.isWithinSchoolRadius
                              ? Icons.verified_user_rounded
                              : Icons.person_pin_circle_rounded,
                          color: widget.isWithinSchoolRadius
                              ? Colors.greenAccent
                              : Colors.orangeAccent,
                          size: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name and Status
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.name != null)
                            Text(
                              widget.name!.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const Text(
                            'IDENTITY VERIFIED',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 7,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.confidencePercent != null) ...[
                      const SizedBox(width: 15),
                      Container(
                        width: 1,
                        height: 20,
                        color: Colors.white.withOpacity(0.15),
                      ),
                      const SizedBox(width: 15),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${widget.confidencePercent!.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'MATCH',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 6,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, color: color, size: 12),
    );
  }
}
