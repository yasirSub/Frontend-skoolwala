import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable Loading Indicator Widget
/// A polished circular progress indicator with optional text
class AppLoadingIndicator extends StatelessWidget {
  final double? size;
  final Color? color;
  final String? text;
  final double? fontSize;

  const AppLoadingIndicator({
    super.key,
    this.size,
    this.color,
    this.text,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size ?? 40,
            height: size ?? 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? AppTheme.primaryPurple,
              ),
              backgroundColor: (color ?? AppTheme.primaryPurple).withOpacity(
                0.2,
              ),
            ),
          ),
          if (text != null) ...[
            const SizedBox(height: 16),
            Text(
              text!,
              style: TextStyle(
                color: color ?? AppTheme.textGray,
                fontSize: fontSize ?? 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
