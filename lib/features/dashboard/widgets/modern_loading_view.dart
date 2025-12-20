import 'package:flutter/material.dart';
import 'package:skoolwala/shared/widgets/app_loading_indicator.dart';

/// Modern Loading View Widget
/// Uses the standard AppLoadingIndicator
class ModernLoadingView extends StatelessWidget {
  const ModernLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: AppLoadingIndicator(text: 'Loading...', color: Colors.white),
    );
  }
}
