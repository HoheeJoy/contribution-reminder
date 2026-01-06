class AuditLog {
  final String? id;
  final String userId;
  final String action; // 'create', 'update', 'delete', 'status_change'
  final String entityType; // 'member', 'contribution', 'reminder'
  final String entityId;
  final String? oldValue;
  final String? newValue;
  final String? description;
  final DateTime timestamp;

  AuditLog({
    this.id,
    required this.userId,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.oldValue,
    this.newValue,
    this.description,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'old_value': oldValue,
      'new_value': newValue,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AuditLog.fromMap(Map<String, dynamic> map) {
    return AuditLog(
      id: map['id']?.toString(),
      userId: map['user_id'] ?? '',
      action: map['action'] ?? '',
      entityType: map['entity_type'] ?? '',
      entityId: map['entity_id'] ?? '',
      oldValue: map['old_value'],
      newValue: map['new_value'],
      description: map['description'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

