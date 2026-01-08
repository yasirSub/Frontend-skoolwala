import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:skoolwala/shared/theme/app_theme.dart';
import 'package:skoolwala/shared/widgets/app_loading_indicator.dart';

import '../models/mailbox_recipient.dart';
import '../services/mailbox_api_service.dart';

class MailboxComposeScreen extends StatefulWidget {
  final MailboxApiService service;

  const MailboxComposeScreen({super.key, required this.service});

  @override
  State<MailboxComposeScreen> createState() => _MailboxComposeScreenState();
}

class _MailboxComposeScreenState extends State<MailboxComposeScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  final FocusNode _subjectFocusNode = FocusNode();
  final FocusNode _bodyFocusNode = FocusNode();

  int? _roleId;
  MailboxRecipient? _recipient;
  bool _loadingRecipients = false;
  bool _sending = false;
  List<MailboxRecipient> _recipients = const [];

  late final AnimationController _glowController;
  late final Animation<double> _glowScale;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _glowScale = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    _subjectFocusNode.dispose();
    _bodyFocusNode.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  InputDecoration _glassInputDecoration({
    required String hint,
    required Color onPrimary,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    final border = OutlineInputBorder(
      borderRadius: AppTheme.radiusMedium,
      borderSide: BorderSide(color: onPrimary.withOpacity(0.18), width: 1),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: onPrimary.withOpacity(0.65)),
      prefixIcon: prefixIcon == null
          ? null
          : IconTheme(
              data: IconThemeData(color: onPrimary.withOpacity(0.85)),
              child: prefixIcon,
            ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: onPrimary.withOpacity(0.10),
      enabledBorder: border,
      border: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: AppTheme.radiusMedium,
        borderSide: BorderSide(color: onPrimary.withOpacity(0.55), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppTheme.radiusMedium,
        borderSide: BorderSide(color: AppTheme.errorRed, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppTheme.radiusMedium,
        borderSide: BorderSide(color: AppTheme.errorRed, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceL,
        vertical: AppTheme.spaceL,
      ),
    );
  }

  Widget _recipientMenuItem(
    MailboxRecipient r,
    TextStyle? titleStyle,
    TextStyle? subtitleStyle,
  ) {
    final subtitleParts = <String>[];
    final email = r.email?.trim();
    final mobile = r.mobile?.trim();
    if (email != null && email.isNotEmpty) subtitleParts.add(email);
    if (mobile != null && mobile.isNotEmpty) subtitleParts.add(mobile);
    final subtitle = subtitleParts.join(' • ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          r.name.isEmpty ? '(Unnamed)' : r.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: titleStyle,
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: subtitleStyle,
          ),
        ],
      ],
    );
  }

  Future<void> _loadRecipients(int roleId) async {
    setState(() {
      _loadingRecipients = true;
      _recipient = null;
      _recipients = const [];
    });

    try {
      final recipients = await widget.service.getRecipients(roleId: roleId);
      if (!mounted) return;
      setState(() {
        _recipients = recipients;
      });
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _loadingRecipients = false;
        });
      }
    }
  }

  Future<void> _send() async {
    final roleId = _roleId;
    final recipient = _recipient;
    final subject = _subjectController.text.trim();
    final body = _bodyController.text.trim();

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      _showSnack('Please fix the highlighted fields.');
      return;
    }

    if (roleId == null) {
      _showSnack('Please select a role.');
      return;
    }
    if (recipient == null) {
      _showSnack('Please select a receiver.');
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _sending = true;
    });

    try {
      await widget.service.sendMessage(
        receiverRoleId: roleId,
        receiverId: recipient.id,
        subject: subject,
        body: body,
      );

      if (!mounted) return;
      _subjectController.clear();
      _bodyController.clear();
      setState(() {
        _recipient = null;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Message sent.')));
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    const composeFg = Colors.white;
    const composeMuted = Colors.white70;
    const composeLight = Colors.white54;

    final menuTitleStyle = theme.textTheme.bodyMedium?.copyWith(
      color: composeFg,
      fontWeight: FontWeight.w700,
    );
    final menuSubtitleStyle = theme.textTheme.bodySmall?.copyWith(
      color: composeMuted,
    );

    final roleItems = const <MapEntry<int, String>>[
      MapEntry(1, 'Admin'),
      MapEntry(2, 'Staff'),
      MapEntry(3, 'Teacher'),
      MapEntry(4, 'Accountant'),
      MapEntry(5, 'Librarian'),
      MapEntry(6, 'Parent'),
      MapEntry(7, 'Student'),
    ];

    final titleStyle = theme.textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w700,
      color: composeFg,
    );
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
      color: composeMuted,
    );

    final cardGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.white.withOpacity(0.42), Colors.white.withOpacity(0.18)],
    );
    final cardBorderColor = Colors.white.withOpacity(0.22);
    final buttonShadow = BoxShadow(
      color: Colors.black.withOpacity(0.35),
      blurRadius: 25,
      offset: const Offset(0, 12),
    );

    Widget glowCircle({
      required Alignment alignment,
      required double size,
      double scale = 1,
      required double opacity,
    }) {
      return Align(
        alignment: alignment,
        child: Transform.scale(
          scale: scale,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [Colors.white.withOpacity(opacity), Colors.transparent],
              ),
            ),
          ),
        ),
      );
    }

    final viewInsetsBottom = MediaQuery.viewInsetsOf(context).bottom;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
        AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            final baseScale = _glowScale.value;
            final topLeftScale = 1 + (baseScale - 1) * 0.6;
            final centerScale = 1 + (baseScale - 1) * 1.05;
            final bottomScale = 1 + (baseScale - 1) * 0.8;
            final topLeftOpacity = (0.24 + (baseScale - 0.95) * 0.9).clamp(
              0.18,
              0.5,
            );
            final centerOpacity = (0.3 + (baseScale - 0.95) * 0.95).clamp(
              0.2,
              0.6,
            );
            final bottomOpacity = (0.22 + (baseScale - 0.95) * 0.75).clamp(
              0.16,
              0.45,
            );
            return Stack(
              children: [
                glowCircle(
                  alignment: Alignment.topLeft,
                  size: 120,
                  scale: topLeftScale,
                  opacity: topLeftOpacity,
                ),
                glowCircle(
                  alignment: Alignment.centerRight,
                  size: 180,
                  scale: centerScale,
                  opacity: centerOpacity,
                ),
                glowCircle(
                  alignment: Alignment.bottomLeft,
                  size: 200,
                  scale: bottomScale,
                  opacity: bottomOpacity,
                ),
              ],
            );
          },
        ),
        SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              AppTheme.spaceL,
              AppTheme.space2XL,
              AppTheme.spaceL,
              AppTheme.space2XL + viewInsetsBottom,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Form(
                  key: _formKey,
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOutCubic,
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, t, child) {
                      final y = (1 - t) * 14;
                      return Opacity(
                        opacity: t.clamp(0, 1),
                        child: Transform.translate(
                          offset: Offset(0, y),
                          child: child,
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: AppTheme.radiusLarge,
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: cardGradient,
                            borderRadius: AppTheme.radiusLarge,
                            border: Border.all(
                              color: cardBorderColor,
                              width: 1,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 25,
                                offset: Offset(0, 12),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(AppTheme.spaceL),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(
                                      AppTheme.spaceS,
                                    ),
                                    child: Icon(
                                      Icons.edit_rounded,
                                      color: composeFg,
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.spaceS),
                                  Text(
                                    'Compose',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: composeFg,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.spaceXS),
                              Container(
                                height: 4,
                                width: 96,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  gradient: AppTheme.primaryGradient,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.darkPurple.withOpacity(
                                        0.6,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppTheme.spaceL),
                              Text(
                                'Reach out instantly to admins, staff, or parents.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: composeMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spaceL),
                              DropdownButtonFormField<int>(
                                value: _roleId,
                                isExpanded: true,
                                dropdownColor: surface,
                                iconEnabledColor: composeFg,
                                iconDisabledColor: composeLight,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: composeFg,
                                  fontWeight: FontWeight.w700,
                                ),
                                selectedItemBuilder: (context) => roleItems
                                    .map(
                                      (e) => Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          e.value,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: composeFg,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                decoration: _glassInputDecoration(
                                  hint: 'Role',
                                  onPrimary: composeMuted,
                                  prefixIcon: const Icon(Icons.badge_rounded),
                                ),
                                validator: (value) {
                                  if (value == null) return 'Select a role';
                                  return null;
                                },
                                items: roleItems
                                    .map(
                                      (e) => DropdownMenuItem<int>(
                                        value: e.key,
                                        child: Text(
                                          e.value,
                                          style: menuTitleStyle,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _sending
                                    ? null
                                    : (value) async {
                                        if (value == null) return;
                                        setState(() {
                                          _roleId = value;
                                        });
                                        await _loadRecipients(value);
                                      },
                              ),
                              const SizedBox(height: AppTheme.spaceM),
                              if (_loadingRecipients)
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: AppTheme.spaceS,
                                  ),
                                  child: AppLoadingIndicator(size: 28),
                                )
                              else
                                DropdownButtonFormField<MailboxRecipient>(
                                  value: _recipient,
                                  isExpanded: true,
                                  dropdownColor: surface,
                                  iconEnabledColor: composeFg,
                                  iconDisabledColor: composeLight,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: composeFg,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  selectedItemBuilder: (context) => _recipients
                                      .map(
                                        (r) => Align(
                                          alignment: Alignment.centerLeft,
                                          child: _recipientMenuItem(
                                            r,
                                            titleStyle,
                                            subtitleStyle,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  decoration: _glassInputDecoration(
                                    hint: _roleId == null
                                        ? 'Select a role first'
                                        : (_recipients.isEmpty
                                              ? 'No receivers available'
                                              : 'Receiver'),
                                    onPrimary: composeMuted,
                                    prefixIcon: const Icon(
                                      Icons.person_rounded,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (_roleId == null) return null;
                                    if (_recipients.isEmpty)
                                      return 'No receivers available';
                                    if (value == null)
                                      return 'Select a receiver';
                                    return null;
                                  },
                                  items: _recipients
                                      .map(
                                        (r) => DropdownMenuItem(
                                          value: r,
                                          child: _recipientMenuItem(
                                            r,
                                            menuTitleStyle,
                                            menuSubtitleStyle,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged:
                                      (_sending ||
                                          _roleId == null ||
                                          _recipients.isEmpty)
                                      ? null
                                      : (value) {
                                          setState(() {
                                            _recipient = value;
                                          });
                                        },
                                ),
                              const SizedBox(height: AppTheme.spaceM),
                              TextFormField(
                                controller: _subjectController,
                                focusNode: _subjectFocusNode,
                                textInputAction: TextInputAction.next,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: composeFg,
                                  fontWeight: FontWeight.w700,
                                ),
                                cursorColor: composeFg,
                                decoration: _glassInputDecoration(
                                  hint: 'Subject',
                                  onPrimary: composeMuted,
                                  prefixIcon: const Icon(Icons.subject_rounded),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Subject is required';
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) {
                                  _bodyFocusNode.requestFocus();
                                },
                              ),
                              const SizedBox(height: AppTheme.spaceM),
                              TextFormField(
                                controller: _bodyController,
                                focusNode: _bodyFocusNode,
                                textInputAction: TextInputAction.newline,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: composeFg,
                                  fontWeight: FontWeight.w600,
                                ),
                                cursorColor: composeFg,
                                decoration: _glassInputDecoration(
                                  hint: 'Message',
                                  onPrimary: composeMuted,
                                  prefixIcon: const Icon(Icons.message_rounded),
                                ),
                                minLines: 5,
                                maxLines: 10,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Message is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppTheme.spaceL),
                              SizedBox(
                                height: 56,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    borderRadius: AppTheme.radiusLarge,
                                    boxShadow: [buttonShadow],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _sending ? null : _send,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: AppTheme.radiusLarge,
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    child: _sending
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text('SEND MESSAGE'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
