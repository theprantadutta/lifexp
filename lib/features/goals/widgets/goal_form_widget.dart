import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/goal.dart';
import '../../../shared/blocs/goal/goal_bloc.dart';
import '../../../shared/blocs/goal/goal_event.dart';

/// Widget for creating or editing a goal
class GoalFormWidget extends StatefulWidget {
  const GoalFormWidget({
    super.key,
    required this.userId,
    required this.onGoalSaved,
    required this.onCancel,
  });

  final String userId;
  final VoidCallback onGoalSaved;
  final VoidCallback onCancel;

  @override
  State<GoalFormWidget> createState() => _GoalFormWidgetState();
}

class _GoalFormWidgetState extends State<GoalFormWidget> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late GoalCategory _selectedCategory;
  late GoalPriority _selectedPriority;
  late DateTime _deadline;
  DateTime? _startDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _selectedCategory = GoalCategory.personal;
    _selectedPriority = GoalPriority.medium;
    _deadline = DateTime.now().add(const Duration(days: 30)); // Default 30 days
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create New Goal',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Goal Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a goal title';
                  }
                  if (value.length > 100) {
                    return 'Title must be less than 100 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value != null && value.length > 1000) {
                    return 'Description must be less than 1000 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              DropdownButtonFormField<GoalCategory>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: GoalCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16.0),
              DropdownButtonFormField<GoalPriority>(
                initialValue: _selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: GoalPriority.values.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Text(priority.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedPriority = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16.0),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Start Date'),
                      subtitle: Text(
                        _startDate != null
                            ? '${_startDate!.year}-${_startDate!.month}-${_startDate!.day}'
                            : 'Not set',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () => _selectStartDate(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: ListTile(
                      title: const Text('Deadline'),
                      subtitle: Text(
                        '${_deadline.year}-${_deadline.month}-${_deadline.day}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () => _selectDeadline(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: widget.onCancel,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16.0),
                  ElevatedButton(
                    onPressed: _saveGoal,
                    child: const Text('Save Goal'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows date picker for selecting start date
  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  /// Shows date picker for selecting deadline
  Future<void> _selectDeadline(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _deadline) {
      setState(() {
        _deadline = picked;
      });
    }
  }

  /// Saves the goal
  void _saveGoal() {
    if (_formKey.currentState!.validate()) {
      final goalBloc = context.read<GoalBloc>();
      
      goalBloc.add(
        CreateGoal(
          userId: widget.userId,
          title: _titleController.text,
          description: _descriptionController.text,
          category: _selectedCategory,
          priority: _selectedPriority,
          deadline: _deadline,
          startDate: _startDate,
        ),
      );
      
      // Clear form
      _titleController.clear();
      _descriptionController.clear();
      _selectedCategory = GoalCategory.personal;
      _selectedPriority = GoalPriority.medium;
      _startDate = null;
      _deadline = DateTime.now().add(const Duration(days: 30));
      
      widget.onGoalSaved();
    }
  }
}