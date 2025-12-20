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
        onTap: onProfileTap,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              // Enhanced Profile Avatar
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.4),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    const Center(
                      child: Icon(
                        Icons.person_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    // Status Badge
                    Container(
                      decoration: BoxDecoration(
                        color: isEnrolled ? Colors.greenAccent : Colors.amber,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        isEnrolled ? Icons.verified : Icons.warning_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getDisplayName(profile?.fullName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Arrow
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
