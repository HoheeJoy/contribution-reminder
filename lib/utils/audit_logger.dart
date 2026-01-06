import 'package:flutter/foundation.dart';
import '../services/database_service.dart';

class AuditLogger {
  static final DatabaseService _db = DatabaseService();

  static Future<void> logAction({
    required String userId,
    required String action,
    required String entityType,
    required String entityId,
    String? oldValue,
    String? newValue,
    String? description,
  }) async {
    try {
      await _db.insertAuditLog(
        userId: userId,
        action: action,
        entityType: entityType,
        entityId: entityId,
        oldValue: oldValue,
        newValue: newValue,
        description: description,
      );
    } catch (e) {
      // Silently fail audit logging to not break main functionality
      debugPrint('Audit log error: $e');
    }
  }
}

