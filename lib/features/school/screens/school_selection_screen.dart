// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/school_service.dart';
import '../../../shared/models/school.dart';
import '../../auth/screens/login_screen.dart';
import '../../../shared/widgets/animated_face_scan.dart';
import '../../../shared/services/persistent_storage.dart';

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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Stack(
                children: [
                  // Main content column
                  Column(
                    children: [
                      const SizedBox(height: 24),
                      // Logo image
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/Skoolwala Logo.png',
                            height: 60,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: FutureBuilder<List<School>>(
                          future: _schoolsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const SizedBox(
                                height: 52,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
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
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
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
                                          style: const TextStyle(
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedSchool = v),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Proceed button - full width and better styling
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedSchool == null
                                ? Colors.grey[400]
                                : const Color(
                                    0xFF0C9F8E,
                                  ), // Teal/green color to match theme
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: Colors.black.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            disabledBackgroundColor: Colors.grey[300],
                          ),
                          onPressed: _selectedSchool == null
                              ? null
                              : () async {
                                  if (_selectedSchool == null) return;

                                  // Log school logo information before navigation
                                  print(
                                    '🔍 School Selection - Navigating to Login:',
                                  );
                                  print(
                                    '   School Name: ${_selectedSchool!.name}',
                                  );
                                  print(
                                    '   School ID (branch_id): ${_selectedSchool!.id}',
                                  );
                                  print(
                                    '   📝 Text Logo URL: ${_selectedSchool!.textLogo} (NOT USED in Login)',
                                  );
                                  print(
                                    '   ⚙️  SYSTEM LOGO (mainLogo) URL: ${_selectedSchool!.mainLogo} (THIS WILL BE USED)',
                                  );
                                  print(
                                    '   Text Logo is empty: ${_selectedSchool!.textLogo.isEmpty}',
                                  );
                                  print(
                                    '   System Logo is empty: ${_selectedSchool!.mainLogo.isEmpty}',
                                  );
                                  if (_selectedSchool!.mainLogo.isEmpty) {
                                    print(
                                      '   ⚠️  WARNING: System Logo is empty! Login screen will show text only.',
                                    );
                                  } else {
                                    print(
                                      '   ✅ System Logo found! This will be displayed on login screen.',
                                    );
                                  }

                                  // Save selected school to persistent storage
                                  print(
                                    '💾 SchoolSelection: Saving school selection',
                                  );
                                  print(
                                    '   School ID (branch_id): ${_selectedSchool!.id}',
                                  );
                                  print(
                                    '   School Name: ${_selectedSchool!.name}',
                                  );

                                  await PersistentStorage.saveSelectedSchool(
                                    schoolId: _selectedSchool!.id,
                                    schoolName: _selectedSchool!.name,
                                    schoolUrl: _selectedSchool!.url,
                                    textLogo: _selectedSchool!.textLogo,
                                    mainLogo: _selectedSchool!.mainLogo,
                                  );

                                  // Verify it was saved
                                  final saved =
                                      await PersistentStorage.getSelectedSchool();
                                  print(
                                    '✅ SchoolSelection: Verified saved school',
                                  );
                                  print('   Saved ID: ${saved?['id']}');
                                  print('   Saved Name: ${saved?['name']}');

                                  if (mounted) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => LoginScreen(
                                          schoolName: _selectedSchool!.name,
                                          mainLogo: _selectedSchool!.mainLogo,
                                          branchId: _selectedSchool!
                                              .id, // Pass branch_id directly
                                        ),
                                      ),
                                    );
                                  }
                                },
                          child: const Text(
                            'Proceed',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Logo display (if school is selected) - this will scroll with content
                      if (_selectedSchool != null)
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(
                            maxHeight: 200,
                            minHeight: 80,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          alignment: Alignment.center,
                          child: _selectedSchool!.mainLogo.isNotEmpty
                              ? Image.network(
                                  _selectedSchool!.mainLogo,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, _, __) =>
                                      const SizedBox.shrink(),
                                )
                              : const SizedBox.shrink(),
                        ),
                      // Spacer to push content up and make room for fixed animated box
                      SizedBox(height: size.height * 0.35),
                    ],
                  ),
                  // Fixed positioned animated box at the bottom - stays in place regardless of school selection
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 40, // Moved down more from bottom
                    child: Container(
                      width: double.infinity,
                      height: 280,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
