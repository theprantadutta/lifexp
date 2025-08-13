import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../themes/theme_extensions.dart';
import 'gamification_icons.dart';

/// Main navigation widget with bottom navigation bar and drawer
class MainNavigation extends StatefulWidget {
  const MainNavigation({
    required this.currentIndex,
    required this.onTabChanged,
    required this.screens,
    super.key,
    this.scaffoldKey,
  });
  final int currentIndex;
  final Function(int) onTabChanged;
  final List<Widget> screens;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with TickerProviderStateMixin {
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fabScaleAnimation = Tween<double>(begin: 1, end: 0.9).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _onFabPressed() async {
    await _fabAnimationController.forward();
    await _fabAnimationController.reverse();
    // Navigate to task creation screen (placeholder)
  }

  @override
  Widget build(BuildContext context) {
    // Set status bar style based on theme
    final isDark = Theme.of(context).brightness == Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Theme.of(context).colorScheme.surface,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
    );

    return Scaffold(
      key: widget.scaffoldKey,
      extendBody: true,
      body: IndexedStack(index: widget.currentIndex, children: widget.screens),
      bottomNavigationBar: _buildBottomNavigationBar(context),
      floatingActionButton: _buildFloatingActionButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      drawer: const MainDrawer(),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, -4),
        ),
      ],
    ),
    child: BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 10,
      elevation: 0,
      height: 70, // Increased height for better spacing
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context,
            icon: GamificationIcons.homeOutlined,
            activeIcon: GamificationIcons.home,
            label: 'Home',
            index: 0,
          ),
          _buildNavItem(
            context,
            icon: GamificationIcons.tasksOutlined,
            activeIcon: GamificationIcons.tasks,
            label: 'Tasks',
            index: 1,
          ),
          const SizedBox(width: 48), // More space for FAB
          _buildNavItem(
            context,
            icon: GamificationIcons.progressOutlined,
            activeIcon: GamificationIcons.progress,
            label: 'Progress',
            index: 2,
          ),
          _buildNavItem(
            context,
            icon: GamificationIcons.profileOutlined,
            activeIcon: GamificationIcons.profile,
            label: 'Profile',
            index: 3,
          ),
        ],
      ),
    ),
  );

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isActive = widget.currentIndex == index;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    // Use gradient colors for active state
    final color = isActive
        ? primaryColor
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onTabChanged(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: isActive
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withValues(alpha: 0.12),
                      secondaryColor.withValues(alpha: 0.12),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GamificationIcon(
                icon: isActive ? activeIcon : icon,
                color: color,
                isActive: isActive,
                showGlow: isActive,
                size: 24,
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style:
                    Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 10,
                    ) ??
                    TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) => AnimatedBuilder(
    animation: _fabScaleAnimation,
    builder: (context, child) => Transform.scale(
      scale: _fabScaleAnimation.value,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: context.xpGradient,
          boxShadow: [
            BoxShadow(
              color: context.xpPrimary.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _onFabPressed,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          child: const GamificationIcon(
            icon: GamificationIcons.quickAdd,
            color: Colors.white,
            size: 28,
            showGlow: true,
          ),
        ),
      ),
    ),
  );
}

/// Navigation drawer with settings and additional options
class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) => Drawer(
    child: Column(
      children: [
        _buildDrawerHeader(context),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildDrawerItem(
                context,
                icon: GamificationIcons.achievement,
                title: 'Achievements',
                subtitle: 'View your badges and milestones',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to achievements screen (placeholder)
                },
              ),
              _buildDrawerItem(
                context,
                icon: GamificationIcons.themes,
                title: 'Themes',
                subtitle: 'Customize your app appearance',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to theme selection screen (placeholder)
                },
              ),
              _buildDrawerItem(
                context,
                icon: GamificationIcons.settings,
                title: 'Settings',
                subtitle: 'App preferences and configuration',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to settings screen (placeholder)
                },
              ),
              _buildDrawerItem(
                context,
                icon: GamificationIcons.notifications,
                title: 'Notifications',
                subtitle: 'Manage your reminders',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to notification settings (placeholder)
                },
              ),
              const Divider(),
              _buildDrawerItem(
                context,
                icon: GamificationIcons.help,
                title: 'Help & Support',
                subtitle: 'Get help and send feedback',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to help screen (placeholder)
                },
              ),
              _buildDrawerItem(
                context,
                icon: GamificationIcons.about,
                title: 'About',
                subtitle: 'App version and information',
                onTap: () {
                  Navigator.pop(context);
                  // Show about dialog (placeholder)
                },
              ),
            ],
          ),
        ),
        _buildDrawerFooter(context),
      ],
    ),
  );

  Widget _buildDrawerHeader(BuildContext context) => Container(
    height: 200,
    decoration: BoxDecoration(gradient: context.xpGradient),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Avatar placeholder
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const GamificationIcon(
                icon: GamificationIcons.profile,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            // User info placeholder
            Text(
              'Welcome back!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                GamificationIcon(
                  icon: GamificationIcons.xp,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Level 1 • 0 XP',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) => ListTile(
    leading: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.xpPrimary.withValues(alpha: 0.1),
            context.xpSecondary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.xpPrimary.withValues(alpha: 0.2)),
      ),
      child: GamificationIcon(icon: icon, color: context.xpPrimary, size: 20),
    ),
    title: Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    ),
    subtitle: Text(
      subtitle,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
      ),
    ),
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
  );

  Widget _buildDrawerFooter(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      border: Border(
        top: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
    ),
    child: Row(
      children: [
        Icon(
          Icons.favorite,
          color: Colors.red.withValues(alpha: 0.7),
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          'Made with love for productivity',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    ),
  );
}
