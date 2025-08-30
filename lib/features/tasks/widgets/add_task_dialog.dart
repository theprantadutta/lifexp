import 'package:flutter/material.dart';
import '../../../data/models/task.dart';

/// Dialog for adding or editing tasks
class AddTaskDialog extends StatefulWidget {

  const AddTaskDialog({
    required this.initialType, required this.onTaskAdded, super.key,
    this.task,
  });
  final TaskType initialType;
  final Task? task;
  final Function(
    String title,
    String description,
    TaskType type,
    TaskCategory category,
    int difficulty,
    DateTime? dueDate,
  )
  onTaskAdded;

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  late TaskType _selectedType;
  late TaskCategory _selectedCategory;
  late int _selectedDifficulty;
  DateTime? _selectedDueDate;

  @override
  void initState() {
    super.initState();

    if (widget.task != null) {
      // Editing existing task
      final task = widget.task!;
      _titleController.text = task.title;
      _descriptionController.text = task.description;
      _selectedType = task.type;
      _selectedCategory = task.category;
      _selectedDifficulty = task.difficulty;
      _selectedDueDate = task.dueDate;
    } else {
      // Creating new task
      _selectedType = widget.initialType;
      _selectedCategory = TaskCategory.custom;
      _selectedDifficulty = 3;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Task' : 'Add New Task'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter task title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  if (value.length > 100) {
                    return 'Title must be 100 characters or less';
                  }
                  return null;
                },
                maxLength: 100,
              ),
              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Enter task description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                maxLength: 500,
                validator: (value) {
                  if (value != null && value.length > 500) {
                    return 'Description must be 500 characters or less';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Task type dropdown
              DropdownButtonFormField<TaskType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Task Type',
                  border: OutlineInputBorder(),
                ),
                items: TaskType.values.map((type) => DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Icon(_getTypeIcon(type)),
                        const SizedBox(width: 8),
                        Text(type.displayName),
                      ],
                    ),
                  )).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Category dropdown
              DropdownButtonFormField<TaskCategory>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: TaskCategory.values.map((category) => DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Text(
                          category.icon,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(category.displayName),
                      ],
                    ),
                  )).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Difficulty slider
              Text(
                'Difficulty: $_selectedDifficulty',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Slider(
                value: _selectedDifficulty.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                label: _selectedDifficulty.toString(),
                onChanged: (value) {
                  setState(() {
                    _selectedDifficulty = value.round();
                  });
                },
              ),
              Row(
                children: List.generate(_selectedDifficulty, (index) => Icon(
                    Icons.star,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  )),
              ),
              const SizedBox(height: 16),

              // Due date picker
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  _selectedDueDate == null
                      ? 'No due date'
                      : 'Due: ${_formatDate(_selectedDueDate!)}',
                ),
                trailing: _selectedDueDate != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _selectedDueDate = null;
                          });
                        },
                      )
                    : null,
                onTap: _selectDueDate,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveTask,
          child: Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }

  IconData _getTypeIcon(TaskType type) {
    switch (type) {
      case TaskType.daily:
        return Icons.today;
      case TaskType.weekly:
        return Icons.view_week;
      case TaskType.longTerm:
        return Icons.flag;
    }
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _selectedDueDate = date;
      });
    }
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      widget.onTaskAdded(
        _titleController.text.trim(),
        _descriptionController.text.trim(),
        _selectedType,
        _selectedCategory,
        _selectedDifficulty,
        _selectedDueDate,
      );
      Navigator.of(context).pop();
    }
  }
}
