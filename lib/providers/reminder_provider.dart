import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import '../models/reminder_model.dart';
import '../models/contribution_model.dart';
import '../models/member_model.dart';
import '../utils/notification_helper.dart';

class ReminderProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  
  List<Reminder> _reminders = [];
  bool _isLoading = false;
  String? _memberId;

  List<Reminder> get reminders => _reminders;
  bool get isLoading => _isLoading;
  
  int get unreadCount => _reminders.where((r) => !r.isRead).length;

  Future<void> loadReminders({String? memberId}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _memberId = memberId;
      if (memberId != null) {
        _reminders = await _db.getRemindersByMember(memberId);
      } else {
        _reminders = await _db.getAllReminders();
      }
    } catch (e) {
      debugPrint('Error loading reminders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendReminder({
    required Member member,
    required Contribution contribution,
    required String type,
  }) async {
    try {
      final message = _generateReminderMessage(member, contribution, type);
      
      final reminder = Reminder(
        memberId: member.id!,
        contributionId: contribution.id!,
        type: type,
        sentAt: DateTime.now(),
        message: message,
      );
      
      await _db.insertReminder(reminder);
      
      // Send local notification
      await NotificationHelper.showNotification(
        title: 'Contribution Reminder',
        body: message,
      );
      
      await loadReminders(memberId: _memberId);
      return true;
    } catch (e) {
      debugPrint('Error sending reminder: $e');
      return false;
    }
  }

  Future<bool> markAsRead(String reminderId) async {
    try {
      await _db.markReminderAsRead(reminderId);
      await loadReminders(memberId: _memberId);
      return true;
    } catch (e) {
      debugPrint('Error marking reminder as read: $e');
      return false;
    }
  }

  Future<void> checkAndSendReminders({
    required List<Member> members,
    required List<Contribution> contributions,
    int daysBeforeDue = 3,
  }) async {
    final now = DateTime.now();
    
    for (final contribution in contributions) {
      if (contribution.status == 'paid') continue;
      
      final member = members.firstWhere(
        (m) => m.id == contribution.memberId,
        orElse: () => members.first,
      );
      
      final daysUntilDue = contribution.dueDate.difference(now).inDays;
      
      // Check if due soon reminder should be sent
      if (daysUntilDue <= daysBeforeDue && daysUntilDue >= 0) {
        // Check if reminder already sent
        final existingReminders = _reminders.where((r) =>
          r.contributionId == contribution.id && r.type == 'due_soon'
        );
        
        if (existingReminders.isEmpty) {
          await sendReminder(
            member: member,
            contribution: contribution,
            type: 'due_soon',
          );
        }
      }
      
      // Check if overdue reminder should be sent
      if (contribution.dueDate.isBefore(now) && contribution.status != 'paid') {
        final existingReminders = _reminders.where((r) =>
          r.contributionId == contribution.id && r.type == 'overdue'
        );
        
        if (existingReminders.isEmpty) {
          await sendReminder(
            member: member,
            contribution: contribution,
            type: 'overdue',
          );
        }
      }
    }
  }

  String _generateReminderMessage(Member member, Contribution contribution, String type) {
    final daysUntilDue = contribution.dueDate.difference(DateTime.now()).inDays;
    
    if (type == 'due_soon') {
      return 'Hi ${member.name}, your contribution of ${contribution.amount} is due in $daysUntilDue days (${contribution.dueDate.toString().split(' ')[0]}).';
    } else if (type == 'overdue') {
      final daysOverdue = DateTime.now().difference(contribution.dueDate).inDays;
      return 'Hi ${member.name}, your contribution of ${contribution.amount} is overdue by $daysOverdue days. Please make payment as soon as possible.';
    }
    
    return 'Reminder: Contribution payment due';
  }

  List<Reminder> getUpcomingReminders() {
    return _reminders.where((r) => r.type == 'due_soon' && !r.isRead).toList();
  }

  List<Reminder> getOverdueReminders() {
    return _reminders.where((r) => r.type == 'overdue' && !r.isRead).toList();
  }
}

