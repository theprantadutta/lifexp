import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/blocs/avatar/avatar_bloc.dart';
import '../../../shared/blocs/avatar/avatar_event.dart';
import '../../../shared/blocs/avatar/avatar_state.dart';

/// Panel for customizing avatar appearance
class AvatarCustomizationPanel extends StatefulWidget {
  const AvatarCustomizationPanel({super.key});

  @override
  State<AvatarCustomizationPanel> createState() => _AvatarCustomizationPanelState();
}

class _AvatarCustomizationPanelState extends State<AvatarCustomizationPanel> {
  int _selectedCategory = 0;
  
  final List<String> _categories = [
    'Hair',
    'Eyes',
    'Clothing',
    'Accessories',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<AvatarBloc, AvatarState>(
      builder: (context, state) {
        if (state is! AvatarLoaded) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Column(
          children: [
            // Category tabs
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: _categories.asMap().entries.map((entry) {
                  final index = entry.key;
                  final category = entry.value;
                  final isSelected = _selectedCategory == index;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedCategory = index),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            category,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Customization options
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              child: _buildCustomizationOptions(context, state.avatar),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCustomizationOptions(BuildContext context, avatar) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Mock customization options for demonstration
    final options = _getOptionsForCategory(_selectedCategory);

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        final isSelected = _isOptionSelected(option);
        final isUnlocked = _isOptionUnlocked(option, avatar);

        return GestureDetector(
          onTap: isUnlocked
              ? () => _selectOption(context, option)
              : () => _showUnlockDialog(context, option),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primary.withValues(alpha: 0.2)
                  : colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        option['icon'] as IconData,
                        color: isUnlocked
                            ? (isSelected ? colorScheme.primary : colorScheme.onSurface)
                            : colorScheme.outline,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        option['name'] as String,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isUnlocked
                              ? (isSelected ? colorScheme.primary : colorScheme.onSurface)
                              : colorScheme.outline,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (!isUnlocked)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Icon(
                      Icons.lock,
                      size: 16,
                      color: colorScheme.outline,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _getOptionsForCategory(int category) {
    switch (category) {
      case 0: // Hair
        return [
          {'id': 'hair_1', 'name': 'Short', 'icon': Icons.face, 'unlockLevel': 1},
          {'id': 'hair_2', 'name': 'Long', 'icon': Icons.face_2, 'unlockLevel': 5},
          {'id': 'hair_3', 'name': 'Curly', 'icon': Icons.face_3, 'unlockLevel': 10},
          {'id': 'hair_4', 'name': 'Spiky', 'icon': Icons.face_4, 'unlockLevel': 15},
        ];
      case 1: // Eyes
        return [
          {'id': 'eyes_1', 'name': 'Brown', 'icon': Icons.visibility, 'unlockLevel': 1},
          {'id': 'eyes_2', 'name': 'Blue', 'icon': Icons.visibility, 'unlockLevel': 3},
          {'id': 'eyes_3', 'name': 'Green', 'icon': Icons.visibility, 'unlockLevel': 7},
          {'id': 'eyes_4', 'name': 'Hazel', 'icon': Icons.visibility, 'unlockLevel': 12},
        ];
      case 2: // Clothing
        return [
          {'id': 'shirt_1', 'name': 'T-Shirt', 'icon': Icons.checkroom, 'unlockLevel': 1},
          {'id': 'shirt_2', 'name': 'Hoodie', 'icon': Icons.checkroom, 'unlockLevel': 8},
          {'id': 'shirt_3', 'name': 'Suit', 'icon': Icons.business_center, 'unlockLevel': 20},
          {'id': 'shirt_4', 'name': 'Armor', 'icon': Icons.shield, 'unlockLevel': 25},
        ];
      case 3: // Accessories
        return [
          {'id': 'acc_1', 'name': 'None', 'icon': Icons.face, 'unlockLevel': 1},
          {'id': 'acc_2', 'name': 'Glasses', 'icon': Icons.visibility, 'unlockLevel': 6},
          {'id': 'acc_3', 'name': 'Hat', 'icon': Icons.sports_baseball, 'unlockLevel': 11},
          {'id': 'acc_4', 'name': 'Crown', 'icon': Icons.star, 'unlockLevel': 30},
        ];
      default:
        return [];
    }
  }

  bool _isOptionSelected(Map<String, dynamic> option) {
    // TODO: Check if option is currently selected on avatar
    return option['id'] == 'hair_1' || option['id'] == 'eyes_1' || 
           option['id'] == 'shirt_1' || option['id'] == 'acc_1';
  }

  bool _isOptionUnlocked(Map<String, dynamic> option, avatar) {
    final requiredLevel = option['unlockLevel'] as int;
    return avatar.level >= requiredLevel;
  }

  void _selectOption(BuildContext context, Map<String, dynamic> option) {
    // TODO: Implement avatar customization
    context.read<AvatarBloc>().add(
      AvatarCustomizationChanged(
        category: _categories[_selectedCategory].toLowerCase(),
        optionId: option['id'] as String,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${option['name']} selected!'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showUnlockDialog(BuildContext context, Map<String, dynamic> option) {
    final theme = Theme.of(context);
    final requiredLevel = option['unlockLevel'] as int;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Item Locked'),
        content: Text(
          'Reach level $requiredLevel to unlock "${option['name']}".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}