import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/member_model.dart';
import '../models/contribution_model.dart';
import '../models/reminder_model.dart';
import '../models/organization_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Member CRUD operations
  Future<String> insertMember(Member member) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final memberData = member.copyWith(id: id).toMap();
    // Convert DateTime to ISO string for Firestore
    memberData['join_date'] = member.joinDate.toIso8601String();
    memberData['is_active'] = member.isActive;
    await _firestore.collection('members').doc(id).set(memberData);
    return id;
  }

  Future<List<Member>> getAllMembers({String? organizationId}) async {
    Query query = _firestore.collection('members').orderBy('name');
    
    if (organizationId != null) {
      query = query.where('organization_id', isEqualTo: organizationId);
    }
    
    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return Member.fromMap(data);
    }).toList();
  }

  Future<Member?> getMemberById(String id) async {
    final doc = await _firestore.collection('members').doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    data['id'] = doc.id;
    return Member.fromMap(data);
  }

  Future<Member?> getMemberByEmail(String email) async {
    final snapshot = await _firestore
        .collection('members')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return Member.fromMap(data);
  }

  Future<void> updateMember(Member member) async {
    if (member.id == null) return;
    final memberData = member.toMap();
    memberData['join_date'] = member.joinDate.toIso8601String();
    memberData['is_active'] = member.isActive;
    await _firestore.collection('members').doc(member.id).update(memberData);
  }

  Future<void> deleteMember(String id) async {
    await _firestore.collection('members').doc(id).delete();
  }

  // Contribution CRUD operations
  Future<String> insertContribution(Contribution contribution) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final contributionData = contribution.copyWith(id: id).toMap();
    contributionData['due_date'] = contribution.dueDate.toIso8601String();
    contributionData['paid_date'] = contribution.paidDate?.toIso8601String();
    contributionData['created_at'] = contribution.createdAt.toIso8601String();
    await _firestore.collection('contributions').doc(id).set(contributionData);
    return id;
  }

  Future<List<Contribution>> getContributionsByMember(String memberId) async {
    final snapshot = await _firestore
        .collection('contributions')
        .where('member_id', isEqualTo: memberId)
        .orderBy('due_date', descending: true)
        .get();
    
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return Contribution.fromMap(data);
    }).toList();
  }

  Future<List<Contribution>> getAllContributions({String? organizationId}) async {
    Query query = _firestore.collection('contributions').orderBy('due_date', descending: true);
    
    if (organizationId != null) {
      // Get member IDs for this organization first
      final membersSnapshot = await _firestore
          .collection('members')
          .where('organization_id', isEqualTo: organizationId)
          .get();
      
      final memberIds = membersSnapshot.docs.map((doc) => doc.id).toList();
      
      if (memberIds.isEmpty) return [];
      
      // Firestore 'in' query limit is 10, so we need to batch if needed
      if (memberIds.length <= 10) {
        query = query.where('member_id', whereIn: memberIds);
      } else {
        // For more than 10 members, get all and filter
        final allContributions = await query.get();
        final filtered = allContributions.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return memberIds.contains(data['member_id']);
        });
        return filtered.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return Contribution.fromMap(data);
        }).toList();
      }
    }
    
    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return Contribution.fromMap(data);
    }).toList();
  }

  Future<Contribution?> getContributionById(String id) async {
    final doc = await _firestore.collection('contributions').doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    data['id'] = doc.id;
    return Contribution.fromMap(data);
  }

  Future<void> updateContribution(Contribution contribution) async {
    if (contribution.id == null) return;
    final contributionData = contribution.toMap();
    contributionData['due_date'] = contribution.dueDate.toIso8601String();
    contributionData['paid_date'] = contribution.paidDate?.toIso8601String();
    contributionData['created_at'] = contribution.createdAt.toIso8601String();
    await _firestore.collection('contributions').doc(contribution.id).update(contributionData);
  }

  Future<void> deleteContribution(String id) async {
    await _firestore.collection('contributions').doc(id).delete();
  }

  Future<double> getUnpaidBalance(String memberId) async {
    final snapshot = await _firestore
        .collection('contributions')
        .where('member_id', isEqualTo: memberId)
        .where('status', whereIn: ['unpaid', 'overdue'])
        .get();
    
    double total = 0.0;
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data['amount'] as num).toDouble();
    }
    return total;
  }

  // Reminder CRUD operations
  Future<String> insertReminder(Reminder reminder) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final reminderData = reminder.copyWith(id: id).toMap();
    reminderData['sent_at'] = reminder.sentAt.toIso8601String();
    reminderData['is_read'] = reminder.isRead;
    await _firestore.collection('reminders').doc(id).set(reminderData);
    return id;
  }

  Future<List<Reminder>> getRemindersByMember(String memberId) async {
    final snapshot = await _firestore
        .collection('reminders')
        .where('member_id', isEqualTo: memberId)
        .orderBy('sent_at', descending: true)
        .get();
    
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return Reminder.fromMap(data);
    }).toList();
  }

  Future<List<Reminder>> getAllReminders() async {
    final snapshot = await _firestore
        .collection('reminders')
        .orderBy('sent_at', descending: true)
        .get();
    
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return Reminder.fromMap(data);
    }).toList();
  }

  Future<void> updateReminder(Reminder reminder) async {
    if (reminder.id == null) return;
    final reminderData = reminder.toMap();
    reminderData['sent_at'] = reminder.sentAt.toIso8601String();
    reminderData['is_read'] = reminder.isRead;
    await _firestore.collection('reminders').doc(reminder.id).update(reminderData);
  }

  Future<void> markReminderAsRead(String id) async {
    await _firestore.collection('reminders').doc(id).update({'is_read': true});
  }

  // Organization CRUD operations
  Future<String> insertOrganization(Organization organization) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final orgData = organization.copyWith(id: id).toMap();
    await _firestore.collection('organizations').doc(id).set(orgData);
    return id;
  }

  Future<Organization?> getOrganizationById(String id) async {
    final doc = await _firestore.collection('organizations').doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    data['id'] = doc.id;
    return Organization.fromMap(data);
  }

  Future<List<Organization>> getAllOrganizations() async {
    final snapshot = await _firestore.collection('organizations').get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return Organization.fromMap(data);
    }).toList();
  }

  Future<void> updateOrganization(Organization organization) async {
    if (organization.id == null) return;
    await _firestore.collection('organizations').doc(organization.id).update(organization.toMap());
  }

  // User authentication operations
  Future<String> insertUser({
    required String email,
    required String passwordHash,
    String? memberId,
    required String role,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await _firestore.collection('users').doc(id).set({
      'email': email,
      'password_hash': passwordHash,
      'member_id': memberId,
      'role': role,
    });
    return id;
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final snapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return data;
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<void> updateUserMemberId(String userId, String memberId) async {
    await _firestore.collection('users').doc(userId).update({
      'member_id': memberId,
    });
  }

  // Audit log operations
  Future<String> insertAuditLog({
    required String userId,
    required String action,
    required String entityType,
    required String entityId,
    String? oldValue,
    String? newValue,
    String? description,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await _firestore.collection('audit_logs').doc(id).set({
      'user_id': userId,
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'old_value': oldValue,
      'new_value': newValue,
      'description': description,
      'timestamp': DateTime.now().toIso8601String(),
    });
    return id;
  }

  Future<List<Map<String, dynamic>>> getAuditLogs({
    String? userId,
    String? entityType,
    int? limit,
  }) async {
    Query query = _firestore.collection('audit_logs').orderBy('timestamp', descending: true);
    
    if (userId != null) {
      query = query.where('user_id', isEqualTo: userId);
    }
    
    if (entityType != null) {
      query = query.where('entity_type', isEqualTo: entityType);
    }
    
    if (limit != null) {
      query = query.limit(limit);
    }
    
    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }
}
