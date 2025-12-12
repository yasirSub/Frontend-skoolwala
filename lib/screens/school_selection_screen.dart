// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skoolwala/features/auth/screens/login_screen.dart';
import 'package:skoolwala/features/school/services/school_service.dart';
import 'package:skoolwala/shared/models/school.dart';
import 'package:skoolwala/shared/widgets/animated_face_scan.dart';
import 'package:skoolwala/shared/services/persistent_storage.dart';

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
    _loadSavedSchool();

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

  /// Load saved school from SharedPreferences
  Future<void> _loadSavedSchool() async {
    try {
      final savedSchool = await PersistentStorage.getSelectedSchool();
      if (savedSchool != null) {
        // Find matching school from the list
        final schools = await _schoolsFuture;
        final matchingSchool = schools.firstWhere(
          (school) => school.id == savedSchool['id'],
          orElse: () => School(
            id: savedSchool['id']!,
            name: savedSchool['name']!,
            url: savedSchool['url']!,
            textLogo: savedSchool['text_logo'] ?? '',
            mainLogo: savedSchool['main_logo'] ?? '',
          ),
        );

        if (mounted) {
          setState(() {
            _selectedSchool = matchingSchool;
          });
        }
      }
    } catch (e) {
      print('Error loading saved school: $e');
    }
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
                        return SizedBox(
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
                          onChanged: (v) {
                            if (v != null) {
                              print('🏫 School Selected: ${v.name}');
                              print('   📝 Text Logo: ${v.textLogo}');
                              print('   ⚙️ Main Logo: ${v.mainLogo}');
                              setState(() => _selectedSchool = v);
                            }
                          },
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
                        : () async {
                            if (_selectedSchool == null) return;

                            // Save selected school to SharedPreferences
                            print('💾 SchoolSelection: Saving school selection');
                            print('   School ID (branch_id): ${_selectedSchool!.id}');
                            print('   School Name: ${_selectedSchool!.name}');
                            
                            await PersistentStorage.saveSelectedSchool(
                              schoolId: _selectedSchool!.id,
                              schoolName: _selectedSchool!.name,
                              schoolUrl: _selectedSchool!.url,
                              textLogo: _selectedSchool!.textLogo,
                              mainLogo: _selectedSchool!.mainLogo,
                            );

                            // Verify it was saved
                            final saved = await PersistentStorage.getSelectedSchool();
                            print('✅ SchoolSelection: Verified saved school');
                            print('   Saved ID: ${saved?['id']}');
                            print('   Saved Name: ${saved?['name']}');

                            if (mounted) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => LoginScreen(
                                    schoolName: _selectedSchool!.name,
                                    mainLogo: _selectedSchool!.mainLogo,
                                    branchId: _selectedSchool!.id, // Pass branch_id directly
                                  ),
                                ),
                              );
                            }
                          },
                    child: const Text('Proceed'),
                  ),
                ),
                const SizedBox(height: 12),
                if (_selectedSchool != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Show text logo if available
                      if (_selectedSchool!.textLogo.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 60),
                          child: Image.network(
                            _selectedSchool!.textLogo,
                            height: 60,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) {
                                print('✅ Text Logo loaded: ${_selectedSchool!.textLogo}');
                                return child;
                              }
                              return const SizedBox(
                                height: 60,
                                child: Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              print('❌ Text Logo failed to load: ${_selectedSchool!.textLogo}');
                              print('   Error: $error');
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      // Show System Logo (mainLogo) if available
                      if (_selectedSchool!.mainLogo.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(
                            top: _selectedSchool!.textLogo.isNotEmpty ? 12 : 0,
                          ),
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 120),
                            child: Image.network(
                              _selectedSchool!.mainLogo,
                              height: 120,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) {
                                  print('✅ Main Logo loaded: ${_selectedSchool!.mainLogo}');
                                  return child;
                                }
                                return const SizedBox(
                                  height: 120,
                                  child: Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                print('❌ Main Logo failed to load: ${_selectedSchool!.mainLogo}');
                                print('   Error: $error');
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ),
                      // Show message if no logos available
                      if (_selectedSchool!.textLogo.isEmpty &&
                          _selectedSchool!.mainLogo.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                            ),
                          ),
                          child: const Text(
                            'No logo available for this school',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
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
