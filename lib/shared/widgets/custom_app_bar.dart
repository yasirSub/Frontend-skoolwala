import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

/// Custom App Bar Widget
/// Reusable top app bar with modern design
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool centerTitle;
  final bool automaticallyImplyLeading;
  final Widget? leading;
  final List<Widget> actions;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final Widget? flexibleSpace;
  final PreferredSizeWidget? bottom;
  final double? titleSpacing;
  final Color? primaryColor;
  final Gradient? gradient;
  final bool showThemeToggle;
  final bool showRoundedCorners;

  const CustomAppBar({
    super.key,
    required this.title,
    this.centerTitle = true,
    this.automaticallyImplyLeading = false,
    this.leading,
    this.actions = const [],
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.flexibleSpace,
    this.bottom,
    this.titleSpacing,
    this.primaryColor,
    this.gradient,
    this.showThemeToggle = false,
    this.showRoundedCorners = true,
  });

  @override
  Widget build(BuildContext context) {
    // Adapt colors based on theme
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultPrimaryColor =
        primaryColor ??
        (isDark ? const Color(0xFF2A2A2A) : const Color(0xFF1A1F3E));
    final defaultForegroundColor =
        foregroundColor ?? (isDark ? Colors.white : Colors.white);

    // Build actions list with optional theme toggle
    List<Widget> appBarActions = List.from(actions);
    if (showThemeToggle) {
      appBarActions.add(
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return IconButton(
              onPressed: () => themeProvider.toggleTheme(),
              icon: Icon(
                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: defaultForegroundColor,
              ),
              tooltip: themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
            );
          },
        ),
      );
    }

    return PreferredSize(
      preferredSize: preferredSize,
      child: showRoundedCorners
          ? ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient:
                      gradient ??
                      LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          defaultPrimaryColor,
                          defaultPrimaryColor.withOpacity(0.95),
                        ],
                      ),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.black : defaultPrimaryColor)
                          .withOpacity(isDark ? 0.5 : 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: elevation ?? 0,
                  centerTitle: centerTitle,
                  automaticallyImplyLeading: automaticallyImplyLeading,
                  leading: leading,
                  actions: appBarActions,
                  title: Text(
                    title,
                    style: TextStyle(
                      color: defaultForegroundColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  titleSpacing: titleSpacing,
                  flexibleSpace: flexibleSpace,
                  bottom: bottom,
                ),
              ),
            )
          : AppBar(
              backgroundColor: backgroundColor ?? defaultPrimaryColor,
              foregroundColor: foregroundColor ?? defaultForegroundColor,
              elevation: elevation ?? 0,
              centerTitle: centerTitle,
              automaticallyImplyLeading: automaticallyImplyLeading,
              leading: leading,
              actions: appBarActions,
              title: Text(
                title,
                style: TextStyle(
                  color: foregroundColor ?? defaultForegroundColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              titleSpacing: titleSpacing,
              flexibleSpace: flexibleSpace,
              bottom: bottom,
            ),
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}

/// Simple App Bar for basic screens
class SimpleAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget> actions;

  const SimpleAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.onBackPressed,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      title: Text(title),
      backgroundColor: isDark
          ? const Color(0xFF2A2A2A)
          : const Color(0xFF1A1F3E),
      foregroundColor: Colors.white,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            )
          : null,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Transparent App Bar for overlays or special screens
class TransparentAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget> actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const TransparentAppBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.showBackButton = true,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            )
          : null,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
