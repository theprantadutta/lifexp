import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Service for managing memory usage and preventing memory leaks
class MemoryManagementService {
  factory MemoryManagementService() => _instance;
  MemoryManagementService._internal();
  static final MemoryManagementService _instance = MemoryManagementService._internal();

  final Map<String, StreamSubscription> _subscriptions = {};
  final Map<String, Timer> _timers = {};
  final Map<String, AnimationController> _animationControllers = {};
  final Set<String> _activeWidgets = {};
  
  Timer? _memoryCheckTimer;
  bool _isMonitoring = false;

  /// Initialize memory management
  void initialize() {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    _startMemoryMonitoring();
    
    if (kDebugMode) {
      developer.log('MemoryManagementService: Memory monitoring started');
    }
  }

  /// Register a stream subscription for automatic cleanup
  void registerSubscription(String key, StreamSubscription subscription) {
    // Cancel existing subscription if any
    _subscriptions[key]?.cancel();
    _subscriptions[key] = subscription;
    
    if (kDebugMode) {
      developer.log('MemoryManagementService: Registered subscription: $key');
    }
  }

  /// Register a timer for automatic cleanup
  void registerTimer(String key, Timer timer) {
    // Cancel existing timer if any
    _timers[key]?.cancel();
    _timers[key] = timer;
    
    if (kDebugMode) {
      developer.log('MemoryManagementService: Registered timer: $key');
    }
  }

  /// Register an animation controller for automatic cleanup
  void registerAnimationController(String key, AnimationController controller) {
    // Dispose existing controller if any
    _animationControllers[key]?.dispose();
    _animationControllers[key] = controller;
    
    if (kDebugMode) {
      developer.log('MemoryManagementService: Registered animation controller: $key');
    }
  }

  /// Register active widget
  void registerWidget(String widgetKey) {
    _activeWidgets.add(widgetKey);
  }

  /// Unregister widget and cleanup its resources
  void unregisterWidget(String widgetKey) {
    _activeWidgets.remove(widgetKey);
    
    // Cleanup associated resources
    _cleanupWidgetResources(widgetKey);
  }

  /// Cleanup resources for a specific widget
  void _cleanupWidgetResources(String widgetKey) {
    // Cancel subscriptions
    final subscriptionsToRemove = _subscriptions.keys
        .where((key) => key.startsWith(widgetKey))
        .toList();
    
    for (final key in subscriptionsToRemove) {
      _subscriptions[key]?.cancel();
      _subscriptions.remove(key);
    }
    
    // Cancel timers
    final timersToRemove = _timers.keys
        .where((key) => key.startsWith(widgetKey))
        .toList();
    
    for (final key in timersToRemove) {
      _timers[key]?.cancel();
      _timers.remove(key);
    }
    
    // Dispose animation controllers
    final controllersToRemove = _animationControllers.keys
        .where((key) => key.startsWith(widgetKey))
        .toList();
    
    for (final key in controllersToRemove) {
      _animationControllers[key]?.dispose();
      _animationControllers.remove(key);
    }
    
    if (kDebugMode && (subscriptionsToRemove.isNotEmpty || timersToRemove.isNotEmpty || controllersToRemove.isNotEmpty)) {
      developer.log('MemoryManagementService: Cleaned up resources for widget: $widgetKey');
    }
  }

  /// Cancel specific subscription
  void cancelSubscription(String key) {
    _subscriptions[key]?.cancel();
    _subscriptions.remove(key);
  }

  /// Cancel specific timer
  void cancelTimer(String key) {
    _timers[key]?.cancel();
    _timers.remove(key);
  }

  /// Dispose specific animation controller
  void disposeAnimationController(String key) {
    _animationControllers[key]?.dispose();
    _animationControllers.remove(key);
  }

  /// Start memory monitoring
  void _startMemoryMonitoring() {
    _memoryCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _performMemoryCheck();
    });
  }

  /// Perform memory check and cleanup
  void _performMemoryCheck() {
    if (kDebugMode) {
      final stats = getMemoryStats();
      developer.log('MemoryManagementService: Memory check - ${stats['summary']}');
      
      // Cleanup orphaned resources
      _cleanupOrphanedResources();
    }
  }

  /// Cleanup orphaned resources
  void _cleanupOrphanedResources() {
    var cleanedCount = 0;
    
    // Check for orphaned subscriptions (not associated with active widgets)
    final orphanedSubscriptions = _subscriptions.keys
        .where((key) => !_activeWidgets.any((widget) => key.startsWith(widget)))
        .toList();
    
    for (final key in orphanedSubscriptions) {
      _subscriptions[key]?.cancel();
      _subscriptions.remove(key);
      cleanedCount++;
    }
    
    // Check for orphaned timers
    final orphanedTimers = _timers.keys
        .where((key) => !_activeWidgets.any((widget) => key.startsWith(widget)))
        .toList();
    
    for (final key in orphanedTimers) {
      _timers[key]?.cancel();
      _timers.remove(key);
      cleanedCount++;
    }
    
    // Check for orphaned animation controllers
    final orphanedControllers = _animationControllers.keys
        .where((key) => !_activeWidgets.any((widget) => key.startsWith(widget)))
        .toList();
    
    for (final key in orphanedControllers) {
      _animationControllers[key]?.dispose();
      _animationControllers.remove(key);
      cleanedCount++;
    }
    
    if (kDebugMode && cleanedCount > 0) {
      developer.log('MemoryManagementService: Cleaned up $cleanedCount orphaned resources');
    }
  }

  /// Force garbage collection (debug only)
  void forceGarbageCollection() {
    if (kDebugMode) {
      // This is a hint to the VM, not guaranteed to trigger GC
      developer.log('MemoryManagementService: Requesting garbage collection');
    }
  }

  /// Get memory usage statistics
  Map<String, dynamic> getMemoryStats() => {
      'activeWidgets': _activeWidgets.length,
      'subscriptions': _subscriptions.length,
      'timers': _timers.length,
      'animationControllers': _animationControllers.length,
      'summary': '${_activeWidgets.length} widgets, ${_subscriptions.length} subscriptions, ${_timers.length} timers, ${_animationControllers.length} controllers',
    };

  /// Cleanup all resources
  void cleanupAll() {
    // Cancel all subscriptions
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    
    // Cancel all timers
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    
    // Dispose all animation controllers
    for (final controller in _animationControllers.values) {
      controller.dispose();
    }
    _animationControllers.clear();
    
    // Clear active widgets
    _activeWidgets.clear();
    
    if (kDebugMode) {
      developer.log('MemoryManagementService: Cleaned up all resources');
    }
  }

  /// Dispose the service
  void dispose() {
    _memoryCheckTimer?.cancel();
    cleanupAll();
    _isMonitoring = false;
  }
}

/// Mixin for widgets that need automatic memory management
mixin MemoryManagedMixin<T extends StatefulWidget> on State<T> {
  late final String _widgetKey;
  final MemoryManagementService _memoryService = MemoryManagementService();
  
  @override
  void initState() {
    super.initState();
    _widgetKey = '${widget.runtimeType}_$hashCode';
    _memoryService.registerWidget(_widgetKey);
  }
  
  @override
  void dispose() {
    _memoryService.unregisterWidget(_widgetKey);
    super.dispose();
  }
  
  /// Register a stream subscription for automatic cleanup
  void registerSubscription(String name, StreamSubscription subscription) {
    _memoryService.registerSubscription('${_widgetKey}_$name', subscription);
  }
  
  /// Register a timer for automatic cleanup
  void registerTimer(String name, Timer timer) {
    _memoryService.registerTimer('${_widgetKey}_$name', timer);
  }
  
  /// Register an animation controller for automatic cleanup
  void registerAnimationController(String name, AnimationController controller) {
    _memoryService.registerAnimationController('${_widgetKey}_$name', controller);
  }
  
  /// Cancel a specific subscription
  void cancelSubscription(String name) {
    _memoryService.cancelSubscription('${_widgetKey}_$name');
  }
  
  /// Cancel a specific timer
  void cancelTimer(String name) {
    _memoryService.cancelTimer('${_widgetKey}_$name');
  }
  
  /// Dispose a specific animation controller
  void disposeAnimationController(String name) {
    _memoryService.disposeAnimationController('${_widgetKey}_$name');
  }
}

/// Widget that automatically manages memory for its children
class MemoryManagedWidget extends StatefulWidget {

  const MemoryManagedWidget({
    required this.child, super.key,
    this.debugLabel,
  });
  final Widget child;
  final String? debugLabel;

  @override
  State<MemoryManagedWidget> createState() => _MemoryManagedWidgetState();
}

class _MemoryManagedWidgetState extends State<MemoryManagedWidget> 
    with MemoryManagedMixin {
  
  @override
  Widget build(BuildContext context) => widget.child;
}

/// Optimized stream builder that automatically manages subscriptions
class OptimizedStreamBuilder<T> extends StatefulWidget {

  const OptimizedStreamBuilder({
    required this.builder, super.key,
    this.stream,
    this.initialData,
  });
  final Stream<T>? stream;
  final T? initialData;
  final AsyncWidgetBuilder<T> builder;

  @override
  State<OptimizedStreamBuilder<T>> createState() => _OptimizedStreamBuilderState<T>();
}

class _OptimizedStreamBuilderState<T> extends State<OptimizedStreamBuilder<T>> 
    with MemoryManagedMixin {
  
  late AsyncSnapshot<T> _snapshot;
  
  @override
  void initState() {
    super.initState();
    _snapshot = AsyncSnapshot<T>.withData(ConnectionState.none, widget.initialData as T);
    _subscribe();
  }
  
  @override
  void didUpdateWidget(OptimizedStreamBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stream != widget.stream) {
      _subscribe();
    }
  }
  
  void _subscribe() {
    if (widget.stream != null) {
      registerSubscription('stream', widget.stream!.listen(
        (data) {
          if (mounted) {
            setState(() {
              _snapshot = AsyncSnapshot<T>.withData(ConnectionState.active, data);
            });
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          if (mounted) {
            setState(() {
              _snapshot = AsyncSnapshot<T>.withError(ConnectionState.active, error, stackTrace);
            });
          }
        },
        onDone: () {
          if (mounted) {
            setState(() {
              _snapshot = _snapshot.inState(ConnectionState.done);
            });
          }
        },
      ));
    }
  }
  
  @override
  Widget build(BuildContext context) => widget.builder(context, _snapshot);
}

/// Optimized future builder that automatically manages resources
class OptimizedFutureBuilder<T> extends StatefulWidget {

  const OptimizedFutureBuilder({
    required this.builder, super.key,
    this.future,
    this.initialData,
  });
  final Future<T>? future;
  final T? initialData;
  final AsyncWidgetBuilder<T> builder;

  @override
  State<OptimizedFutureBuilder<T>> createState() => _OptimizedFutureBuilderState<T>();
}

class _OptimizedFutureBuilderState<T> extends State<OptimizedFutureBuilder<T>> 
    with MemoryManagedMixin {
  
  late AsyncSnapshot<T> _snapshot;
  Object? _activeCallbackIdentity;
  
  @override
  void initState() {
    super.initState();
    _snapshot = AsyncSnapshot<T>.withData(ConnectionState.none, widget.initialData as T);
    _subscribe();
  }
  
  @override
  void didUpdateWidget(OptimizedFutureBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.future != widget.future) {
      _subscribe();
    }
  }
  
  void _subscribe() {
    if (widget.future != null) {
      final callbackIdentity = Object();
      _activeCallbackIdentity = callbackIdentity;
      
      widget.future!.then<void>((data) {
        if (_activeCallbackIdentity == callbackIdentity && mounted) {
          setState(() {
            _snapshot = AsyncSnapshot<T>.withData(ConnectionState.done, data);
          });
        }
      }, onError: (Object error, StackTrace stackTrace) {
        if (_activeCallbackIdentity == callbackIdentity && mounted) {
          setState(() {
            _snapshot = AsyncSnapshot<T>.withError(ConnectionState.done, error, stackTrace);
          });
        }
      });
      
      _snapshot = _snapshot.inState(ConnectionState.waiting);
    }
  }
  
  @override
  Widget build(BuildContext context) => widget.builder(context, _snapshot);
}