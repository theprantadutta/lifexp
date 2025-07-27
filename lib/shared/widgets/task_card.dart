import 'package:flutter/material.dart';
import '../themes/theme_extensions.dart';

/// A card widget for displaying tasks with completion animations
class TaskCard extends StatefulWidget {
  final String title;
  final String? description;
  final String category;
  final int xpReward;
  final int difficulty;
  final int streakCount;
  final bool isCompleted;
  final DateTime? dueDate;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;

  const TaskCard({
    super.key,
    required this.title,
    this.description,
    required this.category,
    required this.xpReward,
    required this.difficulty,
    this.streakCount = 0,
    this.isCompleted = false,
    this.dueDate,
    this.onTap,
    this.onComplete,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.7).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleComplete() async {
    if (_isAnimating || widget.isCompleted) return;

    setState(() {
      _isAnimating = true;
    });

    await _animationController.forward();
    await Future.delayed(const Duration(milliseconds: 100));

    widget.onComplete?.call();

    await _animationController.reverse();

    if (mounted) {
      setState(() {
        _isAnimating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = context.getCategoryColor(widget.category);
    final isOverdue =
        widget.dueDate != null &&
        widget.dueDate!.isBefore(DateTime.now()) &&
        !widget.isCompleted;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: widget.isCompleted ? 1 : 3,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.isCompleted
                          ? Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.3)
                          : categoryColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with category indicator
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              categoryColor.withValues(alpha: 0.1),
                              categoryColor.withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Category indicator
                            Container(
                              width: 4,
                              height: 24,
                              decoration: BoxDecoration(
                                color: categoryColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Title and category
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          decoration: widget.isCompleted
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color: widget.isCompleted
                                              ? Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.6)
                                              : null,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: categoryColor.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          widget.category.toUpperCase(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: categoryColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                      if (widget.difficulty > 1) ...[
                                        const SizedBox(width: 8),
                                        Row(
                                          children: List.generate(
                                            widget.difficulty,
                                            (index) => Icon(
                                              Icons.star,
                                              size: 12,
                                              color: context.xpPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Completion checkbox
                            GestureDetector(
                              onTap: _handleComplete,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: widget.isCompleted
                                        ? categoryColor
                                        : Theme.of(context).colorScheme.outline,
                                    width: 2,
                                  ),
                                  color: widget.isCompleted
                                      ? categoryColor
                                      : Colors.transparent,
                                ),
                                child: widget.isCompleted
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 18,
                                      )
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Description
                            if (widget.description != null &&
                                widget.description!.isNotEmpty) ...[
                              Text(
                                widget.description!,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                            ],
                            // Stats row
                            Row(
                              children: [
                                // XP reward
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: context.xpGradient,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.bolt,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${widget.xpReward} XP',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Streak indicator
                                if (widget.streakCount > 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: context.streakFire.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.local_fire_department,
                                          color: context.streakFire,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${widget.streakCount}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: context.streakFire,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                // Due date
                                if (widget.dueDate != null) ...[
                                  Icon(
                                    Icons.schedule,
                                    size: 14,
                                    color: isOverdue
                                        ? Theme.of(context).colorScheme.error
                                        : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDueDate(widget.dueDate!),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: isOverdue
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.error
                                              : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.6),
                                          fontWeight: isOverdue
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Actions
                      if (widget.showActions && !widget.isCompleted) ...[
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (widget.onEdit != null)
                                TextButton.icon(
                                  onPressed: widget.onEdit,
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('Edit'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              if (widget.onDelete != null)
                                TextButton.icon(
                                  onPressed: widget.onDelete,
                                  icon: const Icon(Icons.delete, size: 16),
                                  label: const Text('Delete'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Theme.of(
                                      context,
                                    ).colorScheme.error,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays}d left';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h left';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m left';
    } else if (difference.inSeconds > 0) {
      return 'Due soon';
    } else {
      return 'Overdue';
    }
  }
}
