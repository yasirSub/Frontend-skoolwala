import 'package:flutter/material.dart';
import 'package:skoolwala/shared/theme/app_theme.dart';

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
    super.key,
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
  });

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

    if (status.contains('mismatch') || status.contains('not match')) {
      return 'Face not match';
    }
    if (status.contains('no matching') || status.contains('no match')) {
      return 'Face not found';
    }
    if (status.contains('failed') || status.contains('fail')) {
      if (status.contains('face')) return 'Face analysis failed';
      if (status.contains('validation')) return 'Validation failed';
      if (status.contains('location') || status.contains('gps')) {
        return 'Location failed';
      }
      return 'Failed';
    }
    if (status.contains('error')) {
      if (status.contains('network')) return 'Network error';
      return 'Error occurred';
    }
    return null;
  }

  String _getButtonLabel() {
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
      return 'ANALYZING FACE... (${noMatchCount + 1}/3)';
    }

    if (isFetchingMobileLocation) {
      return 'FETCHING LOCATION...';
    }

    if (isProcessing) {
      return 'PROCESSING...';
    }

    if (!schoolLocationLoaded) {
      return 'FETCHING SCHOOL...';
    }

    if (faceAnalysisStatus != null) {
      final status = faceAnalysisStatus!.toLowerCase();
      if (status.contains('starting') ||
          status.contains('initializing') ||
          status.contains('starting automatic')) {
        return noMatchCount > 0 && noMatchCount < 3
            ? 'INITIALIZING... (${noMatchCount + 1}/3)'
            : 'INITIALIZING...';
      }
    }

    if (schoolLocationLoaded && schoolLocation == null) {
      return 'ZONE NOT SET';
    }

    if (!isFaceValidatedForLoggedInUser) {
      if (noMatchCount >= 3) return 'TRY AGAIN';
      return 'ANALYZING... (${noMatchCount + 1}/3)';
    }

    if (schoolLocation == null) {
      return 'WAITING...';
    }

    if (!isProcessing &&
        !isAnalyzingFace &&
        !isFetchingMobileLocation &&
        schoolLocation != null) {
      return isCurrentlyCheckedIn
          ? 'READY FOR CHECK OUT'
          : 'READY FOR CHECK IN';
    }

    return 'CHECK IN';
  }

  @override
  Widget build(BuildContext context) {
    final bool schoolNotConfigured =
        schoolLocationLoaded && schoolLocation == null;
    final bool isDisabled =
        isProcessing ||
        isAnalyzingFace ||
        !schoolLocationLoaded ||
        isFetchingMobileLocation;
    final bool isReady =
        isFaceValidatedForLoggedInUser && schoolLocation != null && !isDisabled;
    final bool isTryAgain =
        !isReady && (noMatchCount >= 3 || _hasErrorStatus) && !isDisabled;

    final label = _getButtonLabel();

    Color color1;
    Color color2;
    IconData icon;

    if (isDisabled) {
      color1 = Colors.grey[800]!;
      color2 = Colors.grey[900]!;
      icon = Icons.hourglass_top_rounded;
    } else if (schoolNotConfigured) {
      color1 = AppTheme.errorRed;
      color2 = AppTheme.darkPurple;
      icon = Icons.location_off_rounded;
    } else if (isReady) {
      if (isCurrentlyCheckedIn) {
        color1 = AppTheme.errorRed;
        color2 = AppTheme.errorRed.withOpacity(0.8);
        icon = Icons.logout_rounded;
      } else {
        color1 = AppTheme.successGreen;
        color2 = AppTheme.successGreen.withOpacity(0.8);
        icon = Icons.login_rounded;
      }
    } else if (isTryAgain) {
      color1 = AppTheme.warningOrange;
      color2 = AppTheme.warningOrange.withOpacity(0.8);
      icon = Icons.refresh_rounded;
    } else {
      color1 = AppTheme.primaryPurple;
      color2 = AppTheme.darkPurple;
      icon = Icons.face_retouching_natural;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color1, color2],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDisabled)
            BoxShadow(
              color: color1.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
              spreadRadius: -2,
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled
              ? null
              : () {
                  if (schoolNotConfigured) {
                    onSchoolLocationNotSet();
                  } else if (isTryAgain) {
                    onRestartFaceAnalysis();
                  } else if (isReady) {
                    onMarkAttendance(
                      isCurrentlyCheckedIn ? 'check_out' : 'check_in',
                    );
                  }
                },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 16),
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
