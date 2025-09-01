import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/blocs/avatar/avatar_bloc.dart';
import '../../../shared/blocs/avatar/avatar_event.dart';
import '../../../shared/blocs/avatar/avatar_state.dart';
import '../../../shared/widgets/interactive_avatar.dart';
import '../../../data/models/avatar.dart';

/// Panel for customizing avatar appearance
class AvatarCustomizationPanel extends StatefulWidget {
  const AvatarCustomizationPanel({super.key});

  @override
  State<AvatarCustomizationPanel> createState() => _AvatarCustomizationPanelState();
}

class _AvatarCustomizationPanelState extends State<AvatarCustomizationPanel> {
  int _selectedCategory = 0;
  Map<String, String> _tempCustomizations = {};
  
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
            // Real-time preview
            Container(
              padding: const EdgeInsets.all(16),
              child: AvatarPreview(
                avatar: state.avatar,
                customizations: _tempCustomizations,
                size: 150,
                showPreviewAnimation: false,
              ),
            ),
            
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
            
            // Apply button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton(
                onPressed: () => _applyCustomizations(context, state.avatar),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Apply Changes'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCustomizationOptions(BuildContext context, Avatar avatar) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Get customization options for the selected category
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
        final isSelected = _isOptionSelected(option, avatar);
        final isUnlocked = _isOptionUnlocked(option, avatar);

        return GestureDetector(
          onTap: isUnlocked
              ? () => _selectOption(context, option, avatar)
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

  bool _isOptionSelected(Map<String, dynamic> option, Avatar avatar) {
    final categoryKey = _getCategoryKey(_selectedCategory);
    
    // Check if this option is currently selected in temporary customizations
    if (_tempCustomizations.containsKey(categoryKey)) {
      return _tempCustomizations[categoryKey] == option['id'];
    }
    
    // Otherwise check the avatar's current appearance
    switch (_selectedCategory) {
      case 0: // Hair
        return avatar.appearance.hairStyle == option['id'];
      case 1: // Eyes
        return avatar.appearance.eyeColor == option['id'];
      case 2: // Clothing
        return avatar.appearance.clothing == option['id'];
      case 3: // Accessories
        return avatar.appearance.accessories == option['id'];
      default:
        return false;
    }
  }

  bool _isOptionUnlocked(Map<String, dynamic> option, Avatar avatar) {
    final requiredLevel = option['unlockLevel'] as int;
    return avatar.level >= requiredLevel;
  }

  void _selectOption(BuildContext context, Map<String, dynamic> option, Avatar avatar) {
    final categoryKey = _getCategoryKey(_selectedCategory);
    
    // Update temporary customizations for preview
    setState(() {
      _tempCustomizations = Map<String, String>.from(_tempCustomizations);
      _tempCustomizations[categoryKey] = option['id'] as String;
    });

    // Show selection feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${option['name']} selected for preview'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _applyCustomizations(BuildContext context, Avatar avatar) {
    // Create updated appearance based on temporary customizations
    final updatedAppearance = avatar.appearance.copyWith(
      hairStyle: _tempCustomizations['hair'] ?? avatar.appearance.hairStyle,
      hairColor: _tempCustomizations['hairColor'] ?? avatar.appearance.hairColor,
      eyeColor: _tempCustomizations['eyes'] ?? avatar.appearance.eyeColor,
      clothing: _tempCustomizations['clothing'] ?? avatar.appearance.clothing,
      accessories: _tempCustomizations['accessory'] ?? avatar.appearance.accessories,
    );

    // Dispatch update appearance event
    context.read<AvatarBloc>().add(
      UpdateAppearance(
        avatarId: avatar.id,
        appearance: updatedAppearance,
      ),
    );

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Avatar customization applied!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showUnlockDialog(BuildContext context, Map<String, dynamic> option) {
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

  String _getCategoryKey(int categoryIndex) {
    switch (categoryIndex) {
      case 0: return 'hair';
      case 1: return 'eyes';
      case 2: return 'clothing';
      case 3: return 'accessory';
      default: return '';
    }
  }
}