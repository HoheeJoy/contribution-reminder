import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../services/database_service.dart';
import '../models/member_model.dart';

class AuthProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  
  Member? _currentMember;
  bool _isAuthenticated = false;
  String? _currentUserId;

  Member? get currentMember => _currentMember;
  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _currentUserId;
  bool get isAdmin => _currentMember?.role == 'admin';

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> login(String email, String password) async {
    try {
      const adminEmail = 'admin@gmail.com';
      const adminPassword = 'admin123';
      
      // Check if this is admin login attempt
      if (email.toLowerCase() == adminEmail && password == adminPassword) {
        // Try to get admin user from Firestore
        var user = await _db.getUserByEmail(adminEmail);
        
        // If admin doesn't exist in Firestore, create it
        if (user == null) {
          // First, check if admin member exists
          var adminMember = await _db.getMemberByEmail(adminEmail);
          String memberId;
          
          if (adminMember == null) {
            // Create admin member in Firestore
            final member = Member(
              name: 'Administrator',
              memberId: 'ADMIN',
              email: adminEmail,
              organizationId: 'default',
              joinDate: DateTime.now(),
              role: 'admin',
              isActive: true,
            );
            memberId = await _db.insertMember(member);
          } else {
            memberId = adminMember.id!;
          }
          
          // Create admin user account in Firestore
          final hashedPassword = _hashPassword(adminPassword);
          await _db.insertUser(
            email: adminEmail,
            passwordHash: hashedPassword,
            memberId: memberId,
            role: 'admin',
          );
          
          // Get the created user
          user = await _db.getUserByEmail(adminEmail);
        } else {
          // Admin exists, verify password
          final hashedPassword = _hashPassword(adminPassword);
          if (user['password_hash'] != hashedPassword) {
            return false; // Password mismatch
          }
        }
        
        if (user != null) {
          _currentUserId = user['id'];
          final memberId = user['member_id'];
          
          if (memberId != null) {
            _currentMember = await _db.getMemberById(memberId);
          }
          
          // If member doesn't exist, create it and update user record
          if (_currentMember == null) {
            final member = Member(
              name: 'Administrator',
              memberId: 'ADMIN',
              email: adminEmail,
              organizationId: 'default',
              joinDate: DateTime.now(),
              role: 'admin',
              isActive: true,
            );
            final newMemberId = await _db.insertMember(member);
            _currentMember = await _db.getMemberById(newMemberId);
            
            // Update user record with member ID
            await _db.updateUserMemberId(user['id'], newMemberId);
          }
          
          if (_currentMember == null) {
            return false;
          }
          
          _isAuthenticated = true;
          notifyListeners();
          return true;
        }
        
        return false;
      }

      // Regular user login from Firestore
      final user = await _db.getUserByEmail(email);
      if (user == null) {
        return false;
      }

      final hashedPassword = _hashPassword(password);
      if (user['password_hash'] != hashedPassword) {
        return false;
      }

      _currentUserId = user['id'];
      final memberId = user['member_id'];
      
      if (memberId != null) {
        _currentMember = await _db.getMemberById(memberId);
      } else {
        // Create a temporary member for users without member record
        _currentMember = Member(
          id: user['id'],
          name: email.split('@')[0],
          memberId: user['id'],
          email: email,
          organizationId: 'default',
          joinDate: DateTime.now(),
          role: user['role'] ?? 'member',
        );
      }

      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String idNumber,
    String? phone,
  }) async {
    try {
      // Check if email already exists
      final existingUser = await _db.getUserByEmail(email);
      if (existingUser != null) {
        return false;
      }

      // Check if member with same email or ID number already exists
      final existingMember = await _db.getMemberByEmail(email);
      if (existingMember != null) {
        return false;
      }

      // Check if ID number already exists
      final allMembers = await _db.getAllMembers();
      final idNumberExists = allMembers.any((m) => m.memberId == idNumber);
      if (idNumberExists) {
        return false;
      }

      // Create member (all users are registered as 'member' role)
      final member = Member(
        name: name,
        memberId: idNumber,
        email: email,
        phone: phone,
        organizationId: 'default',
        joinDate: DateTime.now(),
        role: 'member',
        isActive: true,
      );
      final memberIdCreated = await _db.insertMember(member);

      // Create user account
      final hashedPassword = _hashPassword(password);
      final userId = await _db.insertUser(
        email: email,
        passwordHash: hashedPassword,
        memberId: memberIdCreated,
        role: 'member',
      );

      // Automatically log in the user after registration
      _currentUserId = userId;
      _currentMember = await _db.getMemberById(memberIdCreated);
      _isAuthenticated = true;
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Registration error: $e');
      return false;
    }
  }

  void updateCurrentMember(Member member) {
    _currentMember = member;
    notifyListeners();
  }

  Future<void> logout() async {
    _currentMember = null;
    _isAuthenticated = false;
    _currentUserId = null;
    notifyListeners();
  }

  Future<void> loadCurrentUser(String userId) async {
    try {
      final user = await _db.getUserByEmail(userId);
      if (user != null) {
        _currentUserId = user['id'];
        final memberId = user['member_id'];
        if (memberId != null) {
          _currentMember = await _db.getMemberById(memberId);
        }
        _isAuthenticated = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Load user error: $e');
    }
  }
}

