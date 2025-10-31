import 'package:flutter/material.dart';

class CheckInOutButton extends StatelessWidget {
  final bool schoolLocationLoaded;
  final Map<String, dynamic>? schoolLocation;
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

  @override
  Widget build(BuildContext context) {
    final bool schoolNotConfigured =
        schoolLocationLoaded && schoolLocation == null;

    return SizedBox(
      width: double.infinity,
      child: Container(
        margin: EdgeInsets.only(top: 20),
        child: schoolNotConfigured
            ? ElevatedButton.icon(
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
                icon: Icon(Icons.location_off),
                label: Text('School location not set'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              )
            : ElevatedButton.icon(
                onPressed: (isProcessing || isAnalyzingFace)
                    ? null
                    : (isFaceValidatedForLoggedInUser || _canShowTryAgainButton)
                    ? () {
                        if (schoolLocation == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('School location not set'),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 2),
                            ),
                          );
                          onSchoolLocationNotSet();
                          return;
                        }
                        if (!isFaceValidatedForLoggedInUser &&
                            _canShowTryAgainButton) {
                          onRestartFaceAnalysis();
                        } else {
                          onMarkAttendance(
                            isCurrentlyCheckedIn ? 'check_out' : 'check_in',
                          );
                        }
                      }
                    : null,
                icon: Icon(
                  isFaceValidatedForLoggedInUser ? Icons.logout : Icons.login,
                ),
                label: Text(
                  isProcessing
                      ? 'Processing...'
                      : isAnalyzingFace
                      ? 'Analyzing Face...'
                      : (schoolNotConfigured
                            ? 'School location not set'
                            : (!isFaceValidatedForLoggedInUser &&
                                  ((faceAnalysisStatus?.toLowerCase().contains(
                                            'mismatch',
                                          ) ==
                                          true) ||
                                      (faceAnalysisStatus
                                              ?.toLowerCase()
                                              .contains('not match') ==
                                          true)))
                            ? 'Face not match'
                            : (isFaceValidatedForLoggedInUser
                                  ? (isCurrentlyCheckedIn
                                        ? 'Ready for Check Out'
                                        : 'Ready for Check In')
                                  : 'Face analysis in progress... Please wait for automatic detection')),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: (isProcessing || isAnalyzingFace)
                      ? Colors.grey
                      : (schoolNotConfigured
                            ? Colors.red
                            : (isFaceValidatedForLoggedInUser
                                  ? (isCurrentlyCheckedIn
                                        ? Colors.red
                                        : Colors.green)
                                  : ((_canShowTryAgainButton)
                                        ? Colors.orange
                                        : Colors.grey))),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
      ),
    );
  }
}
