import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'auth_provider.dart';

class RepairTicketProvider extends ChangeNotifier {
  final RepairTicketRepository _repository = RepairTicketRepository();
  final ActivityService _activityService = ActivityService();
  AuthProvider? _authProvider;

  List<RepairTicket> _tickets = [];
  RepairTicket? _selectedTicket;
  bool _isLoading = false;
  String _searchQuery = '';
  RepairStatus? _statusFilter;

  List<RepairTicket> get tickets => _tickets;
  RepairTicket? get selectedTicket => _selectedTicket;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  RepairStatus? get statusFilter => _statusFilter;

  // Set auth provider for activity tracking
  void setAuthProvider(AuthProvider authProvider) {
    _authProvider = authProvider;
  }

  Future<void> loadTickets({
    String? searchQuery,
    RepairStatus? status,
    String? customerId,
    String? technicianId,
  }) async {
    _isLoading = true;
    _searchQuery = searchQuery ?? '';
    _statusFilter = status;
    notifyListeners();

    try {
      _tickets = await _repository.getAll(
        searchQuery: searchQuery,
        status: status,
        customerId: customerId,
        technicianId: technicianId,
      );
    } catch (e) {
      debugPrint('Error loading tickets: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTicket(String ticketId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _selectedTicket = await _repository.getById(ticketId);

      // Log view activity
      if (_selectedTicket != null && _authProvider?.currentUser != null) {
        await _activityService.logActivity(
          userId: _authProvider!.currentUser!.id,
          username: _authProvider!.currentUser!.username,
          userRole: _authProvider!.currentUser!.role,
          activityType: ActivityType.view,
          entityType: EntityType.ticket,
          entityId: _selectedTicket!.id,
          description: 'Repair ticket viewed: ${_selectedTicket!.title}',
          metadata: {
            'ticketId': _selectedTicket!.id,
            'customerId': _selectedTicket!.customerId,
          },
        );
      }
    } catch (e) {
      debugPrint('Error loading ticket: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> createTicket(RepairTicket ticket) async {
    try {
      final id = await _repository.create(ticket);

      // Log activity
      if (_authProvider?.currentUser != null) {
        await _activityService.logActivity(
          userId: _authProvider!.currentUser!.id,
          username: _authProvider!.currentUser!.username,
          userRole: _authProvider!.currentUser!.role,
          activityType: ActivityType.create,
          entityType: EntityType.ticket,
          entityId: id,
          description: 'Repair ticket created: ${ticket.title}',
          metadata: {
            'ticketId': id,
            'customerId': ticket.customerId,
            'status': ticket.status.name,
          },
        );
      }

      await loadTickets(searchQuery: _searchQuery, status: _statusFilter);
      return id;
    } catch (e) {
      debugPrint('Error creating ticket: $e');
      return null;
    }
  }

  Future<bool> updateTicket(RepairTicket ticket) async {
    try {
      await _repository.update(ticket);

      // Log activity
      if (_authProvider?.currentUser != null) {
        await _activityService.logActivity(
          userId: _authProvider!.currentUser!.id,
          username: _authProvider!.currentUser!.username,
          userRole: _authProvider!.currentUser!.role,
          activityType: ActivityType.update,
          entityType: EntityType.ticket,
          entityId: ticket.id,
          description: 'Repair ticket updated: ${ticket.title}',
          metadata: {
            'ticketId': ticket.id,
            'customerId': ticket.customerId,
            'status': ticket.status.name,
          },
        );
      }

      if (_selectedTicket?.id == ticket.id) {
        _selectedTicket = ticket;
      }
      await loadTickets(searchQuery: _searchQuery, status: _statusFilter);
      return true;
    } catch (e) {
      debugPrint('Error updating ticket: $e');
      return false;
    }
  }

  Future<bool> deleteTicket(String ticketId) async {
    try {
      // Get ticket info before deletion for logging
      final ticketToDelete = _tickets.firstWhere((t) => t.id == ticketId);

      await _repository.delete(ticketId);

      // Log activity
      if (_authProvider?.currentUser != null) {
        await _activityService.logActivity(
          userId: _authProvider!.currentUser!.id,
          username: _authProvider!.currentUser!.username,
          userRole: _authProvider!.currentUser!.role,
          activityType: ActivityType.delete,
          entityType: EntityType.ticket,
          entityId: ticketId,
          description: 'Repair ticket deleted: ${ticketToDelete.title}',
          metadata: {
            'ticketId': ticketId,
            'customerId': ticketToDelete.customerId,
          },
        );
      }

      _tickets.removeWhere((ticket) => ticket.id == ticketId);
      if (_selectedTicket?.id == ticketId) {
        _selectedTicket = null;
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting ticket: $e');
      return false;
    }
  }

  Future<List<RepairTicket>> getActiveTickets() async {
    try {
      return await _repository.getActiveTickets();
    } catch (e) {
      debugPrint('Error getting active tickets: $e');
      return [];
    }
  }

  Future<List<RepairTicket>> getOverdueTickets() async {
    try {
      return await _repository.getOverdueTickets();
    } catch (e) {
      debugPrint('Error getting overdue tickets: $e');
      return [];
    }
  }

  Future<Map<String, int>> getStatusCounts() async {
    try {
      return await _repository.getStatusCounts();
    } catch (e) {
      debugPrint('Error getting status counts: $e');
      return {};
    }
  }

  void clearSelection() {
    _selectedTicket = null;
    notifyListeners();
  }
}
