import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';

class VerificationComplianceGrid extends StatelessWidget {
  final Map<String, dynamic> summary;

  const VerificationComplianceGrid({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildComplianceItem(
            label: 'FACE',
            rate: (summary['face_verification_rate'] ?? 0).toDouble(),
            icon: Icons.face_retouching_natural_rounded,
            color: AppTheme.primaryPurple,
          ),
          _buildComplianceItem(
            label: 'GPS',
            rate: (summary['gps_verification_rate'] ?? 0).toDouble(),
            icon: Icons.location_on_rounded,
            color: AppTheme.accentCyan,
          ),
          _buildComplianceItem(
            label: 'RADIUS',
            rate: (summary['location_verification_rate'] ?? 0).toDouble(),
            icon: Icons.radar_rounded,
            color: AppTheme.accentGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceItem({
    required String label,
    required double rate,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: rate / 100,
                strokeWidth: 4,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              Icon(icon, color: color.withOpacity(0.8), size: 20),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '$rate%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
