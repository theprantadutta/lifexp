import 'package:flutter/material.dart';
import 'package:rive/rive.dart' hide LinearGradient;

import '../../data/models/avatar.dart';

/// Interactive avatar widget with Rive animations
class InteractiveAvatar extends StatefulWidget {
  const InteractiveAvatar({
    required this.avatar,
    super.key,
    this.size = 120,
    this.onTap,
    this.showLevelUpAnimation = false,
    this.showAttributeGain = false,
    this.attributeType,
  });

  final Avatar avatar;
  final double size;
  final VoidCallback? onTap;
  final bool showLevelUpAnimation;
  final bool showAttributeGain;
  final AttributeType? attributeType;

  @override
  State<InteractiveAvatar> createState() => _InteractiveAvatarState();
}

class _InteractiveAvatarState extends State<InteractiveAvatar> {
  Artboard? _artboard;
  StateMachineController? _controller;
  SMIInput<bool>? _idleInput;
  SMIInput<bool>? _levelUpInput;
  SMIInput<bool>? _strengthInput;
  SMIInput<bool>? _wisdomInput;
  SMIInput<bool>? _intelligenceInput;
  SMIInput<bool>? _tapInput;

  @override
  void initState() {
    super.initState();
    _loadRiveFile();
  }

  void _loadRiveFile() {
    // Load the Rive file
    RiveFile.asset('assets/animations/avatar.riv').then((file) {
      final artboard = file.mainArtboard;
      final controller = StateMachineController.fromArtboard(
        artboard,
        'AvatarStateMachine',
      );

      if (controller != null) {
        artboard.addController(controller);
        
        // Get state machine inputs
        _idleInput = controller.findInput<bool>('idle');
        _levelUpInput = controller.findInput<bool>('levelUp');
        _strengthInput = controller.findInput<bool>('strength');
        _wisdomInput = controller.findInput<bool>('wisdom');
        _intelligenceInput = controller.findInput<bool>('intelligence');
        _tapInput = controller.findInput<bool>('tap');

        setState(() {
          _artboard = artboard;
          _controller = controller;
        });

        // Start with idle animation
        _playIdleAnimation();
      }
    }).catchError((error) {
      // Handle error loading Rive file
      debugPrint('Error loading Rive file: $error');
    });
  }

  void _playIdleAnimation() {
    _idleInput?.value = true;
  }

  void _playLevelUpAnimation() {
    _levelUpInput?.value = true;
    
    // Reset after animation duration
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _levelUpInput?.value = false;
        _playIdleAnimation();
      }
    });
  }

  void _playAttributeAnimation(AttributeType type) {
    switch (type) {
      case AttributeType.strength:
        _strengthInput?.value = true;
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _strengthInput?.value = false;
            _playIdleAnimation();
          }
        });
        break;
      case AttributeType.wisdom:
        _wisdomInput?.value = true;
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _wisdomInput?.value = false;
            _playIdleAnimation();
          }
        });
        break;
      case AttributeType.intelligence:
        _intelligenceInput?.value = true;
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _intelligenceInput?.value = false;
            _playIdleAnimation();
          }
        });
        break;
    }
  }

  void _playTapAnimation() {
    _tapInput?.value = true;
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _tapInput?.value = false;
        _playIdleAnimation();
      }
    });
  }

  @override
  void didUpdateWidget(InteractiveAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Trigger animations based on widget updates
    if (widget.showLevelUpAnimation && !oldWidget.showLevelUpAnimation) {
      _playLevelUpAnimation();
    }

    if (widget.showAttributeGain && 
        !oldWidget.showAttributeGain && 
        widget.attributeType != null) {
      _playAttributeAnimation(widget.attributeType!);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () {
        _playTapAnimation();
        widget.onTap?.call();
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              colorScheme.primary.withValues(alpha: 0.1),
              colorScheme.secondary.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipOval(
          child: _artboard != null
              ? Rive(
                  artboard: _artboard!,
                  fit: BoxFit.cover,
                )
              : _buildFallbackAvatar(context),
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.primary.withValues(alpha: 0.1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Base avatar icon
          Icon(
            Icons.person,
            size: widget.size * 0.5,
            color: colorScheme.primary,
          ),
          
          // Level indicator
          Positioned(
            bottom: widget.size * 0.1,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Lv.${widget.avatar.level}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar preview widget for customization
class AvatarPreview extends StatefulWidget {
  const AvatarPreview({
    required this.avatar, super.key,
    this.size = 200,
    this.customizations = const {},
    this.showPreviewAnimation = false,
  });

  final Avatar avatar;
  final double size;
  final Map<String, String> customizations;
  final bool showPreviewAnimation;

  @override
  State<AvatarPreview> createState() => _AvatarPreviewState();
}

class _AvatarPreviewState extends State<AvatarPreview> {
  Artboard? _artboard;
  StateMachineController? _controller;
  SMIInput<bool>? _previewInput;
  SMIInput<String>? _hairInput;
  SMIInput<String>? _eyesInput;
  SMIInput<String>? _clothingInput;
  SMIInput<String>? _accessoryInput;

  @override
  void initState() {
    super.initState();
    _loadRiveFile();
  }

  void _loadRiveFile() {
    RiveFile.asset('assets/animations/avatar_customization.riv').then((file) {
      final artboard = file.mainArtboard;
      final controller = StateMachineController.fromArtboard(
        artboard,
        'CustomizationStateMachine',
      );

      if (controller != null) {
        artboard.addController(controller);
        
        // Get customization inputs
        _previewInput = controller.findInput<bool>('preview');
        _hairInput = controller.findInput<String>('hair');
        _eyesInput = controller.findInput<String>('eyes');
        _clothingInput = controller.findInput<String>('clothing');
        _accessoryInput = controller.findInput<String>('accessory');

        setState(() {
          _artboard = artboard;
          _controller = controller;
        });

        _applyCustomizations();
      }
    }).catchError((error) {
      debugPrint('Error loading avatar customization Rive file: $error');
    });
  }

  void _applyCustomizations() {
    _hairInput?.value = widget.customizations['hair'] ?? 'default';
    _eyesInput?.value = widget.customizations['eyes'] ?? 'default';
    _clothingInput?.value = widget.customizations['clothing'] ?? 'default';
    _accessoryInput?.value = widget.customizations['accessory'] ?? 'none';
  }

  void _playPreviewAnimation() {
    _previewInput?.value = true;
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _previewInput?.value = false;
      }
    });
  }

  @override
  void didUpdateWidget(AvatarPreview oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.customizations != oldWidget.customizations) {
      _applyCustomizations();
    }

    if (widget.showPreviewAnimation && !oldWidget.showPreviewAnimation) {
      _playPreviewAnimation();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surface,
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(
        child: _artboard != null
            ? Rive(
                artboard: _artboard!,
                fit: BoxFit.cover,
              )
            : _buildFallbackPreview(context),
      ),
    );
  }

  Widget _buildFallbackPreview(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.1),
            colorScheme.secondary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        Icons.person,
        size: widget.size * 0.4,
        color: colorScheme.primary,
      ),
    );
  }
}

/// Animated avatar for level up sequences
class LevelUpAvatar extends StatefulWidget {
  const LevelUpAvatar({
    required this.avatar, required this.onAnimationComplete, super.key,
    this.size = 150,
  });

  final Avatar avatar;
  final VoidCallback onAnimationComplete;
  final double size;

  @override
  State<LevelUpAvatar> createState() => _LevelUpAvatarState();
}

class _LevelUpAvatarState extends State<LevelUpAvatar>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _scaleController;
  late Animation<double> _glowAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _glowAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // Start animations
    _glowController.repeat(reverse: true);
    _scaleController.forward().then((_) {
      _scaleController.reverse().then((_) {
        widget.onAnimationComplete();
      });
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: Listenable.merge([_glowAnimation, _scaleAnimation]),
      builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(
                    alpha: _glowAnimation.value * 0.6,
                  ),
                  blurRadius: 20 * _glowAnimation.value,
                  spreadRadius: 5 * _glowAnimation.value,
                ),
              ],
            ),
            child: InteractiveAvatar(
              avatar: widget.avatar,
              size: widget.size,
              showLevelUpAnimation: true,
            ),
          ),
        ),
    );
  }
}