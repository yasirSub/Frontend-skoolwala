// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skoolwala/features/auth/screens/login_screen.dart';
import 'package:skoolwala/features/school/services/school_service.dart';
import 'package:skoolwala/shared/models/school.dart';
import 'package:skoolwala/shared/widgets/animated_face_scan.dart';

class SchoolSelectionScreen extends StatefulWidget {
  const SchoolSelectionScreen({super.key});

  @override
  State<SchoolSelectionScreen> createState() => _SchoolSelectionScreenState();
}

class _SchoolSelectionScreenState extends State<SchoolSelectionScreen>
    with SingleTickerProviderStateMixin {
  final SchoolService _service = const SchoolService();
  late Future<List<School>> _schoolsFuture;
  School? _selectedSchool;
  late final AnimationController _scanController;
  double _scanProgress = 0.0; // 0..1

  @override
  void initState() {
    super.initState();
    _schoolsFuture = _service.fetchSchools();

    // Make status bar transparent
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    _scanController =
        AnimationController(
            vsync: this,
            duration: const Duration(seconds: 3),
            lowerBound: 0,
            upperBound: 1,
          )
          ..addListener(() {
            setState(() {
              _scanProgress = _scanController.value;
            });
          })
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E2A39), Color(0xFF0C9F8E)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Logo placeholder
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'SKOOLWALA',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: FutureBuilder<List<School>>(
                    future: _schoolsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 52,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.error,
                                color: Colors.red,
                                size: 48,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Failed to load schools: ${snapshot.error}',
                                style: const TextStyle(color: Colors.black),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }
                      final schools = snapshot.data ?? const <School>[];
                      return DropdownButtonHideUnderline(
                        child: DropdownButton<School>(
                          isExpanded: true,
                          hint: const Text(
                            'Select School',
                            style: TextStyle(color: Colors.black54),
                          ),
                          value: _selectedSchool,
                          style: const TextStyle(color: Colors.black),
                          dropdownColor: Colors.white,
                          items: schools
                              .map(
                                (school) => DropdownMenuItem<School>(
                                  value: school,
                                  child: Text(
                                    school.name,
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _selectedSchool = v),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 160,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4056),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _selectedSchool == null
                        ? null
                        : () {
                            if (_selectedSchool == null) return;
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => LoginScreen(
                                  schoolName: _selectedSchool!.name,
                                ),
                              ),
                            );
                          },
                    child: const Text('Proceed'),
                  ),
                ),
                const Spacer(),
                // Face scan image area - transparent for chroma key
                Container(
                  width: size.width * 0.8,
                  height: size.height * 0.45,
                  decoration: BoxDecoration(
                    color: Colors.transparent, // Transparent background
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.tealAccent.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final lineHeight = 3.0;
                      final travel = constraints.maxHeight - lineHeight;
                      final top = travel * _scanProgress;
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          // Pure Flutter animated face scan (no video)
                          const AnimatedFaceScan(),
                          // Scan overlay to match the rest of the UI
                          Positioned(
                            left: 0,
                            right: 0,
                            top: top,
                            child: Container(
                              height: lineHeight,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Color(0xFF00FFE0),
                                    Colors.transparent,
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
