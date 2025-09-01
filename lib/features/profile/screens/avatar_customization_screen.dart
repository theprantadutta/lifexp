import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/blocs/avatar/avatar_bloc.dart';
import '../../../shared/blocs/avatar/avatar_state.dart';
import '../../../shared/widgets/interactive_avatar.dart';
import '../widgets/avatar_customization_panel.dart';

/// Dedicated screen for avatar customization with enhanced features
class AvatarCustomizationScreen extends StatelessWidget {
  const AvatarCustomizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize Avatar'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showCustomizationHelp(context),
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      body: BlocBuilder<AvatarBloc, AvatarState>(
        builder: (context, state) {
          if (state is! AvatarLoaded) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar preview section
                _buildPreviewSection(context, state.avatar),
                const SizedBox(height: 24),

                // Customization panel
                _buildCustomizationPanel(context),
                const SizedBox(height: 24),

                // Quick actions
                _buildQuickActions(context, state.avatar),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPreviewSection(BuildContext context, avatar) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.1),
            colorScheme.secondary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Preview',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          AvatarPreview(
            avatar: avatar,
            size: 200,
          ),
          const SizedBox(height: 16),
          Text(
            avatar.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Level ${avatar.level}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomizationPanel(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customization Options',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: const AvatarCustomizationPanel(),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, avatar) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _resetToDefault(context, avatar),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.surface,
                  foregroundColor: colorScheme.onSurface,
                  side: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.5),
                  ),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Reset to Default'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _randomizeAppearance(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Randomize'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showCustomizationHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Customization Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How to customize your avatar:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. Select a category (Hair, Eyes, Clothing, Accessories)'),
              SizedBox(height: 4),
              Text('2. Choose an option from the grid'),
              SizedBox(height: 4),
              Text('3. See the preview update in real-time'),
              SizedBox(height: 4),
              Text('4. Tap "Apply Changes" to save your customization'),
              SizedBox(height: 16),
              Text(
                'Note:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Some options are locked and require higher levels'),
              SizedBox(height: 4),
              Text('• Your changes are previewed before applying'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _resetToDefault(BuildContext context, avatar) {
    // TODO: Implement reset to default appearance
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reset to default functionality coming soon!'),
      ),
    );
  }

  void _randomizeAppearance(BuildContext context) {
    // TODO: Implement randomize appearance
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Randomize functionality coming soon!'),
      ),
    );
  }
}