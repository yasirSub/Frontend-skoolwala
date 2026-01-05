import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skoolwala/shared/theme/app_theme.dart';
import 'package:skoolwala/shared/widgets/custom_app_bar.dart';

import 'package:skoolwala/features/attendance/screens/attendance_scan_screen.dart';
import 'package:skoolwala/features/profile/mailbox/screens/mailbox_screen.dart';
import 'package:skoolwala/features/teacher/screens/teacher_schedule_screen.dart';

import '../models/app_notification.dart';
import '../services/notifications_repository.dart';

class NotificationsScreen extends StatefulWidget {
  final NotificationsRepository repository;

  const NotificationsScreen({
    super.key,
    this.repository = const NotificationsRepository(),
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = false;
  List<AppNotification> _items = const [];

  String _plainText(String input) {
    // Strip basic HTML tags and common entities coming from backend notifications.
    final noTags = input.replaceAll(RegExp(r'<[^>]*>'), ' ');
    return noTags
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<void> _handleTap(AppNotification n) async {
    if (!n.isRead) {
      await widget.repository.markAsRead(n.id);
      if (!mounted) return;
      setState(() {
        _items = _items
            .map((x) => x.id == n.id ? x.copyWith(isRead: true) : x)
            .toList(growable: false);
      });
    }

    if (!mounted) return;

    final routeName = n.routeName;
    if (routeName != null && routeName.trim().isNotEmpty) {
      await Navigator.of(context).pushNamed(routeName, arguments: n.routeArgs);
      return;
    }

    switch (n.type.trim().toLowerCase()) {
      case 'mail':
      case 'message':
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const MailboxScreen()));
        return;
      case 'class':
      case 'live_class':
      case 'liveclass':
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TeacherScheduleScreen()),
        );
        return;
      case 'attendance':
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AttendanceScanScreen()));
        return;
      default:
        return;
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });

    try {
      final data = await widget.repository.fetchMyNotifications();
      if (!mounted) return;
      setState(() {
        _items = data;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  IconData _iconForType(String type) {
    switch (type.trim().toLowerCase()) {
      case 'mail':
      case 'message':
        return Icons.mail_outline_rounded;
      case 'class':
      case 'live_class':
      case 'liveclass':
        return Icons.video_camera_front_outlined;
      case 'attendance':
        return Icons.fact_check_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Future<void> _confirmAndClear() async {
    if (_items.isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear notifications?'),
          content: const Text(
            'This will remove all notifications from this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;
    await widget.repository.clearAll();
    if (!mounted) return;
    setState(() {
      _items = const [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFmt = DateFormat('dd MMM, hh:mm a');
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Notifications',
        automaticallyImplyLeading: true,
        actions: [
          IconButton(
            onPressed: _items.isEmpty ? null : _confirmAndClear,
            tooltip: 'Clear all',
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: isDark ? 0.08 : 0.06,
                child: const DecoratedBox(
                  decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                RefreshIndicator(
                  onRefresh: _load,
                  child: _items.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.all(AppTheme.spaceL),
                          children: [
                            SizedBox(
                              height: MediaQuery.sizeOf(context).height * 0.22,
                            ),
                            Center(
                              child: Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 520,
                                ),
                                padding: const EdgeInsets.all(AppTheme.spaceXL),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: AppTheme.radiusLarge,
                                  boxShadow: AppTheme.cardShadow,
                                  border: Border.all(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(isDark ? 0.14 : 0.08),
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: const BoxDecoration(
                                        gradient: AppTheme.primaryGradient,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.notifications_none_rounded,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                    const SizedBox(height: AppTheme.spaceL),
                                    Text(
                                      'No notifications yet',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: AppTheme.spaceXS),
                                    Text(
                                      'Your updates (mail, class, attendance) will appear here.',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withOpacity(0.65),
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: AppTheme.spaceL),
                                    Text(
                                      'Pull down to refresh',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withOpacity(0.55),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(AppTheme.spaceL),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppTheme.spaceM),
                          itemBuilder: (context, index) {
                            final n = _items[index];
                            final icon = _iconForType(n.type);
                            final timeLabel = timeFmt.format(n.createdAt);
                            final typeLabel = n.type.trim().isEmpty
                                ? 'GENERAL'
                                : n.type.trim().toUpperCase();
                            final titleText = _plainText(n.title);
                            final messageText = _plainText(n.message);

                            return Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: AppTheme.radiusLarge,
                                boxShadow: AppTheme.cardShadow,
                                border: Border.all(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(isDark ? 0.14 : 0.08),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: AppTheme.radiusLarge,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () async {
                                      await _handleTap(n);
                                    },
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 96,
                                          decoration: BoxDecoration(
                                            gradient: n.isRead
                                                ? null
                                                : AppTheme.primaryGradient,
                                            color: n.isRead
                                                ? theme.colorScheme.onSurface
                                                      .withOpacity(0.08)
                                                : null,
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              AppTheme.spaceL,
                                              AppTheme.spaceM,
                                              AppTheme.spaceL,
                                              AppTheme.spaceM,
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  width: 44,
                                                  height: 44,
                                                  decoration: BoxDecoration(
                                                    gradient: AppTheme
                                                        .primaryGradient,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          14,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    icon,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: AppTheme.spaceM,
                                                ),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              titleText,
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: theme
                                                                  .textTheme
                                                                  .bodyLarge
                                                                  ?.copyWith(
                                                                    fontWeight:
                                                                        n.isRead
                                                                        ? FontWeight
                                                                              .w700
                                                                        : FontWeight
                                                                              .w900,
                                                                    color: theme
                                                                        .colorScheme
                                                                        .onSurface,
                                                                  ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width:
                                                                AppTheme.spaceS,
                                                          ),
                                                          Text(
                                                            timeLabel,
                                                            style: theme
                                                                .textTheme
                                                                .bodySmall
                                                                ?.copyWith(
                                                                  color: theme
                                                                      .colorScheme
                                                                      .onSurface
                                                                      .withOpacity(
                                                                        0.6,
                                                                      ),
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(
                                                        height:
                                                            AppTheme.spaceXS,
                                                      ),
                                                      Text(
                                                        messageText,
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: theme
                                                            .textTheme
                                                            .bodyMedium
                                                            ?.copyWith(
                                                              color: theme
                                                                  .colorScheme
                                                                  .onSurface
                                                                  .withOpacity(
                                                                    0.7,
                                                                  ),
                                                            ),
                                                      ),
                                                      const SizedBox(
                                                        height: AppTheme.spaceS,
                                                      ),
                                                      Row(
                                                        children: [
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      AppTheme
                                                                          .spaceS,
                                                                  vertical: 4,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color: theme
                                                                  .colorScheme
                                                                  .primary
                                                                  .withOpacity(
                                                                    0.12,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    999,
                                                                  ),
                                                            ),
                                                            child: Text(
                                                              typeLabel,
                                                              style: theme
                                                                  .textTheme
                                                                  .bodySmall
                                                                  ?.copyWith(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w800,
                                                                    color: theme
                                                                        .colorScheme
                                                                        .primary,
                                                                    letterSpacing:
                                                                        0.6,
                                                                  ),
                                                            ),
                                                          ),
                                                          const Spacer(),
                                                          if (!n.isRead)
                                                            Container(
                                                              width: 10,
                                                              height: 10,
                                                              decoration: BoxDecoration(
                                                                color: theme
                                                                    .colorScheme
                                                                    .primary,
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
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
                ),
                if (_loading)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ColoredBox(
                        color: Colors.transparent,
                        child: Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
