import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/world_tile.dart';
import '../../../shared/blocs/avatar/avatar_bloc_exports.dart';
import '../../../shared/blocs/world/world_bloc_exports.dart';
import '../../../shared/providers/user_context.dart';
import '../widgets/tile_info_panel.dart';
import '../widgets/world_map.dart';
import '../widgets/world_stats_panel.dart';

/// World screen for exploring the interactive map and world building
class WorldScreen extends StatefulWidget {
  const WorldScreen({super.key});

  @override
  State<WorldScreen> createState() => _WorldScreenState();
}

class _WorldScreenState extends State<WorldScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  WorldTile? _selectedTile;
  bool _showStats = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.currentUserOrNull;
    if (user != null) {
      context.read<WorldBloc>().add(LoadWorldTiles(userId: user.id));
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
      title: const Text('World'),
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: Icon(_showStats ? Icons.map : Icons.analytics),
          onPressed: () {
            setState(() {
              _showStats = !_showStats;
            });
          },
          tooltip: _showStats ? 'Show Map' : 'Show Stats',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'reset_view':
                // Reset map view to center
                break;
              case 'unlock_all':
                // Debug option to unlock all tiles
                final user = context.currentUserOrNull;
                if (user != null) {
                  // TODO: Implement unlock all tiles functionality
                  // Need to get current XP and category progress
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Unlock all tiles feature coming soon!')),
                  );
                }
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'reset_view',
              child: Row(
                children: [
                  Icon(Icons.center_focus_strong),
                  SizedBox(width: 8),
                  Text('Reset View'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'unlock_all',
              child: Row(
                children: [
                  Icon(Icons.lock_open),
                  SizedBox(width: 8),
                  Text('Unlock All (Debug)'),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
    body: BlocBuilder<WorldBloc, WorldState>(
      builder: (context, worldState) => BlocBuilder<AvatarBloc, AvatarState>(
        builder: (context, avatarState) {
          if (worldState is WorldLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (worldState is WorldError) {
            return _buildErrorState(worldState.message);
          }

          if (worldState is WorldLoaded) {
            return _showStats
                ? _buildStatsView(worldState, avatarState)
                : _buildMapView(worldState, avatarState);
          }

          return _buildEmptyState();
        },
      ),
    ),
    bottomSheet: _selectedTile != null
        ? TileInfoPanel(
            tile: _selectedTile!,
            onClose: () {
              setState(() {
                _selectedTile = null;
              });
            },
            onUnlock: () => _unlockTile(_selectedTile!),
          )
        : null,
  );

  Widget _buildMapView(WorldLoaded worldState, AvatarState avatarState) => Column(
        children: [
          if (avatarState is AvatarLoaded) _buildWorldHeader(avatarState.avatar),
          Expanded(
            child: WorldMap(
              tiles: worldState.worldTiles,
              onTileSelected: (tile) {
                setState(() {
                  _selectedTile = tile;
                });
              },
              selectedTile: _selectedTile,
            ),
          ),
        ],
      );

  Widget _buildStatsView(WorldLoaded worldState, AvatarState avatarState) => WorldStatsPanel(
        tiles: worldState.worldTiles,
        currentXP: avatarState is AvatarLoaded ? avatarState.avatar.currentXP : 0,
        categoryProgress: const {}, // TODO: Get from progress state
      );

  Widget _buildWorldHeader(avatar) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                'L${avatar.level}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explorer Level ${avatar.level}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '${avatar.currentXp} XP • ${_getUnlockedTilesCount()} areas unlocked',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.explore,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
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
                'Error loading world',
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
                    context.read<WorldBloc>().add(LoadWorldTiles(userId: user.id));
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
                Icons.public,
                size: 48,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'World not initialized',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Complete some tasks to start building your world!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  final user = context.currentUserOrNull;
                  if (user != null) {
                    context.read<WorldBloc>().add(
                      CreateDefaultWorld(userId: user.id),
                    );
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Initialize World'),
              ),
            ],
          ),
        ),
      );

  int _getUnlockedTilesCount() {
    final worldState = context.read<WorldBloc>().state;
    if (worldState is WorldLoaded) {
      return worldState.worldTiles.where((tile) => tile.isUnlocked).length;
    }
    return 0;
  }

  void _unlockTile(WorldTile tile) {
    final user = context.currentUserOrNull;
    if (user != null) {
      context.read<WorldBloc>().add(
        UnlockTile(
          tileId: tile.id,
          currentXP: 0, // TODO: Get actual XP from user state
          categoryProgress: {}, // TODO: Get actual category progress
        ),
      );
    }
  }

  void _customizeTile(WorldTile tile) {
    // Show customization dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Customize ${tile.type.displayName}'),
        content: const Text('Tile customization coming soon!'),
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
