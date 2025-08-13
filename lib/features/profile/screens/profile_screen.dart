import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/blocs/achievement/achievement_bloc.dart';
import '../../../shared/blocs/achievement/achievement_state.dart';
import '../../../shared/blocs/avatar/avatar_bloc.dart';
import '../../../shared/blocs/avatar/avatar_state.dart';
import '../../../shared/blocs/theme/theme_bloc.dart';
import '../../../shared/blocs/theme/theme_event.dart';
import '../../../shared/blocs/theme/theme_state.dart';
import '../widgets/achievement_gallery.dart';
import '../widgets/avatar_customization_panel.dart';
import '../widgets/profile_stats_card.dart';

/// Profile screen with avatar customization and achievements
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showSettingsDialog(context),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: BlocBuilder<AvatarBloc, AvatarState>(
        builder: (context, avatarState) => BlocBuilder<AchievementBloc, AchievementState>(
            builder: (context, achievementState) => SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar and basic info
                    _buildAvatarSection(context, avatarState),
                    const SizedBox(height: 24),

                    // Stats overview
                    _buildStatsSection(context, avatarState),
                    const SizedBox(height: 24),

                    // Avatar customization
                    _buildCustomizationSection(context, avatarState),
                    const SizedBox(height: 24),

                    // Achievement gallery
                    _buildAchievementSection(context, achievementState),
                  ],
                ),
              ),
          ),
      ),
    );
  }

  Widget _buildAvatarSection(BuildContext context, AvatarState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (state is! AvatarLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final avatar = state.avatar;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
          // Avatar display
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.primary,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.person,
              size: 60,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),

          // Level and XP
          Text(
            'Level ${avatar.level}',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // XP Progress
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${avatar.currentXP} XP',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${avatar.xpToNextLevel} XP to next level',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: avatar.currentXP / (avatar.currentXP + avatar.xpToNextLevel),
                backgroundColor: colorScheme.outline.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation(colorScheme.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, AvatarState state) {
    if (state is! AvatarLoaded) {
      return const SizedBox.shrink();
    }

    return ProfileStatsCard(avatar: state.avatar);
  }

  Widget _buildCustomizationSection(BuildContext context, AvatarState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customize Avatar',
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

  Widget _buildAchievementSection(BuildContext context, AchievementState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Achievements',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (state is AchievementLoaded)
              Text(
                '${state.achievements.where((a) => a.isUnlocked).length}/${state.achievements.length}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        const AchievementGallery(),
      ],
    );
  }

  void _showSettingsDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Theme toggle
            BlocBuilder<ThemeBloc, ThemeState>(
              builder: (context, state) => ListTile(
                  leading: Icon(
                    state.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: colorScheme.primary,
                  ),
                  title: const Text('Dark Mode'),
                  trailing: Switch(
                    value: state.isDarkMode,
                    onChanged: (value) {
                      context.read<ThemeBloc>().add(const ToggleDarkModeEvent());
                    },
                  ),
                ),
            ),
            
            // Notifications toggle
            ListTile(
              leading: Icon(
                Icons.notifications,
                color: colorScheme.primary,
              ),
              title: const Text('Notifications'),
              trailing: Switch(
                value: true, // TODO: Connect to notification settings
                onChanged: (value) {
                  // TODO: Implement notification toggle
                },
              ),
            ),

            // About
            ListTile(
              leading: Icon(
                Icons.info,
                color: colorScheme.primary,
              ),
              title: const Text('About'),
              onTap: () {
                Navigator.of(context).pop();
                _showAboutDialog(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'LifeXP',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.stars, size: 48),
      children: [
        const Text(
          'Transform your daily tasks into an epic adventure! '
          'Gain XP, level up your avatar, and unlock achievements '
          'as you build better habits and achieve your goals.',
        ),
      ],
    );
  }
}