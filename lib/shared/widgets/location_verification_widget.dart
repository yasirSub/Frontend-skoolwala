// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:skoolwala/shared/theme/app_theme.dart';
import 'package:skoolwala/features/attendance/services/location_service.dart';

class LocationVerificationWidget extends StatefulWidget {
  final String staffId;
  final String branchId;
  final Function(bool verified, Map<String, dynamic>? data)
  onVerificationComplete;
  final bool autoVerify;
  final Widget? child;

  const LocationVerificationWidget({
    super.key,
    required this.staffId,
    required this.branchId,
    required this.onVerificationComplete,
    this.autoVerify = true,
    this.child,
  });

  @override
  State<LocationVerificationWidget> createState() =>
      _LocationVerificationWidgetState();
}

class _LocationVerificationWidgetState extends State<LocationVerificationWidget>
    with TickerProviderStateMixin {
  bool _isVerifying = false;
  bool _isVerified = false;
  bool _isLocationRequired = false;
  Map<String, dynamic>? _verificationData;
  String? _errorMessage;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkLocationRequirements();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _checkLocationRequirements() async {
    try {
      final isRequired = await LocationService.isLocationVerificationRequired(
        widget.branchId,
      );
      setState(() {
        _isLocationRequired = isRequired;
      });

      if (isRequired && widget.autoVerify) {
        await _verifyLocation();
      } else if (!isRequired) {
        widget.onVerificationComplete(true, null);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to check location requirements: $e';
      });
    }
  }

  Future<void> _verifyLocation() async {
    if (_isVerifying) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    _pulseController.repeat(reverse: true);

    try {
      final result = await LocationService.verifyLocationWithAPI(
        staffId: widget.staffId,
        branchId: widget.branchId,
      );

      _pulseController.stop();

      setState(() {
        _isVerifying = false;
        _isVerified = result['verified'] ?? false;
        _verificationData = result['data'];
        _errorMessage = _isVerified ? null : result['message'];
      });

      widget.onVerificationComplete(_isVerified, _verificationData);
    } catch (e) {
      _pulseController.stop();
      setState(() {
        _isVerifying = false;
        _isVerified = false;
        _errorMessage = 'Location verification failed: $e';
      });
      widget.onVerificationComplete(false, null);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLocationRequired) {
      return widget.child ?? const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.textDark, AppTheme.darkPurple],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getBorderColor(), width: 2),
        boxShadow: [
          BoxShadow(
            color: _getBorderColor().withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isVerifying ? _pulseAnimation.value : 1.0,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getIconColor().withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: _getIconColor(), width: 2),
                      ),
                      child: Icon(_getIcon(), color: _getIconColor(), size: 24),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTitle(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getSubtitle(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Status indicator
          if (_isVerifying) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF00E5FF).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Color(0xFF00E5FF),
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Verifying your location...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_isVerified) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF48BB78).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF48BB78).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF48BB78),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Location Verified',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_verificationData != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${_verificationData!['location_name'] ?? 'Allowed Location'} (${_verificationData!['distance']?.toStringAsFixed(0) ?? '0'}m away)',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE53E3E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE53E3E).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFFE53E3E),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Location Verification Failed',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Action button
          if (!_isVerifying && !_isVerified)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _verifyLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Verify Location',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getBorderColor() {
    if (_isVerifying) return const Color(0xFF00E5FF);
    if (_isVerified) return const Color(0xFF48BB78);
    if (_errorMessage != null) return const Color(0xFFE53E3E);
    return Colors.white.withOpacity(0.3);
  }

  Color _getIconColor() {
    if (_isVerifying) return const Color(0xFF00E5FF);
    if (_isVerified) return const Color(0xFF48BB78);
    if (_errorMessage != null) return const Color(0xFFE53E3E);
    return Colors.white.withOpacity(0.7);
  }

  IconData _getIcon() {
    if (_isVerifying) return Icons.location_searching;
    if (_isVerified) return Icons.location_on;
    if (_errorMessage != null) return Icons.location_off;
    return Icons.location_on_outlined;
  }

  String _getTitle() {
    if (_isVerifying) return 'Verifying Location';
    if (_isVerified) return 'Location Verified';
    if (_errorMessage != null) return 'Location Required';
    return 'Location Verification';
  }

  String _getSubtitle() {
    if (_isVerifying) return 'Please wait while we verify your location';
    if (_isVerified) return 'You are within an allowed location';
    if (_errorMessage != null) {
      return 'You must be at an allowed location to mark attendance';
    }
    return 'Your location will be verified before marking attendance';
  }
}
