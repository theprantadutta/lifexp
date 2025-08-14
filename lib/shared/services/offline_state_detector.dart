import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Service for detecting and monitoring offline/online state
class OfflineStateDetector {
  
  OfflineStateDetector({Connectivity? connectivity}) 
      : _connectivity = connectivity ?? Connectivity() {
    _initialize();
  }
  static const String _testUrl = 'https://www.google.com';
  static const Duration _testTimeout = Duration(seconds: 5);
  static const Duration _recheckInterval = Duration(seconds: 30);
  
  final Connectivity _connectivity;
  final StreamController<ConnectionState> _stateController = StreamController<ConnectionState>.broadcast();
  
  ConnectionState _currentState = ConnectionState.unknown;
  Timer? _recheckTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// Current connection state
  ConnectionState get currentState => _currentState;
  
  /// Stream of connection state changes
  Stream<ConnectionState> get stateStream => _stateController.stream;
  
  /// Whether the device is currently online
  bool get isOnline => _currentState == ConnectionState.online;
  
  /// Whether the device is currently offline
  bool get isOffline => _currentState == ConnectionState.offline;

  /// Initialize the detector
  Future<void> _initialize() async {
    // Check initial connectivity
    await _checkConnectivity();
    
    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
      onError: (error) {
        print('OfflineStateDetector: Connectivity stream error: $error');
      },
    );
    
    // Start periodic recheck timer
    _startPeriodicRecheck();
  }

  /// Handle connectivity changes
  Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    print('OfflineStateDetector: Connectivity changed to $results');
    
    if (results.every((result) => result == ConnectivityResult.none)) {
      _updateState(ConnectionState.offline);
    } else {
      // Even if we have connectivity, verify internet access
      await _verifyInternetAccess();
    }
  }

  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      
      if (connectivityResults.every((result) => result == ConnectivityResult.none)) {
        _updateState(ConnectionState.offline);
      } else {
        await _verifyInternetAccess();
      }
    } catch (e) {
      print('OfflineStateDetector: Error checking connectivity: $e');
      _updateState(ConnectionState.offline);
    }
  }

  /// Verify actual internet access by making a test request
  Future<void> _verifyInternetAccess() async {
    try {
      _updateState(ConnectionState.checking);
      
      final client = HttpClient();
      client.connectionTimeout = _testTimeout;
      
      final request = await client.getUrl(Uri.parse(_testUrl));
      final response = await request.close().timeout(_testTimeout);
      
      if (response.statusCode == 200) {
        _updateState(ConnectionState.online);
      } else {
        _updateState(ConnectionState.offline);
      }
      
      client.close();
    } catch (e) {
      print('OfflineStateDetector: Internet verification failed: $e');
      _updateState(ConnectionState.offline);
    }
  }

  /// Update connection state and notify listeners
  void _updateState(ConnectionState newState) {
    if (_currentState != newState) {
      final previousState = _currentState;
      _currentState = newState;
      
      print('OfflineStateDetector: State changed from $previousState to $newState');
      
      if (!_stateController.isClosed) {
        _stateController.add(newState);
      }
    }
  }

  /// Start periodic connectivity recheck
  void _startPeriodicRecheck() {
    _recheckTimer = Timer.periodic(_recheckInterval, (_) {
      if (_currentState == ConnectionState.offline) {
        // Only recheck if we think we're offline
        _checkConnectivity();
      }
    });
  }

  /// Force a connectivity check
  Future<void> forceCheck() async {
    await _checkConnectivity();
  }

  /// Get connection quality information
  Future<ConnectionQuality> getConnectionQuality() async {
    if (_currentState != ConnectionState.online) {
      return ConnectionQuality.none;
    }

    try {
      final stopwatch = Stopwatch()..start();
      
      final client = HttpClient();
      client.connectionTimeout = _testTimeout;
      
      final request = await client.getUrl(Uri.parse(_testUrl));
      final response = await request.close().timeout(_testTimeout);
      
      stopwatch.stop();
      client.close();
      
      if (response.statusCode == 200) {
        final responseTime = stopwatch.elapsedMilliseconds;
        
        if (responseTime < 500) {
          return ConnectionQuality.excellent;
        } else if (responseTime < 1000) {
          return ConnectionQuality.good;
        } else if (responseTime < 2000) {
          return ConnectionQuality.fair;
        } else {
          return ConnectionQuality.poor;
        }
      }
      
      return ConnectionQuality.poor;
    } catch (e) {
      return ConnectionQuality.none;
    }
  }

  /// Get detailed connection information
  Future<ConnectionInfo> getConnectionInfo() async {
    final connectivityResults = await _connectivity.checkConnectivity();
    final quality = await getConnectionQuality();
    
    // Use the first non-none result, or none if all are none
    final primaryResult = connectivityResults.firstWhere(
      (result) => result != ConnectivityResult.none,
      orElse: () => ConnectivityResult.none,
    );
    
    return ConnectionInfo(
      state: _currentState,
      type: _mapConnectivityResult(primaryResult),
      quality: quality,
      lastChecked: DateTime.now(),
    );
  }

  /// Map ConnectivityResult to ConnectionType
  ConnectionType _mapConnectivityResult(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return ConnectionType.wifi;
      case ConnectivityResult.mobile:
        return ConnectionType.mobile;
      case ConnectivityResult.ethernet:
        return ConnectionType.ethernet;
      case ConnectivityResult.bluetooth:
        return ConnectionType.bluetooth;
      case ConnectivityResult.vpn:
        return ConnectionType.vpn;
      case ConnectivityResult.other:
        return ConnectionType.other;
      case ConnectivityResult.none:
        return ConnectionType.none;
    }
  }

  /// Dispose resources
  void dispose() {
    _recheckTimer?.cancel();
    _connectivitySubscription?.cancel();
    _stateController.close();
  }
}

/// Connection state enum
enum ConnectionState {
  unknown,
  checking,
  online,
  offline,
}

/// Connection type enum
enum ConnectionType {
  none,
  wifi,
  mobile,
  ethernet,
  bluetooth,
  vpn,
  other,
}

/// Connection quality enum
enum ConnectionQuality {
  none,
  poor,
  fair,
  good,
  excellent,
}

/// Detailed connection information
class ConnectionInfo {

  const ConnectionInfo({
    required this.state,
    required this.type,
    required this.quality,
    required this.lastChecked,
  });
  final ConnectionState state;
  final ConnectionType type;
  final ConnectionQuality quality;
  final DateTime lastChecked;

  /// Whether the connection is usable for sync operations
  bool get isUsableForSync => state == ConnectionState.online && 
           quality != ConnectionQuality.none &&
           quality != ConnectionQuality.poor;

  /// Whether the connection is good enough for heavy operations
  bool get isGoodForHeavyOperations => state == ConnectionState.online && 
           (quality == ConnectionQuality.good || quality == ConnectionQuality.excellent);

  @override
  String toString() => 'ConnectionInfo(state: $state, type: $type, quality: $quality, lastChecked: $lastChecked)';
}

/// Mixin for widgets that need connection state awareness
mixin ConnectionAwareMixin<T extends StatefulWidget> on State<T> {
  late OfflineStateDetector _detector;
  ConnectionState _connectionState = ConnectionState.unknown;
  StreamSubscription<ConnectionState>? _stateSubscription;
  
  @override
  void initState() {
    super.initState();
    _detector = OfflineStateDetector();
    _connectionState = _detector.currentState;
    
    _stateSubscription = _detector.stateStream.listen((state) {
      if (mounted && _connectionState != state) {
        setState(() {
          _connectionState = state;
        });
        onConnectionStateChanged(state);
      }
    });
  }
  
  @override
  void dispose() {
    _stateSubscription?.cancel();
    _detector.dispose();
    super.dispose();
  }
  
  /// Called when connection state changes
  void onConnectionStateChanged(ConnectionState state) {}
  
  /// Current connection state
  ConnectionState get connectionState => _connectionState;
  
  /// Whether currently online
  bool get isOnline => _connectionState == ConnectionState.online;
  
  /// Whether currently offline
  bool get isOffline => _connectionState == ConnectionState.offline;
  
  /// Force check connection
  Future<void> checkConnection() => _detector.forceCheck();
  
  /// Get connection quality
  Future<ConnectionQuality> getConnectionQuality() => _detector.getConnectionQuality();
}