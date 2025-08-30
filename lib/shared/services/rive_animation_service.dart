import 'package:flutter/material.dart';
import 'package:rive/rive.dart' hide LinearGradient;

/// Service for managing Rive animations throughout the app
class RiveAnimationService {
  static final Map<String, RiveFile> _loadedFiles = {};
  static final Map<String, Artboard> _artboards = {};

  /// Preloads commonly used Rive files
  static Future<void> preloadAnimations() async {
    final filesToLoad = [
      'assets/animations/avatar.riv',
      'assets/animations/avatar_customization.riv',
      'assets/animations/progress_bar.riv',
      'assets/animations/attribute_effects.riv',
    ];

    for (final filePath in filesToLoad) {
      try {
        final file = await RiveFile.asset(filePath);
        _loadedFiles[filePath] = file;
        debugPrint('Preloaded Rive file: $filePath');
      } catch (e) {
        debugPrint('Failed to preload Rive file $filePath: $e');
      }
    }
  }

  /// Gets a Rive file, loading it if not already cached
  static Future<RiveFile?> getRiveFile(String assetPath) async {
    if (_loadedFiles.containsKey(assetPath)) {
      return _loadedFiles[assetPath];
    }

    try {
      final file = await RiveFile.asset(assetPath);
      _loadedFiles[assetPath] = file;
      return file;
    } catch (e) {
      debugPrint('Failed to load Rive file $assetPath: $e');
      return null;
    }
  }

  /// Creates an artboard from a Rive file
  static Future<Artboard?> createArtboard(
    String assetPath, {
    String? artboardName,
  }) async {
    final file = await getRiveFile(assetPath);
    if (file == null) return null;

    try {
      final artboard = artboardName != null
          ? file.artboardByName(artboardName)
          : file.mainArtboard;
      
      return artboard?.instance();
    } catch (e) {
      debugPrint('Failed to create artboard from $assetPath: $e');
      return null;
    }
  }

  /// Creates a state machine controller for an artboard
  static StateMachineController? createStateMachineController(
    Artboard artboard,
    String stateMachineName,
  ) {
    try {
      final controller = StateMachineController.fromArtboard(
        artboard,
        stateMachineName,
      );
      
      if (controller != null) {
        artboard.addController(controller);
      }
      
      return controller;
    } catch (e) {
      debugPrint('Failed to create state machine controller: $e');
      return null;
    }
  }

  /// Disposes of cached resources
  static void dispose() {
    _loadedFiles.clear();
    _artboards.clear();
  }
}

/// Mixin for widgets that use Rive animations
mixin RiveAnimationMixin<T extends StatefulWidget> on State<T> {
  final List<StateMachineController> _controllers = [];

  /// Helper method to load and setup a Rive animation
  Future<RiveAnimationSetup?> setupRiveAnimation({
    required String assetPath,
    required String stateMachineName,
    String? artboardName,
  }) async {
    final artboard = await RiveAnimationService.createArtboard(
      assetPath,
      artboardName: artboardName,
    );
    
    if (artboard == null) return null;

    final controller = RiveAnimationService.createStateMachineController(
      artboard,
      stateMachineName,
    );

    if (controller == null) return null;

    _controllers.add(controller);

    return RiveAnimationSetup(
      artboard: artboard,
      controller: controller,
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    _controllers.clear();
    super.dispose();
  }
}

/// Container for Rive animation setup
class RiveAnimationSetup {
  const RiveAnimationSetup({
    required this.artboard,
    required this.controller,
  });

  final Artboard artboard;
  final StateMachineController controller;

  /// Gets a boolean input from the state machine
  SMIInput<bool>? getBoolInput(String name) => controller.findInput<bool>(name);

  /// Gets a number input from the state machine
  SMIInput<double>? getNumberInput(String name) => controller.findInput<double>(name);

  /// Gets a trigger input from the state machine
  SMIInput<bool>? getTriggerInput(String name) => controller.findInput<bool>(name);

  /// Gets a string input from the state machine
  SMIInput<String>? getStringInput(String name) => controller.findInput<String>(name);
}

/// Widget that provides a fallback when Rive animations fail to load
class RiveFallback extends StatelessWidget {
  const RiveFallback({
    required this.child, required this.fallback, super.key,
  });

  final Widget child;
  final Widget fallback;

  @override
  Widget build(BuildContext context) => child;
}

/// Animated progress bar using Rive
class RiveProgressBar extends StatefulWidget {
  const RiveProgressBar({
    required this.progress, super.key,
    this.height = 20,
    this.animationDuration = const Duration(milliseconds: 800),
  });

  final double progress; // 0.0 to 1.0
  final double height;
  final Duration animationDuration;

  @override
  State<RiveProgressBar> createState() => _RiveProgressBarState();
}

class _RiveProgressBarState extends State<RiveProgressBar>
    with RiveAnimationMixin {
  RiveAnimationSetup? _animationSetup;
  SMIInput<double>? _progressInput;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
  }

  Future<void> _setupAnimation() async {
    final setup = await setupRiveAnimation(
      assetPath: 'assets/animations/progress_bar.riv',
      stateMachineName: 'ProgressStateMachine',
    );

    if (setup != null) {
      setState(() {
        _animationSetup = setup;
        _progressInput = setup.getNumberInput('progress');
        _progressInput?.value = widget.progress;
      });
    }
  }

  @override
  void didUpdateWidget(RiveProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.progress != oldWidget.progress) {
      _progressInput?.value = widget.progress;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: _animationSetup != null
          ? Rive(artboard: _animationSetup!.artboard)
          : _buildFallbackProgressBar(context),
    );
  }

  Widget _buildFallbackProgressBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(widget.height / 2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: widget.progress,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary,
                colorScheme.secondary,
              ],
            ),
            borderRadius: BorderRadius.circular(widget.height / 2),
          ),
        ),
      ),
    );
  }
}

/// Attribute effect animations using Rive
class AttributeEffectAnimation extends StatefulWidget {
  const AttributeEffectAnimation({
    required this.attributeType, required this.onComplete, super.key,
    this.size = 100,
  });

  final String attributeType; // 'strength', 'wisdom', 'intelligence'
  final VoidCallback onComplete;
  final double size;

  @override
  State<AttributeEffectAnimation> createState() => _AttributeEffectAnimationState();
}

class _AttributeEffectAnimationState extends State<AttributeEffectAnimation>
    with RiveAnimationMixin {
  RiveAnimationSetup? _animationSetup;
  SMIInput<bool>? _triggerInput;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
  }

  Future<void> _setupAnimation() async {
    final setup = await setupRiveAnimation(
      assetPath: 'assets/animations/attribute_effects.riv',
      stateMachineName: 'AttributeStateMachine',
    );

    if (setup != null) {
      setState(() {
        _animationSetup = setup;
        _triggerInput = setup.getTriggerInput(widget.attributeType);
        _triggerInput?.value = true;
      });

      // Complete after animation duration
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          widget.onComplete();
        }
      });
    } else {
      // Fallback completion
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          widget.onComplete();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: _animationSetup != null
          ? Rive(artboard: _animationSetup!.artboard)
          : _buildFallbackEffect(context),
    );
  }

  Widget _buildFallbackEffect(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    IconData icon;
    Color color;

    switch (widget.attributeType) {
      case 'strength':
        icon = Icons.fitness_center;
        color = Colors.red;
        break;
      case 'wisdom':
        icon = Icons.psychology;
        color = Colors.blue;
        break;
      case 'intelligence':
        icon = Icons.school;
        color = Colors.purple;
        break;
      default:
        icon = Icons.star;
        color = colorScheme.primary;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.2),
      ),
      child: Icon(
        icon,
        size: widget.size * 0.5,
        color: color,
      ),
    );
  }
}