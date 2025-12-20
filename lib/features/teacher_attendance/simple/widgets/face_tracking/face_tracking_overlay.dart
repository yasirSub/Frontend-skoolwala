import 'package:flutter/material.dart';

/// Premium face detection box overlay with scanning animation
class FaceTrackingOverlay extends StatefulWidget {
  final bool isProcessing;
  final bool isAnalyzingFace;

  const FaceTrackingOverlay({
    Key? key,
    this.isProcessing = false,
    this.isAnalyzingFace = false,
  }) : super(key: key);

  @override
  State<FaceTrackingOverlay> createState() => _FaceTrackingOverlayState();
}

class _FaceTrackingOverlayState extends State<FaceTrackingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _scannerController;
  late Animation<double> _scannerAnimation;

  @override
  void initState() {
    super.initState();
    _scannerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scannerAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scannerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Color based on state
    final boxColor = widget.isProcessing
        ? Colors.orange
        : widget.isAnalyzingFace
        ? Colors.cyan
        : Colors.greenAccent[400]!;

    return Center(
      child: Stack(
        children: [
          // Main Container Frame
          Container(
            width: 280,
            height: 360,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: boxColor.withOpacity(0.15), width: 1),
            ),
          ),

          // Outer Pulse Glow
          AnimatedBuilder(
            animation: _scannerController,
            builder: (context, child) {
              return Container(
                width: 280,
                height: 360,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: boxColor.withOpacity(
                        0.1 + (0.1 * _scannerController.value),
                      ),
                      blurRadius: 20 + (10 * _scannerController.value),
                      spreadRadius: 2 * _scannerController.value,
                    ),
                  ],
                ),
              );
            },
          ),

          // Scanning Line
          AnimatedBuilder(
            animation: _scannerAnimation,
            builder: (context, child) {
              return Positioned(
                top: 360 * _scannerAnimation.value,
                left: 10,
                right: 10,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        boxColor.withOpacity(0),
                        boxColor.withOpacity(0.8),
                        boxColor.withOpacity(0),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: boxColor.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Stylish Corner Brackets
          // Top Left
          Positioned(top: 0, left: 0, child: _buildCorner(boxColor, 0)),
          // Top Right
          Positioned(top: 0, right: 0, child: _buildCorner(boxColor, 1)),
          // Bottom Left
          Positioned(bottom: 0, left: 0, child: _buildCorner(boxColor, 3)),
          // Bottom Right
          Positioned(bottom: 0, right: 0, child: _buildCorner(boxColor, 2)),
        ],
      ),
    );
  }

  Widget _buildCorner(Color color, int quadrant) {
    return Transform.rotate(
      angle: quadrant * (3.14159 / 2),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(30)),
          border: Border(
            top: BorderSide(color: color, width: 4),
            left: BorderSide(color: color, width: 4),
          ),
        ),
      ),
    );
  }
}
