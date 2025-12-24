import 'package:flutter/material.dart';
import 'dart:ui';

class BottomStatusBar extends StatelessWidget {
  final bool isProcessing;
  final bool isAnalyzingFace;
  final bool isFaceValidatedForLoggedInUser;
  final String bottomStatusMessage;

  const BottomStatusBar({
    super.key,
    required this.isProcessing,
    required this.isAnalyzingFace,
    required this.isFaceValidatedForLoggedInUser,
    required this.bottomStatusMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D).withOpacity(0.8),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Activity Indicator
                if (isProcessing || isAnalyzingFace)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white.withOpacity(0.05),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isProcessing ? Colors.orangeAccent : Colors.cyanAccent,
                      ),
                      minHeight: 2,
                    ),
                  )
                else
                  Container(
                    height: 2,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isFaceValidatedForLoggedInUser
                          ? Colors.greenAccent.withOpacity(0.3)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isProcessing || isAnalyzingFace)
                      Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isProcessing
                                ? Colors.orangeAccent
                                : Colors.cyanAccent,
                          ),
                        ),
                      ),
                    Flexible(
                      child: Text(
                        (isProcessing
                                ? 'PROCESSING ATTENDANCE...'
                                : isAnalyzingFace
                                ? 'ANALYZING BIOMETRICS...'
                                : bottomStatusMessage)
                            .toUpperCase(),
                        style: TextStyle(
                          color: isFaceValidatedForLoggedInUser
                              ? Colors.greenAccent[400]
                              : Colors.white.withOpacity(0.6),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
