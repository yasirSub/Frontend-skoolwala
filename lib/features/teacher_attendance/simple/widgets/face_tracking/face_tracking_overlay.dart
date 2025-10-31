import 'package:flutter/material.dart';

/// Simple face detection box overlay
class FaceTrackingOverlay extends StatelessWidget {
  final bool isProcessing;
  final bool isAnalyzingFace;

  const FaceTrackingOverlay({
    Key? key,
    this.isProcessing = false,
    this.isAnalyzingFace = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Color based on state
    final boxColor = isProcessing
        ? Colors.orange
        : isAnalyzingFace
        ? Colors.cyan
        : Colors.green;

    return Center(
      child: Container(
        width: 280,
        height: 360,
        decoration: BoxDecoration(
          color: Colors.transparent, // No fill - completely transparent inside
          border: Border.all(color: boxColor.withOpacity(0.8), width: 2),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: boxColor.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
      ),
    );
  }
}
