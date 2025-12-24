import 'package:flutter/material.dart';

class LocationStatusPanel extends StatelessWidget {
  final String statusText;
  final bool hasPosition;
  final bool permissionGranted;
  final VoidCallback? onRetry;
  final VoidCallback? onTest;
  final VoidCallback? onReAnalyzeFace;
  final bool showReAnalyze;

  const LocationStatusPanel({
    super.key,
    required this.statusText,
    required this.hasPosition,
    required this.permissionGranted,
    this.onRetry,
    this.onTest,
    this.onReAnalyzeFace,
    this.showReAnalyze = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = hasPosition
        ? Colors.green[900]!
        : permissionGranted
        ? Colors.orange[900]!
        : Colors.red[900]!;
    final IconData icon = hasPosition
        ? Icons.location_on
        : permissionGranted
        ? Icons.location_searching
        : Icons.location_off;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10),
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: onRetry,
                icon: Icon(Icons.refresh, color: Colors.white, size: 16),
                tooltip: 'Retry Location Detection',
              ),
              IconButton(
                onPressed: onTest,
                icon: Icon(
                  Icons.location_searching,
                  color: Colors.white,
                  size: 16,
                ),
                tooltip: 'Test Location (Debug)',
              ),
              if (showReAnalyze)
                IconButton(
                  onPressed: onReAnalyzeFace,
                  icon: Icon(
                    Icons.face_retouching_natural_outlined,
                    color: Colors.white,
                    size: 16,
                  ),
                  tooltip: 'Re-analyze Face',
                ),
            ],
          ),
        ],
      ),
    );
  }
}
