import 'package:equatable/equatable.dart';

/// Represents a data operation that needs to be synced
class SyncOperation extends Equatable {
  const SyncOperation({
    required this.id,
    required this.type,
    required this.entityType,
    required this.entityId,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
    this.maxRetries = 3,
  });

  /// Create a sync operation for creating an entity
  factory SyncOperation.create({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> data,
  }) => SyncOperation(
      id: '${entityType}_create_${entityId}_${DateTime.now().millisecondsSinceEpoch}',
      type: SyncOperationType.create,
      entityType: entityType,
      entityId: entityId,
      data: data,
      timestamp: DateTime.now(),
    );

  /// Create a sync operation for updating an entity
  factory SyncOperation.update({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> data,
  }) => SyncOperation(
      id: '${entityType}_update_${entityId}_${DateTime.now().millisecondsSinceEpoch}',
      type: SyncOperationType.update,
      entityType: entityType,
      entityId: entityId,
      data: data,
      timestamp: DateTime.now(),
    );

  /// Create a sync operation for deleting an entity
  factory SyncOperation.delete({
    required String entityType,
    required String entityId,
  }) => SyncOperation(
      id: '${entityType}_delete_${entityId}_${DateTime.now().millisecondsSinceEpoch}',
      type: SyncOperationType.delete,
      entityType: entityType,
      entityId: entityId,
      data: const {},
      timestamp: DateTime.now(),
    );

  /// Create from JSON
  factory SyncOperation.fromJson(Map<String, dynamic> json) => SyncOperation(
      id: json['id'] as String,
      type: SyncOperationType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as String,
      data: Map<String, dynamic>.from(json['data'] as Map),
      timestamp: DateTime.parse(json['timestamp'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
      maxRetries: json['maxRetries'] as int? ?? 3,
    );

  final String id;
  final SyncOperationType type;
  final String entityType; // 'task', 'avatar', 'achievement', etc.
  final String entityId;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;
  final int maxRetries;

  /// Create a copy with updated retry count
  SyncOperation withRetry() => SyncOperation(
      id: id,
      type: type,
      entityType: entityType,
      entityId: entityId,
      data: data,
      timestamp: timestamp,
      retryCount: retryCount + 1,
      maxRetries: maxRetries,
    );

  /// Check if operation has exceeded max retries
  bool get hasExceededMaxRetries => retryCount >= maxRetries;

  /// Check if operation is ready for retry
  bool get isReadyForRetry {
    if (hasExceededMaxRetries) return false;
    
    // Exponential backoff: wait 2^retryCount minutes
    final backoffMinutes = (1 << retryCount).clamp(1, 60);
    final nextRetryTime = timestamp.add(Duration(minutes: backoffMinutes));
    
    return DateTime.now().isAfter(nextRetryTime);
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
      'id': id,
      'type': type.name,
      'entityType': entityType,
      'entityId': entityId,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'retryCount': retryCount,
      'maxRetries': maxRetries,
    };

  @override
  List<Object?> get props => [
        id,
        type,
        entityType,
        entityId,
        data,
        timestamp,
        retryCount,
        maxRetries,
      ];

  @override
  String toString() => 'SyncOperation(${type.name} $entityType:$entityId, '
           'retries: $retryCount/$maxRetries, '
           'timestamp: ${timestamp.toIso8601String()})';
}

/// Types of sync operations
enum SyncOperationType {
  create,
  update,
  delete,
}