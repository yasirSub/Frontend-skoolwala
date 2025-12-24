import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:skoolwala/shared/theme/app_theme.dart';

class AttendanceInstructions extends StatelessWidget {
  final bool isAnalyzingFace;
  final bool isProcessing;
  final bool isFetchingMobileLocation;
  final bool schoolLocationLoaded;
  final bool isFaceValidatedForLoggedInUser;
  final String? faceAnalysisStatus;
  final int noMatchCount;
  final bool hasFaceEmbedding;

  const AttendanceInstructions({
    Key? key,
    required this.isAnalyzingFace,
    required this.isProcessing,
    required this.isFetchingMobileLocation,
    required this.schoolLocationLoaded,
    required this.isFaceValidatedForLoggedInUser,
    required this.faceAnalysisStatus,
    required this.noMatchCount,
    required this.hasFaceEmbedding,
  }) : super(key: key);

  String _getInstructionMessage() {
    bool isCurrentlyAnalyzing = isAnalyzingFace;
    if (!isCurrentlyAnalyzing && faceAnalysisStatus != null) {
      final status = faceAnalysisStatus!.toLowerCase();
      isCurrentlyAnalyzing =
          status.contains('analyzing') ||
          status.contains('validating') ||
          status.contains('verifying') ||
          status.contains('matching') ||
          status.contains('capturing');
    }

    if (isCurrentlyAnalyzing && noMatchCount < 3) {
      return 'SCANNING BIOMETRICS...';
    }

    if (isFetchingMobileLocation) return 'FETCHING LOCATION...';
    if (isProcessing) return 'PROCESSING DATA...';
    if (!schoolLocationLoaded) return 'SYNCING SCHOOL DATA...';

    if (faceAnalysisStatus != null) {
      final status = faceAnalysisStatus!.toLowerCase();
      if (status.contains('no matching') || status.contains('face not found')) {
        return 'FACE NOT DETECTED';
      }
      if (status.contains('mismatch')) return 'IDENTITY MISMATCH';
    }

    if (isFaceValidatedForLoggedInUser) return 'READY FOR ATTENDANCE';

    return 'POSITION FACE IN FRAME';
  }

  IconData _getIcon() {
    if (isAnalyzingFace || isProcessing || isFetchingMobileLocation) {
      return Icons.waves_rounded;
    }
    if (isFaceValidatedForLoggedInUser) return Icons.verified_rounded;
    return Icons.face_retouching_natural;
  }

  @override
  Widget build(BuildContext context) {
    final message = _getInstructionMessage();
    final bool isActivity =
        isAnalyzingFace || isProcessing || isFetchingMobileLocation;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  (isFaceValidatedForLoggedInUser
                          ? Colors.greenAccent
                          : AppTheme.primaryPurple)
                      .withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIcon(),
              color: isFaceValidatedForLoggedInUser
                  ? Colors.greenAccent
                  : Colors.white70,
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    color: isFaceValidatedForLoggedInUser
                        ? Colors.greenAccent
                        : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                if (isActivity)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Please hold still for a moment',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      isFaceValidatedForLoggedInUser
                          ? 'Verification complete'
                          : 'Automatic scanning active',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
