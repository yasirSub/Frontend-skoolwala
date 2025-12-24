import 'package:flutter/material.dart';

class FaceDetectionOverlay extends StatelessWidget {
  final Animation<double> animation;
  final bool isProcessing;
  final bool isAnalyzingFace;

  const FaceDetectionOverlay({
    super.key,
    required this.animation,
    required this.isProcessing,
    required this.isAnalyzingFace,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: 0.9 + (animation.value * 0.1),
                child: Opacity(
                  opacity: 0.8 + (animation.value * 0.2),
                  child: Image.asset(
                    'assets/FACEdect.png',
                    width: 250,
                    height: 250,
                    color: isProcessing ? Colors.orange : Colors.white,
                    colorBlendMode: BlendMode.srcIn,
                  ),
                ),
              ),
              if (isAnalyzingFace || isProcessing)
                Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (isProcessing ? Colors.orange : Colors.white)
                          .withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: CircularProgressIndicator(
                    value: animation.value,
                    strokeWidth: 2,
                    color: isProcessing ? Colors.orange : Colors.white,
                    backgroundColor: Colors.transparent,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
