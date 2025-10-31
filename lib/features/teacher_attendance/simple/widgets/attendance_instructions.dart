import 'package:flutter/material.dart';

/// Dynamic instructions widget that shows different messages based on attendance state
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
    // Show attempt counter during automatic retries (1/3, 2/3, 3/3)
    // Show counter when analyzing face OR when faceAnalysisStatus indicates analyzing
    // - First attempt: noMatchCount = 0, showing (1/3)
    // - After 1st failure: noMatchCount = 1, showing (2/3)
    // - After 2nd failure: noMatchCount = 2, showing (3/3)

    // Check if we're in analyzing state (either from flag or status)
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
      String baseMessage = 'Analyzing face features...';
      if (faceAnalysisStatus != null) {
        final status = faceAnalysisStatus!.toLowerCase();
        if (status.contains('analyzing face') ||
            status.contains('analyzing...') ||
            status.contains('analyzing')) {
          baseMessage = 'Analyzing face features...';
        } else if (status.contains('validating') ||
            status.contains('validating face')) {
          baseMessage = 'Validating face...';
        } else if (status.contains('verifying') ||
            status.contains('verifying face') ||
            status.contains('verifying face identity')) {
          baseMessage = 'Matching data...';
        } else if (status.contains('matching') ||
            status.contains('matching data')) {
          baseMessage = 'Matching data...';
        } else if (status.contains('capturing') ||
            status.contains('capturing image')) {
          baseMessage = 'Capturing image...';
        }
      }
      // Show current attempt (noMatchCount + 1) out of 3 total attempts
      // noMatchCount starts at 0, so first attempt shows (1/3)
      return '$baseMessage (${noMatchCount + 1}/3)';
    }

    // Priority 1: Show active processing/background activities
    if (isAnalyzingFace) {
      if (faceAnalysisStatus != null) {
        final status = faceAnalysisStatus!.toLowerCase();
        if (status.contains('analyzing face') ||
            status.contains('analyzing...') ||
            status.contains('analyzing')) {
          return 'Analyzing face features...';
        }
        if (status.contains('capturing') ||
            status.contains('capturing image')) {
          return 'Capturing image...';
        }
        if (status.contains('validating') ||
            status.contains('validating face')) {
          return 'Validating face...';
        }
        if (status.contains('verifying') ||
            status.contains('verifying face') ||
            status.contains('verifying face identity')) {
          return 'Matching data...';
        }
        if (status.contains('matching') || status.contains('matching data')) {
          return 'Matching data...';
        }
        if (status.contains('starting') ||
            status.contains('initializing') ||
            status.contains('starting automatic')) {
          return 'Initializing face recognition...';
        }
      }
      return 'Analyzing face features...';
    }

    if (isFetchingMobileLocation) {
      return 'Fetching mobile location...';
    }

    if (isProcessing) {
      return 'Processing attendance...';
    }

    if (!schoolLocationLoaded) {
      return 'Fetching school location...';
    }

    // Priority 2: Check for face not found errors
    if (faceAnalysisStatus != null) {
      final status = faceAnalysisStatus!.toLowerCase();

      if (status.contains('no matching') ||
          status.contains('no match') ||
          status.contains('face not found')) {
        if (noMatchCount >= 3) {
          return 'Please place your face to camera';
        }
        return 'Face not found. Please place your face to camera';
      }

      if (status.contains('mismatch') || status.contains('not match')) {
        return 'Face not match. Please try again';
      }
    }

    // Priority 3: If no face detected at all (no embedding captured)
    if (!hasFaceEmbedding && !isFaceValidatedForLoggedInUser) {
      if (faceAnalysisStatus != null) {
        final status = faceAnalysisStatus!.toLowerCase();
        if (status.contains('no face detected') ||
            status.contains('no face found')) {
          return 'Please place your face to camera';
        }
      }
      // Default when nothing is happening and no face found
      return 'Please place your face to camera';
    }

    // Priority 4: Face validated - show ready message
    if (isFaceValidatedForLoggedInUser) {
      return 'Face verified! Ready for attendance';
    }

    // Default fallback
    return 'Position your face in the circle and tap Check In or Check Out';
  }

  @override
  Widget build(BuildContext context) {
    final message = _getInstructionMessage();

    return Text(
      message,
      style: TextStyle(color: Colors.white70, fontSize: 14),
      textAlign: TextAlign.center,
    );
  }
}
