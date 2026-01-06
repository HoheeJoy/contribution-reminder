import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import '../models/organization_model.dart';

class OrganizationProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  
  Organization? _currentOrganization;
  bool _isLoading = false;

  Organization? get currentOrganization => _currentOrganization;
  bool get isLoading => _isLoading;

  Future<void> loadOrganization(String organizationId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _currentOrganization = await _db.getOrganizationById(organizationId);
      if (_currentOrganization == null) {
        // Create default organization if none exists
        _currentOrganization = Organization(
          name: 'Default Organization',
          currency: 'USD',
        );
        final id = await _db.insertOrganization(_currentOrganization!);
        _currentOrganization = _currentOrganization!.copyWith(id: id);
      }
    } catch (e) {
      debugPrint('Error loading organization: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateOrganization(Organization organization) async {
    try {
      await _db.updateOrganization(organization);
      _currentOrganization = organization;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating organization: $e');
      return false;
    }
  }

  Future<bool> createOrganization(Organization organization) async {
    try {
      final id = await _db.insertOrganization(organization);
      _currentOrganization = organization.copyWith(id: id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error creating organization: $e');
      return false;
    }
  }
}

