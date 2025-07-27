import 'package:flutter/material.dart';
import '../../themes/theme_extensions.dart';
import 'gamification_icons.dart';

/// Main navigation widget with bottom navigation bar and drawer
class MainNavigation extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTabChanged;
  final List<Widget> screens;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const MainNavigation({
    super.key,
    this.scaffoldKey,
    required this.currentIndex,
    required this.onTabChanged,
    required this.screens,
  });

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
    return Scaffold(
      key: widget.scaffoldKey,
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
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 10,
          offset: const Offset(0, -2),
        ),
      ],
    ),
    child: BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
      child: SizedBox(
        height: 60,
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
            const SizedBox(width: 40), // Space for FAB
            _buildNavItem(
              context,
              icon: GamificationIcons.progressOutlined,
              activeIcon: GamificationIcons.progress,
              label: 'Progress',
              index: 2,
            ),
            _buildNavItem(
              context,
              icon: GamificationIcons.worldOutlined,
              activeIcon: GamificationIcons.world,
              label: 'World',
              index: 3,
            ),
            _buildNavItem(
              context,
              icon: GamificationIcons.profileOutlined,
              activeIcon: GamificationIcons.profile,
              label: 'Profile',
              index: 4,
            ),
          ],
        ),
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

    return GestureDetector(
      onTap: () => widget.onTabChanged(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: isActive
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withValues(alpha: 0.1),
                    secondaryColor.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ) ??
                  TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return AnimatedBuilder(
      animation: _fabScaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _fabScaleAnimation.value,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: context.xpGradient,
            boxShadow: [
              BoxShadow(
                color: context.xpPrimary.withValues(alpha: 0.3),
                blurRadius: 12,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: _onFabPressed,
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            child: GamificationIcon(
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
}

/// Navigation drawer with settings and additional options
class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
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
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return Container(
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
                child: GamificationIcon(
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
  }

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
        border: Border.all(
          color: context.xpPrimary.withValues(alpha: 0.2),
          width: 1,
        ),
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

  Widget _buildDrawerFooter(BuildContext context) {
    return Container(
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
}
