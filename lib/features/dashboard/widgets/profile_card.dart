import 'package:flutter/material.dart';
import 'package:skoolwala/features/dashboard/models/profile.dart';
import 'package:skoolwala/features/attendance/screens/multi_angle_enroll_screen.dart';

/// Profile Card Widget for Dashboard
/// Displays teacher profile with enrollment status and actions
class ProfileCard extends StatelessWidget {
  final Profile? profile;
  final VoidCallback? onProfileTap;
  final bool isEnrolled;

  const ProfileCard({
    super.key,
    this.profile,
    this.onProfileTap,
    this.isEnrolled = false,
  });

  String _getDisplayName(String? fullName) {
    if (fullName == null || fullName.isEmpty) return 'Teacher';

    // If the fullName contains an email (has @ symbol), extract just the name part
    if (fullName.contains('@')) {
      // Split by common separators and take the first part
      final parts = fullName.split(RegExp(r'[@\s]+'));
      return parts.first.isNotEmpty ? parts.first : 'Teacher';
    }

    return fullName;
  }

  Future<void> _openMultiEnroll(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MultiAngleEnrollScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          print('🔍 ProfileCard Debug - Card tapped');
          onProfileTap?.call();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667EEA).withOpacity(0.25),
                blurRadius: 25,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: const Color(0xFF764BA2).withOpacity(0.15),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Row(
            children: [
              // Enhanced Profile Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.3),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    const Icon(
                      Icons.person_rounded,
                      size: 28,
                      color: Colors.white,
                    ),
                    // Enhanced verification badge
                    Container(
                      decoration: BoxDecoration(
                        color: isEnrolled ? Colors.green : Colors.orange,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: (isEnrolled ? Colors.green : Colors.orange)
                                .withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Icon(
                        isEnrolled ? Icons.verified : Icons.schedule,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Enhanced Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _getDisplayName(profile?.fullName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Enhanced badges
                  ],
                ),
              ),
              // Multi-enroll shortcut (only show when not enrolled)
              if (!isEnrolled)
                GestureDetector(
                  onTap: () => _openMultiEnroll(context),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(seconds: 2),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(
                              0.4 + (value * 0.3),
                            ),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.5 * value),
                              blurRadius: 15,
                              offset: const Offset(0, 2),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.face_retouching_natural,
                          color: Colors.white.withOpacity(1.0),
                          size: 20,
                        ),
                      );
                    },
                    onEnd: () {
                      // Restart animation
                    },
                  ),
                ),
              const SizedBox(width: 8),
              // Enhanced arrow button
              GestureDetector(
                onTap: onProfileTap,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
