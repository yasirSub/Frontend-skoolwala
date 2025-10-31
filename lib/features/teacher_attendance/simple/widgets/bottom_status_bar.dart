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
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.black87,
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: isProcessing
                ? null
                : isAnalyzingFace
                ? 0.5
                : isFaceValidatedForLoggedInUser
                ? 0.2
                : 1.0,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              isProcessing
                  ? Colors.orange
                  : isFaceValidatedForLoggedInUser
                  ? Colors.green
                  : Colors.white,
            ),
          ),
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
