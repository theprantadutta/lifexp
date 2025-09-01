import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/avatar.dart';
import '../../../data/models/progress.dart';
import '../../../data/models/progress_period.dart';
import '../../../data/models/task.dart';
import '../../../shared/blocs/avatar/avatar_bloc_exports.dart';
import '../../../shared/blocs/progress/progress_bloc_exports.dart';
import '../../../shared/providers/user_context.dart';
import '../../../shared/widgets/attribute_bar.dart';
import '../widgets/category_breakdown_chart.dart';
import '../widgets/comparative_analytics_chart.dart';
import '../widgets/productivity_patterns_chart.dart';
import '../widgets/progress_stats_card.dart';
import '../widgets/trend_analysis_chart.dart';
import '../widgets/xp_chart.dart';

/// Progress screen for viewing analytics and progress charts
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ProgressPeriod _selectedPeriod = ProgressPeriod.week;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.currentUserOrNull;
    if (user != null) {
      context.read<ProgressBloc>().add(LoadProgressEntries(userId: user.id));
      context.read<AvatarBloc>().add(LoadAvatar(userId: user.id));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Progress'),
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      actions: [
        PopupMenuButton<ProgressPeriod>(
          icon: const Icon(Icons.date_range),
          onSelected: (period) {
            setState(() {
              _selectedPeriod = period;
            });
            final user = context.currentUserOrNull;
            if (user != null) {
              final now = DateTime.now();
              late DateTime startDate;
              late DateTime endDate;
              
              switch (period) {
                case ProgressPeriod.day:
                  startDate = DateTime(now.year, now.month, now.day);
                  endDate = startDate.add(const Duration(days: 1));
                  break;
                case ProgressPeriod.week:
                  startDate = now.subtract(Duration(days: now.weekday - 1));
                  endDate = startDate.add(const Duration(days: 7));
                  break;
                case ProgressPeriod.month:
                  startDate = DateTime(now.year, now.month, 1);
                  endDate = DateTime(now.year, now.month + 1, 1);
                  break;
                case ProgressPeriod.year:
                  startDate = DateTime(now.year, 1, 1);
                  endDate = DateTime(now.year + 1, 1, 1);
                  break;
              }
              
              context.read<ProgressBloc>().add(
                LoadProgressEntriesInRange(
                  userId: user.id,
                  startDate: startDate,
                  endDate: endDate,
                ),
              );
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: ProgressPeriod.day,
              child: Text('Today'),
            ),
            const PopupMenuItem(
              value: ProgressPeriod.week,
              child: Text('This Week'),
            ),
            const PopupMenuItem(
              value: ProgressPeriod.month,
              child: Text('This Month'),
            ),
          ],
        ),
      ],
    ),
    body: Column(
      children: [
        _buildPeriodSelector(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildChartsTab(),
              _buildStatsTab(),
            ],
          ),
        ),
      ],
    ),
    bottomNavigationBar: TabBar(
      controller: _tabController,
      tabs: const [
        Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
        Tab(icon: Icon(Icons.show_chart), text: 'Charts'),
        Tab(icon: Icon(Icons.analytics), text: 'Stats'),
      ],
    ),
  );

  Widget _buildPeriodSelector() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      children: [
        Text(
          'Period: ',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ProgressPeriod.values.map((period) {
                final isSelected = _selectedPeriod == period;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_getPeriodDisplayName(period)),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedPeriod = period;
                        });
                        final user = context.currentUserOrNull;
                        if (user != null) {
                          final now = DateTime.now();
                          late DateTime startDate;
                          late DateTime endDate;
                          
                          switch (period) {
                            case ProgressPeriod.day:
                              startDate = DateTime(now.year, now.month, now.day);
                              endDate = startDate.add(const Duration(days: 1));
                              break;
                            case ProgressPeriod.week:
                              startDate = now.subtract(Duration(days: now.weekday - 1));
                              endDate = startDate.add(const Duration(days: 7));
                              break;
                            case ProgressPeriod.month:
                              startDate = DateTime(now.year, now.month, 1);
                              endDate = DateTime(now.year, now.month + 1, 1);
                              break;
                            case ProgressPeriod.year:
                              startDate = DateTime(now.year, 1, 1);
                              endDate = DateTime(now.year + 1, 1, 1);
                              break;
                          }
                          
                          context.read<ProgressBloc>().add(
                            LoadProgressEntriesInRange(
                              userId: user.id,
                              startDate: startDate,
                              endDate: endDate,
                            ),
                          );
                        }
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildOverviewTab() => BlocBuilder<AvatarBloc, AvatarState>(
    builder: (context, avatarState) => BlocBuilder<ProgressBloc, ProgressState>(
      builder: (context, progressState) {
        if (progressState is ProgressLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (progressState is ProgressError) {
          return _buildErrorState(progressState.message);
        }

        if (progressState is ProgressLoaded && avatarState is AvatarLoaded) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatarOverview(avatarState.avatar),
                const SizedBox(height: 24),
                _buildQuickStats(progressState),
                const SizedBox(height: 24),
                _buildRecentAchievements(),
              ],
            ),
          );
        }

        return _buildEmptyState();
      },
    ),
  );

  Widget _buildChartsTab() => BlocBuilder<ProgressBloc, ProgressState>(
    builder: (context, state) {
      if (state is ProgressLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      if (state is ProgressError) {
        return _buildErrorState(state.message);
      }

      if (state is ProgressLoaded) {
        // Get previous period entries for comparison
        final previousPeriodEntries = _getPreviousPeriodEntries(state.progressEntries);
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'XP Progress',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              XPChart(
                progressEntries: state.progressEntries,
                period: _selectedPeriod,
              ),
              const SizedBox(height: 32),
              Text(
                'Category Breakdown',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              CategoryBreakdownChart(
                progressEntries: state.progressEntries,
              ),
              const SizedBox(height: 32),
              Text(
                'Trend Analysis',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              TrendAnalysisChart(
                progressEntries: state.progressEntries,
                period: _selectedPeriod,
              ),
              const SizedBox(height: 32),
              Text(
                'Productivity Patterns',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              ProductivityPatternsChart(
                progressEntries: state.progressEntries,
              ),
              const SizedBox(height: 32),
              Text(
                'Period Comparison',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              ComparativeAnalyticsChart(
                currentPeriodEntries: state.progressEntries,
                previousPeriodEntries: previousPeriodEntries,
                currentPeriod: _selectedPeriod,
              ),
            ],
          ),
        );
      }

      return _buildEmptyState();
    },
  );

  Widget _buildStatsTab() => BlocBuilder<ProgressBloc, ProgressState>(
    builder: (context, state) {
      if (state is ProgressLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      if (state is ProgressError) {
        return _buildErrorState(state.message);
      }

      if (state is ProgressLoaded) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detailed Statistics',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              ...TaskCategory.values.map((category) {
                final categoryEntries = state.progressEntries
                    .where((entry) => entry.category == category.name)
                    .toList();
                
                if (categoryEntries.isEmpty) return const SizedBox.shrink();
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ProgressStatsCard(
                    category: category,
                    progressEntries: categoryEntries,
                    period: _selectedPeriod,
                  ),
                );
              }),
            ],
          ),
        );
      }

      return _buildEmptyState();
    },
  );

  Widget _buildAvatarOverview(Avatar avatar) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  'L${avatar.level}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level ${avatar.level}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${avatar.currentXP} / ${avatar.xpToNextLevel} XP',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: avatar.currentXP / avatar.xpToNextLevel,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AttributeBar(
                  attributeName: 'Strength',
                  currentValue: avatar.strength,
                  maxValue: 100,
                  color: Colors.red,
                  icon: Icons.fitness_center,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AttributeBar(
                  attributeName: 'Wisdom',
                  currentValue: avatar.wisdom,
                  maxValue: 100,
                  color: Colors.blue,
                  icon: Icons.psychology,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AttributeBar(
                  attributeName: 'Intelligence',
                  currentValue: avatar.intelligence,
                  maxValue: 100,
                  color: Colors.green,
                  icon: Icons.school,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _buildQuickStats(ProgressLoaded state) => Row(
    children: [
      Expanded(
        child: _buildStatCard(
          'Total XP',
          state.progressEntries
              .fold<int>(0, (sum, entry) => sum + entry.xpGained)
              .toString(),
          Icons.star,
          Theme.of(context).colorScheme.primary,
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: _buildStatCard(
          'Tasks Done',
          state.progressEntries
              .fold<int>(0, (sum, entry) => sum + entry.tasksCompleted)
              .toString(),
          Icons.check_circle,
          Colors.green,
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: _buildStatCard(
          'Streak Days',
          state.progressEntries.length.toString(),
          Icons.local_fire_department,
          Colors.orange,
        ),
      ),
    ],
  );

  Widget _buildStatCard(String title, String value, IconData icon, Color color) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  Widget _buildRecentAchievements() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Achievements',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          // Placeholder for recent achievements
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.emoji_events,
                  size: 48,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'No recent achievements',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildErrorState(String message) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading progress',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final user = context.currentUserOrNull;
              if (user != null) {
                context.read<ProgressBloc>().add(LoadProgressEntries(userId: user.id));
              }
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    ),
  );

  Widget _buildEmptyState() => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics,
            size: 48,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No progress data yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Complete some tasks to see your progress!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  String _getPeriodDisplayName(ProgressPeriod period) {
    switch (period) {
      case ProgressPeriod.day:
        return 'Today';
      case ProgressPeriod.week:
        return 'Week';
      case ProgressPeriod.month:
        return 'Month';
      case ProgressPeriod.year:
        return 'Year';
    }
  }

  List<ProgressEntry> _getPreviousPeriodEntries(List<ProgressEntry> currentEntries) {
    if (currentEntries.isEmpty) return <ProgressEntry>[];
    
    // For simplicity, we'll return an empty list for now
    // In a real implementation, this would fetch data for the previous period
    return <ProgressEntry>[];
  }
}
