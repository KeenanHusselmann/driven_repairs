import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/authentication_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthenticationService _authService = AuthenticationService();

  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  UserRole? get currentUserRole => _currentUser?.role;

  // Initialize and check for existing session
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Initialize default users if needed
      await _authService.initializeDefaultUsers();

      // Check for existing valid session
      if (_authService.isValidSession()) {
        _currentUser = _authService.currentUser;
      }

      _error = null;
    } catch (e) {
      _error = 'Initialization failed: $e';
      debugPrint('Auth initialization error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login user
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.login(username, password);
      if (user != null) {
        _currentUser = user;
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = 'Invalid username or password';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Login failed: $e';
      debugPrint('Login error: $e');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout user
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      _currentUser = null;
      _error = null;
    } catch (e) {
      _error = 'Logout failed: $e';
      debugPrint('Logout error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check if user has specific permission
  bool hasPermission(Permission permission) {
    return _authService.hasPermission(permission);
  }

  // Check if user can access specific feature
  bool canAccessFeature(String feature) {
    return _authService.canAccessFeature(feature);
  }

  // Check if user has specific role
  bool hasRole(UserRole role) {
    return _currentUser?.role == role;
  }

  // Check if user is admin
  bool get isAdmin => hasRole(UserRole.admin);

  // Check if user is technician
  bool get isTechnician => hasRole(UserRole.technician);

  // Check if user is sales
  bool get isSales => hasRole(UserRole.sales);

  // Check if user is accountant
  bool get isAccountant => hasRole(UserRole.accountant);

  // Change password
  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _authService.changePassword(
        currentPassword,
        newPassword,
      );
      if (!success) {
        _error =
            'Failed to change password. Please check your current password.';
      }
      return success;
    } catch (e) {
      _error = 'Password change failed: $e';
      debugPrint('Password change error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update current user info (after profile updates)
  void updateCurrentUser(User updatedUser) {
    if (_currentUser?.id == updatedUser.id) {
      _currentUser = updatedUser;
      notifyListeners();
    }
  }

  // Update user profile
  Future<bool> updateUserProfile({
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _authService.updateUserProfile(
        userId: _currentUser!.id,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
      );

      if (success) {
        // The AuthenticationService already updates _currentUser
        // Just refresh from the service
        _currentUser = _authService.currentUser;
        notifyListeners();
      } else {
        _error = 'Failed to update profile';
      }

      return success;
    } catch (e) {
      _error = 'Profile update failed: $e';
      debugPrint('Profile update error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get user display name
  String get userDisplayName => _currentUser?.fullName ?? 'Unknown User';

  // Get user initials
  String get userInitials => _currentUser?.initials ?? '??';

  // Check if current session is valid
  bool get isSessionValid => _authService.isValidSession();

  // Get permissions for current user
  List<Permission> get currentUserPermissions =>
      _currentUser?.role.permissions ?? [];

  // Navigation helpers
  bool canViewUsers() => hasPermission(Permission.viewUsers);
  bool canManageUsers() =>
      hasPermission(Permission.createUsers) ||
      hasPermission(Permission.editUsers);
  bool canViewReports() => hasPermission(Permission.viewReports);
  bool canViewSales() =>
      hasPermission(Permission.viewSalesReports) ||
      currentUser?.role == UserRole.admin;
  bool canViewSettings() => hasPermission(Permission.viewSettings);
  bool canManageSettings() => hasPermission(Permission.editSettings);
  bool canViewAuditLogs() => hasPermission(Permission.viewAuditLogs);
}
