import 'package:flutter/material.dart';

class CheckInOutButton extends StatelessWidget {
  final bool schoolLocationLoaded;
  final Map<String, dynamic>? schoolLocation;
  final bool isFetchingMobileLocation;
  final bool isProcessing;
  final bool isAnalyzingFace;
  final bool isFaceValidatedForLoggedInUser;
  final String? faceAnalysisStatus;
  final int noMatchCount;
  final bool isCurrentlyCheckedIn;
  final VoidCallback onSchoolLocationNotSet;
  final VoidCallback onRestartFaceAnalysis;
  final void Function(String type) onMarkAttendance;

  const CheckInOutButton({
    Key? key,
    required this.schoolLocationLoaded,
    required this.schoolLocation,
    required this.isFetchingMobileLocation,
    required this.isProcessing,
    required this.isAnalyzingFace,
    required this.isFaceValidatedForLoggedInUser,
    required this.faceAnalysisStatus,
    required this.noMatchCount,
    required this.isCurrentlyCheckedIn,
    required this.onSchoolLocationNotSet,
    required this.onRestartFaceAnalysis,
    required this.onMarkAttendance,
  }) : super(key: key);

  bool get _canShowTryAgainButton {
    final s = faceAnalysisStatus?.toLowerCase();
    if (s == null) return false;
    return (s.contains('no matching') ||
            s.contains('mismatch') ||
            s.contains('failed') ||
            s.contains('error')) &&
        noMatchCount >= 3;
  }

  bool get _hasMismatchError {
    if (isFaceValidatedForLoggedInUser) return false;
    final s = faceAnalysisStatus?.toLowerCase();
    if (s == null) return false;
    return s.contains('mismatch') || s.contains('not match');
  }

  bool get _hasErrorStatus {
    if (faceAnalysisStatus == null) return false;
    final status = faceAnalysisStatus!.toLowerCase();
    return status.contains('error') ||
        status.contains('failed') ||
        status.contains('fail') ||
        status.contains('mismatch') ||
        status.contains('not match') ||
        status.contains('no matching');
  }

  String? _getErrorMessage() {
    if (faceAnalysisStatus == null) return null;
    final status = faceAnalysisStatus!.toLowerCase();

    // Check for specific error types
    if (status.contains('mismatch') || status.contains('not match')) {
      return 'Face not match';
    }
    if (status.contains('no matching') || status.contains('no match')) {
      return 'Face not found';
    }
    if (status.contains('failed') || status.contains('fail')) {
      if (status.contains('face')) {
        return 'Face analysis failed';
      }
      if (status.contains('validation')) {
        return 'Validation failed';
      }
      if (status.contains('location') || status.contains('gps')) {
        return 'Location failed';
      }
      return 'Failed';
    }
    if (status.contains('error')) {
      if (status.contains('network')) {
        return 'Network error';
      }
      return 'Error occurred';
    }

    return null;
  }

  String _getButtonLabel() {
    // Priority 1: Show active processing flags (these take highest priority)
    // Check if we're in an analyzing state (either from flag or status)
    bool isInAnalyzingState = isAnalyzingFace;
    if (!isInAnalyzingState && faceAnalysisStatus != null) {
      final status = faceAnalysisStatus!.toLowerCase();
      isInAnalyzingState =
          status.contains('analyzing') ||
          status.contains('validating') ||
          status.contains('verifying') ||
          status.contains('matching') ||
          status.contains('capturing');
    }

    if (isInAnalyzingState || isAnalyzingFace) {
      // ALWAYS show attempt counter when analyzing (even on first attempt when noMatchCount = 0)
      // This helps user see progress: (1/3), (2/3), (3/3)
      return 'Analyzing face... (${noMatchCount + 1}/3)';
    }

    if (isFetchingMobileLocation) {
      return 'Fetching mobile location...';
    }

    if (isProcessing) {
      return 'Processing...';
    }

    if (!schoolLocationLoaded) {
      return 'Fetching school location...';
    }

    // Priority 2: Show specific status from faceAnalysisStatus
    // This is important because isAnalyzingFace might be false but we're still in retry cycle
    if (faceAnalysisStatus != null) {
      final status = faceAnalysisStatus!.toLowerCase();

      // Check for processing states first (before errors)
      if (status.contains('starting') ||
          status.contains('initializing') ||
          status.contains('starting automatic')) {
        // Show counter if we're in retry cycle
        if (noMatchCount > 0 && noMatchCount < 3) {
          return 'Initializing... (${noMatchCount + 1}/3)';
        }
        return 'Initializing...';
      }
      if (status.contains('analyzing face') ||
          status.contains('analyzing...') ||
          status.contains('analyzing')) {
        // Show attempt counter if we're analyzing and in retry cycle
        if (noMatchCount < 3) {
          return 'Analyzing face... (${noMatchCount + 1}/3)';
        }
        return 'Analyzing face...';
      }
      if (status.contains('capturing') || status.contains('capturing image')) {
        if (noMatchCount < 3) {
          return 'Capturing image... (${noMatchCount + 1}/3)';
        }
        return 'Capturing image...';
      }
      if (status.contains('validating') || status.contains('validating face')) {
        if (noMatchCount < 3) {
          return 'Validating face... (${noMatchCount + 1}/3)';
        }
        return 'Validating face...';
      }
      if (status.contains('verifying') ||
          status.contains('verifying face') ||
          status.contains('verifying face identity')) {
        if (noMatchCount < 3) {
          return 'Matching data... (${noMatchCount + 1}/3)';
        }
        return 'Matching data...';
      }
      if (status.contains('matching') || status.contains('matching data')) {
        if (noMatchCount < 3) {
          return 'Matching data... (${noMatchCount + 1}/3)';
        }
        return 'Matching data...';
      }

      // Only show errors if not in active processing and after retries exhausted
      if (_hasErrorStatus && _canShowTryAgainButton) {
        final errorMsg = _getErrorMessage();
        if (errorMsg != null) {
          return errorMsg;
        }
      }
    }

    // Priority 3: Check for configuration errors
    if (schoolLocationLoaded && schoolLocation == null) {
      return 'School location not set';
    }

    // Priority 4: Show intermediate states when not everything is ready
    if (!isFaceValidatedForLoggedInUser) {
      if (faceAnalysisStatus != null) {
        final status = faceAnalysisStatus!.toLowerCase();
        if (status.contains('analyzing')) {
          if (noMatchCount < 3) {
            return 'Analyzing face... (${noMatchCount + 1}/3)';
          }
          return 'Analyzing face...';
        }
        if (status.contains('validating')) {
          if (noMatchCount < 3) {
            return 'Validating face... (${noMatchCount + 1}/3)';
          }
          return 'Validating face...';
        }
        if (status.contains('matching') || status.contains('verifying')) {
          if (noMatchCount < 3) {
            return 'Matching data... (${noMatchCount + 1}/3)';
          }
          return 'Matching data...';
        }
        if (status.contains('capturing')) {
          return 'Capturing image...';
        }
        if (status.contains('starting')) {
          return 'Initializing...';
        }
      }
      // Default analyzing state with counter
      if (noMatchCount < 3) {
        return 'Analyzing... (${noMatchCount + 1}/3)';
      }
      return 'Analyzing...';
    }

    if (schoolLocation == null) {
      return 'Waiting for location...';
    }

    // Priority 5: Check if we should show "Try Again" (after 3 failed attempts)
    // This must come BEFORE "Ready" state to ensure it shows when needed
    // Show "Try Again" when 3 attempts are done, regardless of error status
    if (noMatchCount >= 3) {
      // If face is not validated after 3 attempts, show Try Again
      if (!isFaceValidatedForLoggedInUser) {
        return 'Try Again';
      }
    }

    // Priority 6: Everything is ready - show final state (ONLY if not processing)
    // Don't show "Ready" if we're still processing, analyzing, or fetching
    if (!isProcessing &&
        !isAnalyzingFace &&
        !isFetchingMobileLocation &&
        schoolLocationLoaded &&
        isFaceValidatedForLoggedInUser &&
        schoolLocation != null) {
      return isCurrentlyCheckedIn
          ? 'Ready for Check Out'
          : 'Ready for Check In';
    }

    // Default fallback - show analyzing state if nothing else matches
    if (!isFaceValidatedForLoggedInUser) {
      if (noMatchCount < 3) {
        return 'Analyzing... (${noMatchCount + 1}/3)';
      }
      return 'Analyzing...';
    }

    return 'Check In';
  }

  VoidCallback? get _onPressedCallback {
    // ALWAYS disable during any processing/fetching/analyzing
    if (isProcessing ||
        isAnalyzingFace ||
        !schoolLocationLoaded ||
        isFetchingMobileLocation) {
      return null;
    }

    // Enable for "Try Again" button when 3 attempts failed
    // Show Try Again when 3 attempts are done and face is not validated
    if (noMatchCount >= 3 && !isFaceValidatedForLoggedInUser) {
      return onRestartFaceAnalysis;
    }

    // Also check using the helper method
    if (_canShowTryAgainButton) {
      return onRestartFaceAnalysis;
    }

    // ONLY enable when EVERYTHING is completely ready:
    // - Face must be validated for logged-in user
    // - School location must be loaded and available
    // - No mismatch errors
    // - Not currently processing anything
    if (isFaceValidatedForLoggedInUser &&
        schoolLocation != null &&
        !_hasMismatchError) {
      return () =>
          onMarkAttendance(isCurrentlyCheckedIn ? 'check_out' : 'check_in');
    }

    // Keep disabled while fetching/analyzing/preparing
    return null;
  }

  Widget _buildButton(
    BuildContext context,
    bool schoolNotConfigured,
    bool hasLocation,
  ) {
    if (schoolNotConfigured) {
      return ElevatedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('School location not set'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
          onSchoolLocationNotSet();
        },
        icon: Icon(Icons.location_off, size: 22),
        label: Text(
          'School location not set',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[600]!,
          foregroundColor: Colors.white,
          elevation: 4,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          minimumSize: Size(double.infinity, 58),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          shadowColor: Colors.red.withOpacity(0.3),
        ),
      );
    }

    final String buttonLabel = _getButtonLabel();
    final String displayLabel = buttonLabel.isEmpty ? 'Check In' : buttonLabel;

    // Determine button colors and styling
    final bool isDisabled =
        isProcessing ||
        isAnalyzingFace ||
        !schoolLocationLoaded ||
        isFetchingMobileLocation;

    final bool isReady = isFaceValidatedForLoggedInUser && hasLocation;
    final bool isTryAgain =
        _canShowTryAgainButton ||
        (noMatchCount >= 3 && !isFaceValidatedForLoggedInUser);

    Color backgroundColor;
    Color foregroundColor;
    IconData buttonIcon;

    if (isDisabled) {
      backgroundColor = Colors.grey[600]!;
      foregroundColor = Colors.white;
      buttonIcon = Icons.hourglass_empty;
    } else if (schoolNotConfigured) {
      backgroundColor = Colors.red[600]!;
      foregroundColor = Colors.white;
      buttonIcon = Icons.location_off;
    } else if (isReady) {
      backgroundColor = isCurrentlyCheckedIn
          ? Colors.red[600]!
          : Colors.green[600]!;
      foregroundColor = Colors.white;
      buttonIcon = isCurrentlyCheckedIn ? Icons.logout : Icons.login;
    } else if (isTryAgain) {
      backgroundColor = Colors.orange[600]!;
      foregroundColor = Colors.white;
      buttonIcon = Icons.refresh;
    } else {
      backgroundColor = Colors.grey[600]!;
      foregroundColor = Colors.white;
      buttonIcon = Icons.access_time;
    }

    return ElevatedButton.icon(
      onPressed: _onPressedCallback,
      icon: Icon(buttonIcon, size: 22),
      label: Text(
        displayLabel,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: isDisabled ? 0 : 4,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        minimumSize: Size(double.infinity, 58),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        shadowColor: backgroundColor.withOpacity(0.3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool schoolNotConfigured =
        schoolLocationLoaded && schoolLocation == null;
    final bool hasLocation = schoolLocation != null;

    // Ensure button is always visible - using Container with explicit size constraints
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: 56, // Material Design minimum touch target
      ),
      child: _buildButton(context, schoolNotConfigured, hasLocation),
    );
  }
}
