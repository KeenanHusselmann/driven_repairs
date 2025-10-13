import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'database_service.dart';
import 'activity_service.dart';

class AuthenticationService {
  static final AuthenticationService _instance =
      AuthenticationService._internal();
  factory AuthenticationService() => _instance;
  AuthenticationService._internal();

  final DatabaseService _db = DatabaseService();
  final ActivityService _activityService = ActivityService();

  User? _currentUser;
  String? _currentSessionId;

  User? get currentUser => _currentUser;
  String? get sessionId => _currentSessionId;
  bool get isAuthenticated => _currentUser != null;

  // Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Initialize default admin user if no users exist
  Future<void> initializeDefaultUsers() async {
    try {
      final users = await _getAllUsers();
      if (users.isEmpty) {
        final now = DateTime.now();

        // Create default admin user
        final adminUser = User(
          id: 'admin-001',
          username: 'admin',
          email: 'admin@drivenrepairs.com',
          firstName: 'System',
          lastName: 'Administrator',
          role: UserRole.admin,
          status: UserStatus.active,
          passwordHash: _hashPassword('admin123'), // Default password
          department: 'IT',
          createdAt: now,
          updatedAt: now,
        );

        await _createUser(adminUser);

        // Create sample users for each role
        final sampleUsers = [
          User(
            id: 'tech-001',
            username: 'john.tech',
            email: 'john@drivenrepairs.com',
            firstName: 'John',
            lastName: 'Smith',
            role: UserRole.technician,
            status: UserStatus.active,
            passwordHash: _hashPassword('tech123'),
            department: 'Technical',
            createdAt: now,
            updatedAt: now,
            createdBy: adminUser.id,
          ),
          User(
            id: 'sales-001',
            username: 'sarah.sales',
            email: 'sarah@drivenrepairs.com',
            firstName: 'Sarah',
            lastName: 'Johnson',
            role: UserRole.sales,
            status: UserStatus.active,
            passwordHash: _hashPassword('sales123'),
            department: 'Sales',
            createdAt: now,
            updatedAt: now,
            createdBy: adminUser.id,
          ),
          User(
            id: 'acc-001',
            username: 'mike.acc',
            email: 'mike@drivenrepairs.com',
            firstName: 'Mike',
            lastName: 'Davis',
            role: UserRole.accountant,
            status: UserStatus.active,
            passwordHash: _hashPassword('acc123'),
            department: 'Finance',
            createdAt: now,
            updatedAt: now,
            createdBy: adminUser.id,
          ),
        ];

        for (final user in sampleUsers) {
          await _createUser(user);
        }

        debugPrint('Default users created successfully');
      }
    } catch (e) {
      debugPrint('Error initializing default users: $e');
    }
  }

  // Login user
  Future<User?> login(String username, String password) async {
    try {
      final passwordHash = _hashPassword(password);
      final db = await _db.database;

      final results = await db.query(
        'users',
        where: 'username = ? AND passwordHash = ? AND status = ?',
        whereArgs: [username, passwordHash, UserStatus.active.value],
      );

      if (results.isEmpty) {
        return null; // Invalid credentials
      }

      final user = User.fromMap(results.first);
      _currentUser = user;
      _currentSessionId = _generateSessionId();

      // Update last login time
      await db.update(
        'users',
        {'lastLoginAt': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [user.id],
      );

      // Log the login activity
      await _activityService.logActivity(
        userId: user.id,
        username: user.username,
        userRole: user.role,
        activityType: ActivityType.login,
        entityType: EntityType.system,
        description: 'User logged in successfully',
      );

      return user;
    } catch (e) {
      debugPrint('Login error: $e');
      return null;
    }
  }

  // Logout user
  Future<void> logout() async {
    if (_currentUser != null) {
      await _activityService.logActivity(
        userId: _currentUser!.id,
        username: _currentUser!.username,
        userRole: _currentUser!.role,
        activityType: ActivityType.logout,
        entityType: EntityType.system,
        description: 'User logged out',
      );
    }

    _currentUser = null;
    _currentSessionId = null;
  }

  // Check if current user has permission
  bool hasPermission(Permission permission) {
    return _currentUser?.hasPermission(permission) ?? false;
  }

  // Check if current user can access feature
  bool canAccessFeature(String feature) {
    return _currentUser?.canAccessFeature(feature) ?? false;
  }

  // Get all users (admin only)
  Future<List<User>> _getAllUsers() async {
    final db = await _db.database;
    final results = await db.query('users', orderBy: 'createdAt DESC');
    return results.map((map) => User.fromMap(map)).toList();
  }

  // Create user (internal method)
  Future<void> _createUser(User user) async {
    final db = await _db.database;
    await db.insert('users', user.toMap());
  }

  // Generate session ID
  String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final hash = sha256.convert(utf8.encode(timestamp));
    return hash.toString().substring(0, 16);
  }

  // Validate session (for future use with session management)
  bool isValidSession() {
    return _currentUser != null && _currentSessionId != null;
  }

  // Change password
  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    if (_currentUser == null) return false;

    try {
      final currentHash = _hashPassword(currentPassword);
      final db = await _db.database;

      // Verify current password
      final results = await db.query(
        'users',
        where: 'id = ? AND passwordHash = ?',
        whereArgs: [_currentUser!.id, currentHash],
      );

      if (results.isEmpty) return false;

      // Update password
      final newHash = _hashPassword(newPassword);
      await db.update(
        'users',
        {
          'passwordHash': newHash,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [_currentUser!.id],
      );

      await _activityService.logActivity(
        userId: _currentUser!.id,
        username: _currentUser!.username,
        userRole: _currentUser!.role,
        activityType: ActivityType.update,
        entityType: EntityType.user,
        entityId: _currentUser!.id,
        description: 'Password changed successfully',
      );

      return true;
    } catch (e) {
      debugPrint('Change password error: $e');
      return false;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile({
    required String userId,
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
  }) async {
    try {
      final db = await _db.database;
      final now = DateTime.now();

      await db.update(
        'users',
        {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'phone': phone,
          'updatedAt': now.millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [userId],
      );

      // Update current user if it's the same user
      if (_currentUser?.id == userId) {
        _currentUser = User(
          id: _currentUser!.id,
          username: _currentUser!.username,
          email: email,
          firstName: firstName,
          lastName: lastName,
          role: _currentUser!.role,
          status: _currentUser!.status,
          passwordHash: _currentUser!.passwordHash,
          profileImageUrl: _currentUser!.profileImageUrl,
          phone: phone,
          department: _currentUser!.department,
          createdAt: _currentUser!.createdAt,
          updatedAt: now,
          lastLoginAt: _currentUser!.lastLoginAt,
          createdBy: _currentUser!.createdBy,
        );
      }

      await _activityService.logActivity(
        userId: _currentUser?.id ?? userId,
        username: _currentUser?.username ?? 'system',
        userRole: _currentUser?.role ?? UserRole.admin,
        activityType: ActivityType.update,
        entityType: EntityType.user,
        entityId: userId,
        description: 'Profile updated: $firstName $lastName',
      );

      return true;
    } catch (e) {
      debugPrint('Update user profile error: $e');
      return false;
    }
  }
}
