import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/blocs/goal/goal_bloc.dart';
import '../../../shared/blocs/goal/goal_event.dart';
import '../../../shared/blocs/goal/goal_state.dart';
import '../widgets/goal_list_widget.dart';
import '../widgets/goal_form_widget.dart';

/// Main screen for goal management
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key, required this.userId});

  final String userId;

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  late GoalBloc _goalBloc;
  bool _showForm = false;
  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    _goalBloc = context.read<GoalBloc>();
    _loadGoals();
  }

  void _loadGoals() {
    switch (_filterType) {
      case 'all':
        _goalBloc.add(LoadGoals(widget.userId));
        break;
      case 'category':
        // This would require a specific category
        _goalBloc.add(LoadGoals(widget.userId));
        break;
      case 'priority':
        // This would require a specific priority
        _goalBloc.add(LoadGoals(widget.userId));
        break;
      case 'status':
        // This would require a specific status
        _goalBloc.add(LoadGoals(widget.userId));
        break;
      case 'active':
        _goalBloc.add(LoadActiveGoals(widget.userId));
        break;
      case 'completed':
        _goalBloc.add(LoadCompletedGoals(widget.userId));
        break;
      case 'overdue':
        _goalBloc.add(LoadOverdueGoals(widget.userId));
        break;
      case 'dueSoon':
        _goalBloc.add(LoadGoalsDueSoon(widget.userId));
        break;
      default:
        _goalBloc.add(LoadGoals(widget.userId));
    }
  }

  void _toggleForm() {
    setState(() {
      _showForm = !_showForm;
    });
  }

  void _onFilterChanged(String filterType) {
    setState(() {
      _filterType = filterType;
    });
    _loadGoals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Show filter options
              _showFilterOptions();
            },
          ),
        ],
      ),
      body: BlocConsumer<GoalBloc, GoalState>(
        listener: (context, state) {
          if (state is GoalOperationSuccess) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is GoalError) {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is GoalLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is GoalLoaded || state is GoalLoadedWithFilter) {
            final goals = state is GoalLoaded ? state.goals : (state as GoalLoadedWithFilter).goals;
            return Column(
              children: [
                if (_showForm)
                  GoalFormWidget(
                    userId: widget.userId,
                    onGoalSaved: () {
                      _toggleForm();
                      _loadGoals(); // Refresh the list
                    },
                    onCancel: _toggleForm,
                  ),
                Expanded(
                  child: GoalListWidget(
                    goals: goals,
                    onGoalUpdated: _loadGoals,
                  ),
                ),
              ],
            );
          } else if (state is SingleGoalLoaded) {
            // Display single goal details
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.goal.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(state.goal.description),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: state.goal.progress,
                      minHeight: 10,
                    ),
                    const SizedBox(height: 8),
                    Text('${(state.goal.progress * 100).round()}% complete'),
                    const SizedBox(height: 16),
                    // Fixed the displayName references
                    Text('Category: ${_getCategoryDisplayName(state.goal.category)}'),
                    Text('Priority: ${_getPriorityDisplayName(state.goal.priority)}'),
                    Text('Status: ${_getStatusDisplayName(state.goal.status)}'),
                    Text('Deadline: ${state.goal.deadline}'),
                  ],
                ),
              ),
            );
          } else if (state is GoalError) {
            return Center(
              child: Text('Error: ${state.message}'),
            );
          }
          return const Center(child: Text('No goals found'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleForm,
        child: Icon(_showForm ? Icons.close : Icons.add),
      ),
    );
  }

  // Helper methods to get display names
  String _getCategoryDisplayName(dynamic category) {
    // Using toString() and parsing to get the enum name
    final name = category.toString().split('.').last;
    switch (name) {
      case 'health':
        return 'Health';
      case 'fitness':
        return 'Fitness';
      case 'mindfulness':
        return 'Mindfulness';
      case 'learning':
        return 'Learning';
      case 'career':
        return 'Career';
      case 'financial':
        return 'Financial';
      case 'relationships':
        return 'Relationships';
      case 'personal':
        return 'Personal';
      case 'custom':
        return 'Custom';
      default:
        return name;
    }
  }

  String _getPriorityDisplayName(dynamic priority) {
    // Using toString() and parsing to get the enum name
    final name = priority.toString().split('.').last;
    switch (name) {
      case 'low':
        return 'Low';
      case 'medium':
        return 'Medium';
      case 'high':
        return 'High';
      case 'critical':
        return 'Critical';
      default:
        return name;
    }
  }

  String _getStatusDisplayName(dynamic status) {
    // Using toString() and parsing to get the enum name
    final name = status.toString().split('.').last;
    switch (name) {
      case 'notStarted':
        return 'Not Started';
      case 'inProgress':
        return 'In Progress';
      case 'onHold':
        return 'On Hold';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return name;
    }
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('All Goals'),
                onTap: () {
                  _onFilterChanged('all');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Active Goals'),
                onTap: () {
                  _onFilterChanged('active');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Completed Goals'),
                onTap: () {
                  _onFilterChanged('completed');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Overdue Goals'),
                onTap: () {
                  _onFilterChanged('overdue');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Due Soon'),
                onTap: () {
                  _onFilterChanged('dueSoon');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}