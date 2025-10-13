import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'auth_provider.dart';

class CustomerProvider extends ChangeNotifier {
  final CustomerRepository _repository = CustomerRepository();
  final ActivityService _activityService = ActivityService();
  AuthProvider? _authProvider;

  List<Customer> _customers = [];
  Customer? _selectedCustomer;
  bool _isLoading = false;
  String _searchQuery = '';

  List<Customer> get customers => _customers;
  Customer? get selectedCustomer => _selectedCustomer;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  void setAuthProvider(AuthProvider authProvider) {
    _authProvider = authProvider;
  }

  Future<void> loadCustomers({String? searchQuery}) async {
    _isLoading = true;
    _searchQuery = searchQuery ?? '';
    notifyListeners();

    try {
      _customers = await _repository.getAll(searchQuery: searchQuery);
    } catch (e) {
      debugPrint('Error loading customers: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCustomer(String customerId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _selectedCustomer = await _repository.getById(customerId);

      // Log view activity
      if (_selectedCustomer != null && _authProvider?.currentUser != null) {
        await _activityService.logActivity(
          userId: _authProvider!.currentUser!.id,
          username: _authProvider!.currentUser!.username,
          userRole: _authProvider!.currentUser!.role,
          activityType: ActivityType.view,
          entityType: EntityType.customer,
          entityId: _selectedCustomer!.id,
          description: 'Customer viewed: ${_selectedCustomer!.fullName}',
          metadata: {
            'customerId': _selectedCustomer!.id,
            'customerName': _selectedCustomer!.fullName,
          },
        );
      }
    } catch (e) {
      debugPrint('Error loading customer: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> createCustomer(Customer customer) async {
    try {
      final id = await _repository.create(customer);

      // Log activity
      if (_authProvider?.currentUser != null) {
        await _activityService.logActivity(
          userId: _authProvider!.currentUser!.id,
          username: _authProvider!.currentUser!.username,
          userRole: _authProvider!.currentUser!.role,
          activityType: ActivityType.create,
          entityType: EntityType.customer,
          entityId: id,
          description: 'Customer created: ${customer.fullName}',
          metadata: {'customerId': id, 'customerName': customer.fullName},
        );
      }

      await loadCustomers(searchQuery: _searchQuery);
      return id;
    } catch (e, stackTrace) {
      debugPrint('Error creating customer: $e');
      debugPrint('Stack trace: $stackTrace');
      // Re-throw with more details for debugging
      throw Exception('Failed to create customer: $e');
    }
  }

  Future<bool> updateCustomer(Customer customer) async {
    try {
      await _repository.update(customer);

      // Log activity
      if (_authProvider?.currentUser != null) {
        await _activityService.logActivity(
          userId: _authProvider!.currentUser!.id,
          username: _authProvider!.currentUser!.username,
          userRole: _authProvider!.currentUser!.role,
          activityType: ActivityType.update,
          entityType: EntityType.customer,
          entityId: customer.id,
          description: 'Customer updated: ${customer.fullName}',
          metadata: {
            'customerId': customer.id,
            'customerName': customer.fullName,
          },
        );
      }

      if (_selectedCustomer?.id == customer.id) {
        _selectedCustomer = customer;
      }
      await loadCustomers(searchQuery: _searchQuery);
      return true;
    } catch (e) {
      debugPrint('Error updating customer: $e');
      return false;
    }
  }

  Future<bool> deleteCustomer(String customerId) async {
    try {
      // Get customer info before deletion for logging
      final customerToDelete = _customers.firstWhere((c) => c.id == customerId);

      await _repository.delete(customerId);

      // Log activity
      if (_authProvider?.currentUser != null) {
        await _activityService.logActivity(
          userId: _authProvider!.currentUser!.id,
          username: _authProvider!.currentUser!.username,
          userRole: _authProvider!.currentUser!.role,
          activityType: ActivityType.delete,
          entityType: EntityType.customer,
          entityId: customerId,
          description: 'Customer deleted: ${customerToDelete.fullName}',
          metadata: {
            'customerId': customerId,
            'customerName': customerToDelete.fullName,
          },
        );
      }

      _customers.removeWhere((customer) => customer.id == customerId);
      if (_selectedCustomer?.id == customerId) {
        _selectedCustomer = null;
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting customer: $e');
      return false;
    }
  }

  void clearSelection() {
    _selectedCustomer = null;
    notifyListeners();
  }

  Future<int> getCustomerCount() async {
    try {
      return await _repository.getCount(searchQuery: _searchQuery);
    } catch (e) {
      debugPrint('Error getting customer count: $e');
      return 0;
    }
  }
}
