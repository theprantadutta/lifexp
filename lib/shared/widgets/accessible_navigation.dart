import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/accessibility_service.dart';

/// Accessible bottom navigation bar with comprehensive screen reader support
class AccessibleBottomNavigation extends StatelessWidget {

  const AccessibleBottomNavigation({
    required this.currentIndex, required this.onTap, required this.items, super.key,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
  });
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AccessibleNavItem> items;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accessibilityService = AccessibilityService();
    
    return Semantics(
      label: 'Navigation bar with ${items.length} tabs',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor ?? theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == currentIndex;
              
              return Expanded(
                child: Semantics(
                  label: accessibilityService.createNavigationLabel(
                    item.label,
                    isSelected: isSelected,
                  ),
                  hint: accessibilityService.createInteractionHint('navigate to ${item.label}'),
                  button: true,
                  selected: isSelected,
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onTap(index);
                        accessibilityService.announce('Navigated to ${item.label}');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSelected ? item.selectedIcon : item.icon,
                              color: isSelected
                                  ? selectedItemColor ?? theme.colorScheme.primary
                                  : unselectedItemColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.label,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isSelected
                                    ? selectedItemColor ?? theme.colorScheme.primary
                                    : unselectedItemColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// Navigation item data class
class AccessibleNavItem {

  const AccessibleNavItem({
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.semanticLabel,
  });
  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final String? semanticLabel;
}

/// Accessible app bar with proper heading structure
class AccessibleAppBar extends StatelessWidget implements PreferredSizeWidget {

  const AccessibleAppBar({
    required this.title, super.key,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
    this.semanticLabel,
  });
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Semantics(
        header: true,
        label: semanticLabel ?? title,
        child: Text(title),
      ),
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      actions: actions?.map((action) => Semantics(
          button: true,
          child: action,
        )).toList(),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Accessible drawer with proper navigation structure
class AccessibleDrawer extends StatelessWidget {

  const AccessibleDrawer({
    required this.items, super.key,
    this.header,
    this.headerWidget,
    this.onItemTap,
  });
  final String? header;
  final Widget? headerWidget;
  final List<AccessibleDrawerItem> items;
  final Function(int)? onItemTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accessibilityService = AccessibilityService();
    
    return Drawer(
      child: Semantics(
        label: 'Navigation drawer',
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            if (headerWidget != null)
              headerWidget!
            else if (header != null)
              DrawerHeader(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                ),
                child: Semantics(
                  header: true,
                  child: Text(
                    header!,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              
              return Semantics(
                label: item.semanticLabel ?? item.title,
                hint: accessibilityService.createInteractionHint(item.title.toLowerCase()),
                button: true,
                child: ListTile(
                  leading: item.icon != null
                      ? Icon(item.icon)
                      : null,
                  title: Text(item.title),
                  subtitle: item.subtitle != null
                      ? Text(item.subtitle!)
                      : null,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).pop();
                    onItemTap?.call(index);
                    accessibilityService.announce('Selected ${item.title}');
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Drawer item data class
class AccessibleDrawerItem {

  const AccessibleDrawerItem({
    required this.title,
    this.subtitle,
    this.icon,
    this.semanticLabel,
    this.onTap,
  });
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? semanticLabel;
  final VoidCallback? onTap;
}

/// Accessible tab bar with proper focus management
class AccessibleTabBar extends StatelessWidget {

  const AccessibleTabBar({
    required this.tabs, required this.currentIndex, required this.onTap, super.key,
    this.isScrollable = false,
    this.indicatorColor,
    this.labelColor,
    this.unselectedLabelColor,
  });
  final List<String> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isScrollable;
  final Color? indicatorColor;
  final Color? labelColor;
  final Color? unselectedLabelColor;

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService();
    
    return Semantics(
      label: 'Tab bar with ${tabs.length} tabs',
      child: TabBar(
        isScrollable: isScrollable,
        indicatorColor: indicatorColor,
        labelColor: labelColor,
        unselectedLabelColor: unselectedLabelColor,
        tabs: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = index == currentIndex;
          
          return Semantics(
            label: accessibilityService.createNavigationLabel(
              tab,
              isSelected: isSelected,
            ),
            hint: accessibilityService.createInteractionHint('switch to $tab tab'),
            button: true,
            selected: isSelected,
            child: Tab(
              text: tab,
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Accessible floating action button with enhanced feedback
class AccessibleFloatingActionButton extends StatelessWidget {

  const AccessibleFloatingActionButton({
    required this.onPressed, required this.child, required this.tooltip, super.key,
    this.semanticLabel,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.mini = false,
  });
  final VoidCallback? onPressed;
  final Widget child;
  final String tooltip;
  final String? semanticLabel;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool mini;

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService();
    
    return Semantics(
      label: semanticLabel ?? tooltip,
      hint: accessibilityService.createInteractionHint(tooltip.toLowerCase()),
      button: true,
      child: FloatingActionButton(
        onPressed: onPressed != null
            ? () {
                HapticFeedback.lightImpact();
                onPressed!();
                accessibilityService.announce('$tooltip activated');
              }
            : null,
        tooltip: tooltip,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: elevation,
        mini: mini,
        child: child,
      ),
    );
  }
}

/// Accessible breadcrumb navigation
class AccessibleBreadcrumb extends StatelessWidget {

  const AccessibleBreadcrumb({
    required this.items, super.key,
    this.onItemTap,
    this.separator = ' > ',
  });
  final List<BreadcrumbItem> items;
  final Function(int)? onItemTap;
  final String separator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accessibilityService = AccessibilityService();
    
    return Semantics(
      label: 'Breadcrumb navigation with ${items.length} items',
      child: Wrap(
        children: items.asMap().entries.expand((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == items.length - 1;
          
          return [
            Semantics(
              label: isLast ? 'Current page: ${item.label}' : item.label,
              hint: !isLast && onItemTap != null
                  ? accessibilityService.createInteractionHint('navigate to ${item.label}')
                  : null,
              button: !isLast && onItemTap != null,
              child: InkWell(
                onTap: !isLast && onItemTap != null
                    ? () {
                        HapticFeedback.selectionClick();
                        onItemTap!(index);
                        accessibilityService.announce('Navigated to ${item.label}');
                      }
                    : null,
                child: Text(
                  item.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isLast
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.primary,
                    fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                    decoration: !isLast && onItemTap != null
                        ? TextDecoration.underline
                        : null,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Semantics(
                excludeSemantics: true,
                child: Text(
                  separator,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
          ];
        }).toList(),
      ),
    );
  }
}

/// Breadcrumb item data class
class BreadcrumbItem {

  const BreadcrumbItem({
    required this.label,
    this.semanticLabel,
  });
  final String label;
  final String? semanticLabel;
}