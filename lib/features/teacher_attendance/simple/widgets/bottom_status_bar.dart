import 'package:flutter/material.dart';

class BottomStatusBar extends StatelessWidget {
  final bool isProcessing;
  final bool isAnalyzingFace;
  final bool isFaceValidatedForLoggedInUser;
  final String bottomStatusMessage;

  const BottomStatusBar({
    Key? key,
    required this.isProcessing,
    required this.isAnalyzingFace,
    required this.isFaceValidatedForLoggedInUser,
    required this.bottomStatusMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black87,
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar - only show when processing or analyzing (hide when ready)
          if (isProcessing || isAnalyzingFace)
            LinearProgressIndicator(
              value: isProcessing
                  ? null
                  : isAnalyzingFace
                  ? null // Indeterminate for analyzing
                  : null,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                isProcessing ? Colors.orange : Colors.cyan,
              ),
              minHeight: 2,
            )
          else if (isFaceValidatedForLoggedInUser)
            // Thin green line when face is validated (ready state)
            Container(
              height: 2,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(1),
              ),
            )
          else
            // Hidden when nothing is happening
            SizedBox(height: 2),
          SizedBox(height: 8),
          Text(
            isProcessing
                ? 'Processing attendance...'
                : isAnalyzingFace
                ? 'Analyzing face features...'
                : bottomStatusMessage,
            style: TextStyle(
              color: isFaceValidatedForLoggedInUser
                  ? Colors.green[300]
                  : Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
