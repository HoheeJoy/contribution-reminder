import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import '../models/member_model.dart';
import '../utils/audit_logger.dart';

class MemberProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  
  List<Member> _members = [];
  bool _isLoading = false;
  String? _organizationId;

  List<Member> get members => _members;
  bool get isLoading => _isLoading;

  Future<void> loadMembers({String? organizationId}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _organizationId = organizationId;
      _members = await _db.getAllMembers(organizationId: organizationId);
    } catch (e) {
      debugPrint('Error loading members: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addMember(Member member, {String? userId}) async {
    try {
      final memberId = await _db.insertMember(member);
      await loadMembers(organizationId: _organizationId);
      
      // Log audit action
      if (userId != null) {
        await AuditLogger.logAction(
          userId: userId,
          action: 'create',
          entityType: 'member',
          entityId: memberId,
          description: 'Created member: ${member.name}',
        );
      }
      
      return true;
    } catch (e) {
      debugPrint('Error adding member: $e');
      return false;
    }
  }

  Future<bool> updateMember(Member member, {String? userId, Member? oldMember}) async {
    try {
      final oldValue = oldMember != null ? '${oldMember.name} (${oldMember.isActive ? "Active" : "Inactive"})' : null;
      final newValue = '${member.name} (${member.isActive ? "Active" : "Inactive"})';
      
      await _db.updateMember(member);
      await loadMembers(organizationId: _organizationId);
      
      // Log audit action
      if (userId != null) {
        await AuditLogger.logAction(
          userId: userId,
          action: 'update',
          entityType: 'member',
          entityId: member.id!,
          oldValue: oldValue,
          newValue: newValue,
          description: 'Updated member: ${member.name}',
        );
      }
      
      return true;
    } catch (e) {
      debugPrint('Error updating member: $e');
      return false;
    }
  }

  Future<bool> deleteMember(String id, {String? userId, String? memberName}) async {
    try {
      await _db.deleteMember(id);
      await loadMembers(organizationId: _organizationId);
      
      // Log audit action
      if (userId != null) {
        await AuditLogger.logAction(
          userId: userId,
          action: 'delete',
          entityType: 'member',
          entityId: id,
          description: 'Deleted member: ${memberName ?? id}',
        );
      }
      
      return true;
    } catch (e) {
      debugPrint('Error deleting member: $e');
      return false;
    }
  }

  Member? getMemberById(String id) {
    try {
      return _members.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Member> searchMembers(String query) {
    if (query.isEmpty) return _members;
    final lowerQuery = query.toLowerCase();
    return _members.where((member) {
      return member.name.toLowerCase().contains(lowerQuery) ||
          member.memberId.toLowerCase().contains(lowerQuery) ||
          member.email.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  List<Member> filterMembersByStatus(String status) {
    // This would need contribution data to determine status
    // For now, return all members
    return _members;
  }
}

