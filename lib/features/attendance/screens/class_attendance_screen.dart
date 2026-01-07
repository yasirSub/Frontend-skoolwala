import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:skoolwala/shared/theme/app_theme.dart';
import 'package:skoolwala/shared/widgets/custom_app_bar.dart';

enum StudentAttendanceStatus { unmarked, present, absent }

class ClassAttendanceStudent {
  final String id;
  final String name;
  final int? roll;
  final StudentAttendanceStatus status;

  const ClassAttendanceStudent({
    required this.id,
    required this.name,
    this.roll,
    this.status = StudentAttendanceStatus.unmarked,
  });

  ClassAttendanceStudent copyWith({
    String? id,
    String? name,
    int? roll,
    StudentAttendanceStatus? status,
  }) {
    return ClassAttendanceStudent(
      id: id ?? this.id,
      name: name ?? this.name,
      roll: roll ?? this.roll,
      status: status ?? this.status,
    );
  }
}

class ClassAttendanceScreen extends StatefulWidget {
  final String classTitle; // e.g. "Class 1 - A"
  final DateTime initialDate;
  final List<ClassAttendanceStudent> students;

  const ClassAttendanceScreen({
    super.key,
    required this.classTitle,
    required this.initialDate,
    required this.students,
  });

  @override
  State<ClassAttendanceScreen> createState() => _ClassAttendanceScreenState();
}

class _ClassAttendanceScreenState extends State<ClassAttendanceScreen> {
  late DateTime _selectedDate;
  late List<ClassAttendanceStudent> _students;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _students = List.of(widget.students);

    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _total => _students.length;

  int get _present => _students
      .where((s) => s.status == StudentAttendanceStatus.present)
      .length;

  int get _absent =>
      _students.where((s) => s.status == StudentAttendanceStatus.absent).length;

  int get _marked => _students
      .where((s) => s.status != StudentAttendanceStatus.unmarked)
      .length;

  double get _progress => _total == 0 ? 0 : _marked / _total;

  List<ClassAttendanceStudent> get _filteredStudents {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _students;
    return _students
        .where((s) => s.name.toLowerCase().contains(query))
        .toList();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _selectedDate = picked;
    });
  }

  void _setStudentStatus(String id, StudentAttendanceStatus status) {
    setState(() {
      _students = _students
          .map((s) => s.id == id ? s.copyWith(status: status) : s)
          .toList();
    });
  }

  String _formatDate(DateTime date) {
    // Minimal formatting without intl dependency usage here.
    const months = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        showRoundedCorners: false,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.dashboardPrimaryLight, AppTheme.dashboardPrimary],
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
        titleWidget: _HeaderTitle(
          classTitle: widget.classTitle,
          dateText: _formatDate(_selectedDate),
          onTapDate: _pickDate,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.dashboardPrimaryLight,
              AppTheme.dashboardPrimary,
              isDark ? Colors.black : AppTheme.darkPurple.withOpacity(0.9),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _GlassCard(
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 6,
                          backgroundColor: Colors.white.withOpacity(0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withOpacity(0.35),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _Metric(
                            value: _total.toString(),
                            label: 'TOTAL',
                            color: Colors.white.withOpacity(0.9),
                          ),
                          _Metric(
                            value: _present.toString(),
                            label: 'PRESENT',
                            color: AppTheme.accentGreen,
                          ),
                          _Metric(
                            value: _absent.toString(),
                            label: 'ABSENT',
                            color: AppTheme.accentRed,
                          ),
                          _Metric(
                            value: _marked.toString(),
                            label: 'MARKED',
                            color: AppTheme.accentCyan,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _GlassCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search,
                              color: Colors.white.withOpacity(0.75),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search students...',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.45),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _RoundIconButton(
                      icon: Icons.checklist,
                      onPressed: () {
                        // Intentionally left minimal: UI only.
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: _filteredStudents.isEmpty
                    ? Center(
                        child: Text(
                          'No students',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                        itemCount: _filteredStudents.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final s = _filteredStudents[index];
                          return _StudentRow(
                            student: s,
                            onMarkPresent: () => _setStudentStatus(
                              s.id,
                              StudentAttendanceStatus.present,
                            ),
                            onMarkAbsent: () => _setStudentStatus(
                              s.id,
                              StudentAttendanceStatus.absent,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: _FinalizeButton(
            enabled: _total > 0,
            onPressed: () {
              // UI-only for now. Wire to ApiConfig.markStudentAttendanceBulk later.
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
  }
}

class _HeaderTitle extends StatelessWidget {
  final String classTitle;
  final String dateText;
  final VoidCallback onTapDate;

  const _HeaderTitle({
    required this.classTitle,
    required this.dateText,
    required this.onTapDate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          classTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTapDate,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dateText,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white.withOpacity(0.85),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PillChip extends StatelessWidget {
  final String label;

  const _PillChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppTheme.darkPurple.withOpacity(0.35),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.10), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _Metric({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _RoundIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Material(
        color: Colors.white.withOpacity(0.14),
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 52,
            height: 52,
            child: Icon(icon, color: Colors.white.withOpacity(0.9)),
          ),
        ),
      ),
    );
  }
}

class _StudentRow extends StatelessWidget {
  final ClassAttendanceStudent student;
  final VoidCallback onMarkPresent;
  final VoidCallback onMarkAbsent;

  const _StudentRow({
    required this.student,
    required this.onMarkPresent,
    required this.onMarkAbsent,
  });

  Color _statusTint(StudentAttendanceStatus status) {
    switch (status) {
      case StudentAttendanceStatus.present:
        return AppTheme.accentGreen;
      case StudentAttendanceStatus.absent:
        return AppTheme.accentRed;
      case StudentAttendanceStatus.unmarked:
        return Colors.white.withOpacity(0.22);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tint = _statusTint(student.status);

    return _GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
              border: Border.all(
                color: Colors.white.withOpacity(0.28),
                width: 2,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
                width: 1,
              ),
            ),
            child: Icon(Icons.person, color: Colors.white.withOpacity(0.75)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.10),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'ROLL: ${student.roll ?? '-'}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _ActionSquareButton(
            icon: Icons.check,
            tint: AppTheme.accentGreen,
            isActive: student.status == StudentAttendanceStatus.present,
            onPressed: onMarkPresent,
          ),
          const SizedBox(width: 10),
          _ActionSquareButton(
            icon: Icons.close,
            tint: AppTheme.accentRed,
            isActive: student.status == StudentAttendanceStatus.absent,
            onPressed: onMarkAbsent,
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.more_vert, color: Colors.white.withOpacity(0.65)),
          ),
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tint.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionSquareButton extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final bool isActive;
  final VoidCallback onPressed;

  const _ActionSquareButton({
    required this.icon,
    required this.tint,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: Colors.white.withOpacity(0.08),
        child: InkWell(
          onTap: onPressed,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              border: Border.all(
                color: (isActive ? tint : Colors.white.withOpacity(0.14)),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: isActive ? tint : tint.withOpacity(0.75),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _FinalizeButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;

  const _FinalizeButton({required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(999),
          boxShadow: AppTheme.buttonShadow,
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          onPressed: enabled ? onPressed : null,
          icon: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white),
          ),
          label: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'FINALIZE ATTENDANCE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
