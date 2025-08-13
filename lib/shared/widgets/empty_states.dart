import 'package:flutter/material.dart';

/// Collection of empty state widgets with encouraging messaging
class EmptyStates {
  /// Generic empty state widget
  static Widget create({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String message,
    String? actionText,
    VoidCallback? onAction,
    Color? iconColor,
    Widget? customAction,
  }) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 80,
              color: iconColor ?? theme.colorScheme.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (customAction != null) ...[
              const SizedBox(height: 24),
              customAction,
            ] else if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionText),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state for when no tasks exist
class EmptyTasksState extends StatelessWidget {

  const EmptyTasksState({
    super.key,
    this.onCreateTask,
    this.customMessage,
  });
  final VoidCallback? onCreateTask;
  final String? customMessage;

  @override
  Widget build(BuildContext context) => EmptyStates.create(
      context: context,
      icon: Icons.task_alt,
      title: 'Ready to Level Up?',
      message: customMessage ?? 
          'Your adventure begins with your first task! Create goals that matter to you and watch your character grow stronger with every achievement.',
      actionText: 'Create Your First Task',
      onAction: onCreateTask,
      iconColor: Colors.blue,
    );
}

/// Empty state for completed tasks
class EmptyCompletedTasksState extends StatelessWidget {

  const EmptyCompletedTasksState({
    super.key,
    this.onViewAllTasks,
  });
  final VoidCallback? onViewAllTasks;

  @override
  Widget build(BuildContext context) => EmptyStates.create(
      context: context,
      icon: Icons.check_circle_outline,
      title: 'No Victories Yet',
      message: 'Complete some tasks to see your achievements here. Every completed task brings you closer to your goals!',
      actionText: 'View All Tasks',
      onAction: onViewAllTasks,
      iconColor: Colors.green,
    );
}

/// Empty state for achievements
class EmptyAchievementsState extends StatelessWidget {

  const EmptyAchievementsState({
    super.key,
    this.onViewTasks,
  });
  final VoidCallback? onViewTasks;

  @override
  Widget build(BuildContext context) => EmptyStates.create(
      context: context,
      icon: Icons.emoji_events,
      title: 'Achievements Await!',
      message: 'Complete tasks and reach milestones to unlock amazing achievements. Your trophy collection starts with your first completed task!',
      actionText: 'Start Completing Tasks',
      onAction: onViewTasks,
      iconColor: Colors.amber,
    );
}

/// Empty state for progress/analytics
class EmptyProgressState extends StatelessWidget {

  const EmptyProgressState({
    super.key,
    this.onCreateTask,
  });
  final VoidCallback? onCreateTask;

  @override
  Widget build(BuildContext context) => EmptyStates.create(
      context: context,
      icon: Icons.trending_up,
      title: 'Your Journey Starts Here',
      message: 'Track your progress and see your growth over time. Complete tasks to generate your first progress data!',
      actionText: 'Create a Task',
      onAction: onCreateTask,
      iconColor: Colors.purple,
    );
}

/// Empty state for world/map
class EmptyWorldState extends StatelessWidget {

  const EmptyWorldState({
    super.key,
    this.onEarnXP,
  });
  final VoidCallback? onEarnXP;

  @override
  Widget build(BuildContext context) => EmptyStates.create(
      context: context,
      icon: Icons.public,
      title: 'Unexplored Territory',
      message: 'Earn XP by completing tasks to unlock new areas of your world. Each milestone reveals new territories to explore!',
      actionText: 'Start Earning XP',
      onAction: onEarnXP,
      iconColor: Colors.teal,
    );
}

/// Empty state for search results
class EmptySearchState extends StatelessWidget {

  const EmptySearchState({
    required this.searchQuery, super.key,
    this.onClearSearch,
  });
  final String searchQuery;
  final VoidCallback? onClearSearch;

  @override
  Widget build(BuildContext context) => EmptyStates.create(
      context: context,
      icon: Icons.search_off,
      title: 'No Results Found',
      message: 'We couldn\'t find anything matching "$searchQuery". Try adjusting your search terms or browse all items.',
      actionText: 'Clear Search',
      onAction: onClearSearch,
      iconColor: Colors.grey,
    );
}

/// Empty state for filtered results
class EmptyFilterState extends StatelessWidget {

  const EmptyFilterState({
    required this.filterType, super.key,
    this.onClearFilter,
  });
  final String filterType;
  final VoidCallback? onClearFilter;

  @override
  Widget build(BuildContext context) => EmptyStates.create(
      context: context,
      icon: Icons.filter_list_off,
      title: 'No $filterType Items',
      message: 'There are no items matching your current filter. Try adjusting your filters or view all items.',
      actionText: 'Clear Filters',
      onAction: onClearFilter,
      iconColor: Colors.orange,
    );
}

/// Empty state for notifications
class EmptyNotificationsState extends StatelessWidget {
  const EmptyNotificationsState({super.key});

  @override
  Widget build(BuildContext context) => EmptyStates.create(
      context: context,
      icon: Icons.notifications_none,
      title: 'All Caught Up!',
      message: 'You have no new notifications. Keep completing tasks and achieving milestones to stay engaged!',
      iconColor: Colors.indigo,
    );
}

/// Empty state for streaks
class EmptyStreaksState extends StatelessWidget {

  const EmptyStreaksState({
    super.key,
    this.onCreateDailyTask,
  });
  final VoidCallback? onCreateDailyTask;

  @override
  Widget build(BuildContext context) => EmptyStates.create(
      context: context,
      icon: Icons.local_fire_department,
      title: 'Build Your First Streak!',
      message: 'Create daily tasks and complete them consistently to build powerful streaks. Streaks multiply your XP rewards!',
      actionText: 'Create Daily Task',
      onAction: onCreateDailyTask,
      iconColor: Colors.deepOrange,
    );
}

/// Empty state for categories
class EmptyCategoryState extends StatelessWidget {

  const EmptyCategoryState({
    required this.categoryName, super.key,
    this.onCreateTask,
  });
  final String categoryName;
  final VoidCallback? onCreateTask;

  @override
  Widget build(BuildContext context) => EmptyStates.create(
      context: context,
      icon: Icons.category,
      title: 'No $categoryName Tasks',
      message: 'Start your $categoryName journey by creating your first task in this category. Every expert was once a beginner!',
      actionText: 'Create $categoryName Task',
      onAction: onCreateTask,
      iconColor: _getCategoryColor(categoryName),
    );

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'health':
        return Colors.green;
      case 'fitness':
        return Colors.blue;
      case 'learning':
        return Colors.purple;
      case 'work':
        return Colors.indigo;
      case 'finance':
        return Colors.teal;
      case 'social':
        return Colors.pink;
      case 'creative':
        return Colors.orange;
      case 'mindfulness':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }
}

/// Empty state for offline mode
class OfflineEmptyState extends StatelessWidget {

  const OfflineEmptyState({
    super.key,
    this.onRetry,
  });
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => EmptyStates.create(
      context: context,
      icon: Icons.cloud_off,
      title: "You're Offline",
      message: "No worries! You can still create and complete tasks. Your progress will sync when you're back online.",
      actionText: 'Try Again',
      onAction: onRetry,
      iconColor: Colors.grey,
    );
}

/// Empty state with custom illustration
class IllustratedEmptyState extends StatelessWidget {

  const IllustratedEmptyState({
    required this.imagePath, required this.title, required this.message, super.key,
    this.actionText,
    this.onAction,
  });
  final String imagePath;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              imagePath,
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Animated empty state with floating elements
class AnimatedEmptyState extends StatefulWidget {

  const AnimatedEmptyState({
    required this.icon, required this.title, required this.message, super.key,
    this.actionText,
    this.onAction,
    this.iconColor,
  });
  final IconData icon;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;
  final Color? iconColor;

  @override
  State<AnimatedEmptyState> createState() => _AnimatedEmptyStateState();
}

class _AnimatedEmptyStateState extends State<AnimatedEmptyState>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _fadeController;
  late Animation<double> _floatAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _floatAnimation = Tween<double>(
      begin: -10,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _floatController.repeat(reverse: true);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _floatAnimation,
                builder: (context, child) => Transform.translate(
                    offset: Offset(0, _floatAnimation.value),
                    child: Icon(
                      widget.icon,
                      size: 80,
                      color: widget.iconColor ?? theme.colorScheme.primary.withValues(alpha: 0.6),
                    ),
                  ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                widget.message,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.actionText != null && widget.onAction != null) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: widget.onAction,
                  icon: const Icon(Icons.add),
                  label: Text(widget.actionText!),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}