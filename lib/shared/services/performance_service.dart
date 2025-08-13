import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Service for monitoring and optimizing app performance
class PerformanceService {
  factory PerformanceService() => _instance;
  PerformanceService._internal();
  static final PerformanceService _instance = PerformanceService._internal();

  final Map<String, Stopwatch> _timers = {};
  final Map<String, List<Duration>> _metrics = {};
  final List<String> _memoryWarnings = [];
  
  Timer? _memoryMonitorTimer;
  bool _isMonitoring = false;

  /// Initialize performance monitoring
  void initialize() {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    _startMemoryMonitoring();
    
    if (kDebugMode) {
      developer.log('PerformanceService: Monitoring initialized');
    }
  }

  /// Start timing an operation
  void startTimer(String operationName) {
    _timers[operationName] = Stopwatch()..start();
  }

  /// Stop timing an operation and record the duration
  Duration? stopTimer(String operationName) {
    final timer = _timers.remove(operationName);
    if (timer == null) return null;
    
    timer.stop();
    final duration = timer.elapsed;
    
    // Record metric
    _metrics.putIfAbsent(operationName, () => []).add(duration);
    
    // Log slow operations in debug mode
    if (kDebugMode && duration.inMilliseconds > 100) {
      developer.log('PerformanceService: Slow operation "$operationName": ${duration.inMilliseconds}ms');
    }
    
    return duration;
  }

  /// Measure the performance of a function
  Future<T> measureAsync<T>(String operationName, Future<T> Function() operation) async {
    startTimer(operationName);
    try {
      final result = await operation();
      return result;
    } finally {
      stopTimer(operationName);
    }
  }

  /// Measure the performance of a synchronous function
  T measureSync<T>(String operationName, T Function() operation) {
    startTimer(operationName);
    try {
      final result = operation();
      return result;
    } finally {
      stopTimer(operationName);
    }
  }

  /// Get performance metrics for an operation
  PerformanceMetrics? getMetrics(String operationName) {
    final durations = _metrics[operationName];
    if (durations == null || durations.isEmpty) return null;
    
    final totalMs = durations.fold(0, (sum, duration) => sum + duration.inMilliseconds);
    final avgMs = totalMs / durations.length;
    final minMs = durations.map((d) => d.inMilliseconds).reduce((a, b) => a < b ? a : b);
    final maxMs = durations.map((d) => d.inMilliseconds).reduce((a, b) => a > b ? a : b);
    
    return PerformanceMetrics(
      operationName: operationName,
      callCount: durations.length,
      averageMs: avgMs,
      minMs: minMs,
      maxMs: maxMs,
      totalMs: totalMs,
    );
  }

  /// Get all performance metrics
  Map<String, PerformanceMetrics> getAllMetrics() {
    final result = <String, PerformanceMetrics>{};
    for (final operationName in _metrics.keys) {
      final metrics = getMetrics(operationName);
      if (metrics != null) {
        result[operationName] = metrics;
      }
    }
    return result;
  }

  /// Clear all metrics
  void clearMetrics() {
    _metrics.clear();
    _timers.clear();
  }

  /// Start memory monitoring
  void _startMemoryMonitoring() {
    _memoryMonitorTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkMemoryUsage();
    });
  }

  /// Check current memory usage
  void _checkMemoryUsage() {
    if (!kDebugMode) return;
    
    // This is a simplified memory check - in production you'd use more sophisticated tools
    final info = developer.Service.getInfo();
    developer.log('PerformanceService: Memory check completed');
  }

  /// Report memory warning
  void reportMemoryWarning(String context) {
    _memoryWarnings.add('${DateTime.now()}: $context');
    
    if (kDebugMode) {
      developer.log('PerformanceService: Memory warning - $context');
    }
    
    // Keep only last 10 warnings
    if (_memoryWarnings.length > 10) {
      _memoryWarnings.removeAt(0);
    }
  }

  /// Get memory warnings
  List<String> getMemoryWarnings() => List.unmodifiable(_memoryWarnings);

  /// Optimize widget build performance
  static Widget optimizeWidgetBuild({
    required Widget child,
    String? debugLabel,
  }) => RepaintBoundary(
      child: child,
    );

  /// Create optimized list view
  static Widget createOptimizedListView({
    required List<Widget> children,
    ScrollController? controller,
    EdgeInsets? padding,
    bool shrinkWrap = false,
  }) => ListView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      itemCount: children.length,
      itemBuilder: (context, index) => RepaintBoundary(
          child: children[index],
        ),
    );

  /// Create optimized grid view
  static Widget createOptimizedGridView({
    required List<Widget> children,
    required SliverGridDelegate gridDelegate,
    ScrollController? controller,
    EdgeInsets? padding,
    bool shrinkWrap = false,
  }) => GridView.builder(
      gridDelegate: gridDelegate,
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      itemCount: children.length,
      itemBuilder: (context, index) => RepaintBoundary(
          child: children[index],
        ),
    );

  /// Optimize image loading
  static Widget optimizeImage({
    required String imagePath,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    String? cacheKey,
  }) => Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: width?.round(),
      cacheHeight: height?.round(),
    );

  /// Debounce function calls
  static Timer? _debounceTimer;
  static void debounce(Duration delay, VoidCallback callback) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, callback);
  }

  /// Throttle function calls
  static DateTime? _lastThrottleTime;
  static void throttle(Duration interval, VoidCallback callback) {
    final now = DateTime.now();
    if (_lastThrottleTime == null || now.difference(_lastThrottleTime!) >= interval) {
      _lastThrottleTime = now;
      callback();
    }
  }

  /// Dispose resources
  void dispose() {
    _memoryMonitorTimer?.cancel();
    _timers.clear();
    _metrics.clear();
    _memoryWarnings.clear();
    _isMonitoring = false;
  }
}

/// Performance metrics data class
class PerformanceMetrics {

  const PerformanceMetrics({
    required this.operationName,
    required this.callCount,
    required this.averageMs,
    required this.minMs,
    required this.maxMs,
    required this.totalMs,
  });
  final String operationName;
  final int callCount;
  final double averageMs;
  final int minMs;
  final int maxMs;
  final int totalMs;

  @override
  String toString() => 'PerformanceMetrics($operationName: ${callCount}x, avg: ${averageMs.toStringAsFixed(1)}ms, min: ${minMs}ms, max: ${maxMs}ms)';
}

/// Widget that measures build performance
class PerformanceMeasuredWidget extends StatelessWidget {

  const PerformanceMeasuredWidget({
    required this.child, required this.operationName, super.key,
  });
  final Widget child;
  final String operationName;

  @override
  Widget build(BuildContext context) => PerformanceService.optimizeWidgetBuild(
      debugLabel: operationName,
      child: Builder(
        builder: (context) {
          final performanceService = PerformanceService();
          performanceService.startTimer('build_$operationName');
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            performanceService.stopTimer('build_$operationName');
          });
          
          return child;
        },
      ),
    );
}

/// Mixin for widgets that need performance monitoring
mixin PerformanceMixin<T extends StatefulWidget> on State<T> {
  final PerformanceService _performanceService = PerformanceService();
  
  @override
  void initState() {
    super.initState();
    _performanceService.startTimer('initState_${widget.runtimeType}');
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _performanceService.stopTimer('initState_${widget.runtimeType}');
  }
  
  @override
  void dispose() {
    _performanceService.stopTimer('lifecycle_${widget.runtimeType}');
    super.dispose();
  }
  
  /// Measure async operation performance
  Future<T> measureAsync<T>(String operationName, Future<T> Function() operation) => _performanceService.measureAsync(operationName, operation);
  
  /// Measure sync operation performance
  T measureSync<T>(String operationName, T Function() operation) => _performanceService.measureSync(operationName, operation);
  
  /// Report memory warning
  void reportMemoryWarning(String context) {
    _performanceService.reportMemoryWarning('${widget.runtimeType}: $context');
  }
}