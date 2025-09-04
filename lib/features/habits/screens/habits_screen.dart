import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/habit.dart';
import '../../../shared/blocs/habit/habit_bloc.dart';
import '../../../shared/blocs/habit/habit_event.dart';
import '../../../shared/blocs/habit/habit_state.dart';
import '../widgets/habit_list_widget.dart';

/// Screen for displaying and managing user habits
class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  late HabitBloc _habitBloc;
  final _userId = 'user123'; // In a real app, this would come from auth context

  @override
  void initState() {
    super.initState();
    _habitBloc = context.read<HabitBloc>();
    _habitBloc.add(LoadHabits(userId: _userId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _habitBloc.add(RefreshHabits(userId: _userId)),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddHabitDialog,
          ),
        ],
      ),
      body: BlocBuilder<HabitBloc, HabitState>(
        builder: (context, state) {
          if (state is HabitLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HabitError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.message}'),
                  ElevatedButton(
                    onPressed: () => _habitBloc.add(LoadHabits(userId: _userId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is HabitLoaded) {
            return HabitListWidget(
              habits: state.displayHabits,
              onHabitComplete: (habitId) => _habitBloc.add(CompleteHabit(habitId: habitId)),
              onHabitReset: (habitId) => _habitBloc.add(ResetHabit(habitId: habitId)),
            );
          }

          return const Center(child: Text('No habits found'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddHabitDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Shows dialog to add a new habit
  void _showAddHabitDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    HabitCategory selectedCategory = HabitCategory.health;
    HabitFrequency selectedFrequency = HabitFrequency.daily;
    int selectedDifficulty = 3;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Habit'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Habit Title',
                    hintText: 'e.g., Drink 8 glasses of water',
                  ),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe your habit',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<HabitCategory>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: HabitCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedCategory = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<HabitFrequency>(
                  initialValue: selectedFrequency,
                  decoration: const InputDecoration(labelText: 'Frequency'),
                  items: HabitFrequency.values.map((frequency) {
                    return DropdownMenuItem(
                      value: frequency,
                      child: Text(frequency.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedFrequency = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: selectedDifficulty,
                  decoration: const InputDecoration(labelText: 'Difficulty'),
                  items: List.generate(10, (index) => index + 1).map((difficulty) {
                    return DropdownMenuItem(
                      value: difficulty,
                      child: Text('$difficulty ${difficulty <= 3 ? '★' : difficulty <= 6 ? '★★' : '★★★'}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedDifficulty = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  context.read<HabitBloc>().add(
                        CreateHabit(
                          userId: _userId,
                          title: titleController.text,
                          category: selectedCategory,
                          frequency: selectedFrequency,
                          description: descriptionController.text,
                          difficulty: selectedDifficulty,
                        ),
                      );
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}