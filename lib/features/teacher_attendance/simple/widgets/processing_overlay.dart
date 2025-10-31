import 'package:flutter/material.dart';

class ProcessingOverlay extends StatelessWidget {
  final bool isProcessing;
  final bool isAnalyzingFace;
  final String? faceAnalysisStatus;

  const ProcessingOverlay({
    Key? key,
    required this.isProcessing,
    required this.isAnalyzingFace,
    required this.faceAnalysisStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isProcessing && !isAnalyzingFace) return SizedBox.shrink();
    return Center(
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 10),
            Text(
              isAnalyzingFace
                  ? 'Analyzing face...'
                  : (faceAnalysisStatus?.contains('Validating') == true)
                  ? 'Validating face...'
                  : 'Processing...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
