import 'package:flutter/material.dart';
import '../../themes/theme_extensions.dart';

/// Custom app bar with gamification styling
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {

  const CustomAppBar({
    required this.title, super.key,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.showMenuButton = false,
    this.onMenuPressed,
    this.backgroundColor,
    this.showGradient = false,
    this.elevation = 0,
  });
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final bool showMenuButton;
  final VoidCallback? onMenuPressed;
  final Color? backgroundColor;
  final bool showGradient;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final appBarColor =
        backgroundColor ?? Theme.of(context).colorScheme.surface;

    return DecoratedBox(
      decoration: showGradient
          ? BoxDecoration(gradient: context.xpGradient)
          : BoxDecoration(
              color: appBarColor,
              boxShadow: elevation > 0
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: elevation * 2,
                        offset: Offset(0, elevation),
                      ),
                    ]
                  : null,
            ),
      child: AppBar(
        title: Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: showGradient
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: _buildLeading(context),
        actions: actions,
        iconTheme: IconThemeData(
          color: showGradient
              ? Colors.white
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget? _buildLeading(BuildContext context) {
    if (leading != null) return leading;

    if (showMenuButton) {
      return IconButton(
        onPressed: onMenuPressed ?? () => Scaffold.of(context).openDrawer(),
        icon: const Icon(Icons.menu),
        tooltip: 'Menu',
      );
    }

    if (showBackButton && Navigator.of(context).canPop()) {
      return IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Back',
      );
    }

    return null;
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// App bar with XP progress indicator
class XPAppBar extends StatelessWidget implements PreferredSizeWidget {

  const XPAppBar({
    required this.title, required this.currentXP, required this.maxXP, required this.level, super.key,
    this.actions,
    this.showMenuButton = false,
    this.onMenuPressed,
  });
  final String title;
  final int currentXP;
  final int maxXP;
  final int level;
  final List<Widget>? actions;
  final bool showMenuButton;
  final VoidCallback? onMenuPressed;

  @override
  Widget build(BuildContext context) => DecoratedBox(
      decoration: BoxDecoration(gradient: context.xpGradient),
      child: SafeArea(
        child: Column(
          children: [
            // Main app bar
            SizedBox(
              height: kToolbarHeight,
              child: Row(
                children: [
                  if (showMenuButton)
                    IconButton(
                      onPressed:
                          onMenuPressed ??
                          () => Scaffold.of(context).openDrawer(),
                      icon: const Icon(Icons.menu, color: Colors.white),
                      tooltip: 'Menu',
                    )
                  else if (Navigator.of(context).canPop())
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      tooltip: 'Back',
                    ),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (actions != null) ...actions!,
                ],
              ),
            ),
            // XP progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  // Level indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'LV $level',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // XP progress
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'XP Progress',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            Text(
                              '$currentXP / $maxXP',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: FractionallySizedBox(
                              widthFactor: (currentXP / maxXP).clamp(0.0, 1.0),
                              alignment: Alignment.centerLeft,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(3),
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
            ),
          ],
        ),
      ),
    );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 60);
}

/// Compact app bar for secondary screens
class CompactAppBar extends StatelessWidget implements PreferredSizeWidget {

  const CompactAppBar({
    required this.title, super.key,
    this.actions,
    this.leading,
    this.centerTitle = true,
  });
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) => AppBar(
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      centerTitle: centerTitle,
      leading: leading,
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
    );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);
}
