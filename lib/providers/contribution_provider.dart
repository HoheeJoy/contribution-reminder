import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import '../models/contribution_model.dart';
import '../utils/audit_logger.dart';

class ContributionProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  
  List<Contribution> _contributions = [];
  bool _isLoading = false;
  String? _memberId;
  String? _organizationId;

  List<Contribution> get contributions => _contributions;
  bool get isLoading => _isLoading;

  Future<void> loadContributions({String? memberId, String? organizationId}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _memberId = memberId;
      _organizationId = organizationId;
      
      if (memberId != null) {
        _contributions = await _db.getContributionsByMember(memberId);
      } else {
        _contributions = await _db.getAllContributions(organizationId: organizationId);
      }
      
      // Update status for each contribution
      _contributions = _contributions.map((c) {
        final newStatus = c.calculateStatus();
        if (newStatus != c.status) {
          return c.copyWith(status: newStatus);
        }
        return c;
      }).toList();
    } catch (e) {
      debugPrint('Error loading contributions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addContribution(Contribution contribution, {String? userId}) async {
    try {
      final contributionId = await _db.insertContribution(contribution);
      await loadContributions(memberId: _memberId, organizationId: _organizationId);
      
      // Log audit action
      if (userId != null) {
        await AuditLogger.logAction(
          userId: userId,
          action: 'create',
          entityType: 'contribution',
          entityId: contributionId,
          description: 'Created contribution: ₱${contribution.amount} for member ${contribution.memberId}',
        );
      }
      
      return true;
    } catch (e) {
      debugPrint('Error adding contribution: $e');
      return false;
    }
  }

  Future<bool> updateContribution(Contribution contribution, {String? userId, Contribution? oldContribution}) async {
    try {
      final oldValue = oldContribution != null ? '${oldContribution.status} - ₱${oldContribution.amount}' : null;
      final newValue = '${contribution.status} - ₱${contribution.amount}';
      
      await _db.updateContribution(contribution);
      await loadContributions(memberId: _memberId, organizationId: _organizationId);
      
      // Log audit action
      if (userId != null) {
        await AuditLogger.logAction(
          userId: userId,
          action: oldContribution?.status != contribution.status ? 'status_change' : 'update',
          entityType: 'contribution',
          entityId: contribution.id!,
          oldValue: oldValue,
          newValue: newValue,
          description: 'Updated contribution: ₱${contribution.amount}',
        );
      }
      
      return true;
    } catch (e) {
      debugPrint('Error updating contribution: $e');
      return false;
    }
  }

  Future<bool> deleteContribution(String id, {String? userId, double? amount}) async {
    try {
      await _db.deleteContribution(id);
      await loadContributions(memberId: _memberId, organizationId: _organizationId);
      
      // Log audit action
      if (userId != null) {
        await AuditLogger.logAction(
          userId: userId,
          action: 'delete',
          entityType: 'contribution',
          entityId: id,
          description: 'Deleted contribution: ₱${amount ?? 0}',
        );
      }
      
      return true;
    } catch (e) {
      debugPrint('Error deleting contribution: $e');
      return false;
    }
  }

  Future<double> getUnpaidBalance(String memberId) async {
    try {
      return await _db.getUnpaidBalance(memberId);
    } catch (e) {
      debugPrint('Error getting balance: $e');
      return 0.0;
    }
  }

  List<Contribution> filterByStatus(String status) {
    return _contributions.where((c) => c.status == status).toList();
  }

  List<Contribution> filterByDateRange(DateTime start, DateTime end) {
    return _contributions.where((c) {
      return c.dueDate.isAfter(start.subtract(const Duration(days: 1))) &&
          c.dueDate.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  double getTotalPaid() {
    return _contributions
        .where((c) => c.status == 'paid')
        .fold(0.0, (sum, c) => sum + c.amount);
  }

  double getTotalUnpaid() {
    return _contributions
        .where((c) => c.status != 'paid')
        .fold(0.0, (sum, c) => sum + c.amount);
  }
}

