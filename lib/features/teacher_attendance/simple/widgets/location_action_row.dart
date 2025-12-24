import 'package:flutter/material.dart';

class LocationActionRow extends StatelessWidget {
  final bool isProcessing;
  final bool isFetchingLocation;
  final VoidCallback? onRefresh;
  final VoidCallback? onDiagnose;

  const LocationActionRow({
    super.key,
    required this.isProcessing,
    required this.isFetchingLocation,
    this.onRefresh,
    this.onDiagnose,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: (isProcessing || isFetchingLocation) ? null : onRefresh,
          icon: Icon(Icons.refresh, color: Colors.white, size: 14),
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(),
          tooltip: 'Fetch mobile location',
        ),
        SizedBox(width: 4),
        IconButton(
          onPressed: isProcessing ? null : onDiagnose,
          icon: Icon(Icons.info_outline, color: Colors.white, size: 14),
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(),
          tooltip: 'Check permissions & reason',
        ),
      ],
    );
  }
}


