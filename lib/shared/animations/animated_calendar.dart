// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

/// Animated calendar widget for monthly view
class AnimatedCalendar extends StatefulWidget {
  final DateTime currentMonth;
  final Map<int, bool> attendanceData; // day -> isPresent
  final Function(DateTime)? onDateSelected;
  final Duration animationDuration;
  final Duration staggerDelay;

  const AnimatedCalendar({
    super.key,
    required this.currentMonth,
    this.attendanceData = const {},
    this.onDateSelected,
    this.animationDuration = const Duration(milliseconds: 300),
    this.staggerDelay = const Duration(milliseconds: 50),
  });

  @override
  State<AnimatedCalendar> createState() => _AnimatedCalendarState();
}

class _AnimatedCalendarState extends State<AnimatedCalendar>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    final daysInMonth = DateTime(
      widget.currentMonth.year,
      widget.currentMonth.month + 1,
      0,
    ).day;
    _controllers = List.generate(
      daysInMonth,
      (index) =>
          AnimationController(duration: widget.animationDuration, vsync: this),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.elasticOut));
    }).toList();

    // Start animations with staggered delays
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(
        Duration(milliseconds: i * widget.staggerDelay.inMilliseconds),
        () {
          if (mounted) {
            _controllers[i].forward();
          }
        },
      );
    }
  }

  @override
  void didUpdateWidget(AnimatedCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentMonth != widget.currentMonth) {
      _disposeControllers();
      _initializeAnimations();
    }
  }

  void _disposeControllers() {
    for (var controller in _controllers) {
      controller.dispose();
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(
      widget.currentMonth.year,
      widget.currentMonth.month + 1,
      0,
    ).day;
    final firstDayOfMonth = DateTime(
      widget.currentMonth.year,
      widget.currentMonth.month,
      1,
    );
    final firstWeekday = firstDayOfMonth.weekday;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Month header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_getMonthName(widget.currentMonth.month)} ${widget.currentMonth.year}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      // Previous month
                      final prevMonth = DateTime(
                        widget.currentMonth.year,
                        widget.currentMonth.month - 1,
                      );
                      widget.onDateSelected?.call(prevMonth);
                    },
                    icon: Icon(
                      Icons.chevron_left,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // Next month
                      final nextMonth = DateTime(
                        widget.currentMonth.year,
                        widget.currentMonth.month + 1,
                      );
                      widget.onDateSelected?.call(nextMonth);
                    },
                    icon: Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Weekday headers
          Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          // Calendar grid
          ...List.generate(6, (weekIndex) {
            return Row(
              children: List.generate(7, (dayIndex) {
                final dayNumber = weekIndex * 7 + dayIndex - firstWeekday + 1;

                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const Expanded(child: SizedBox(height: 40));
                }

                final isPresent = widget.attendanceData[dayNumber] ?? false;
                final isToday = _isToday(dayNumber);
                final animationIndex = dayNumber - 1;

                return Expanded(
                  child: AnimatedBuilder(
                    animation: _animations[animationIndex],
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _animations[animationIndex].value,
                        child: Opacity(
                          opacity: _animations[animationIndex].value,
                          child: GestureDetector(
                            onTap: () {
                              final selectedDate = DateTime(
                                widget.currentMonth.year,
                                widget.currentMonth.month,
                                dayNumber,
                              );
                              widget.onDateSelected?.call(selectedDate);
                            },
                            child: Container(
                              height: 40,
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: isPresent
                                    ? Theme.of(
                                        context,
                                      ).primaryColor.withOpacity(0.2)
                                    : isToday
                                    ? Theme.of(
                                        context,
                                      ).primaryColor.withOpacity(0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: isToday
                                    ? Border.all(
                                        color: Theme.of(context).primaryColor,
                                        width: 2,
                                      )
                                    : null,
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Text(
                                      dayNumber.toString(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isToday
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isPresent
                                            ? Theme.of(context).primaryColor
                                            : Theme.of(
                                                context,
                                              ).textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                  ),
                                  if (isPresent)
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).primaryColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
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
    return months[month - 1];
  }

  bool _isToday(int day) {
    final now = DateTime.now();
    return now.year == widget.currentMonth.year &&
        now.month == widget.currentMonth.month &&
        now.day == day;
  }
}
