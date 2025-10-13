import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/providers.dart';

class RepairTicketsScreen extends StatefulWidget {
  const RepairTicketsScreen({super.key});

  @override
  State<RepairTicketsScreen> createState() => _RepairTicketsScreenState();
}

class _RepairTicketsScreenState extends State<RepairTicketsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  RepairStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RepairTicketProvider>().loadTickets();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
          Expanded(child: _buildTicketsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTicketDialog(),
        icon: const Icon(Icons.add_task),
        label: const Text('New Ticket'),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Repair Tickets',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Consumer<RepairTicketProvider>(
                  builder: (context, provider, child) {
                    final activeCount = provider.tickets
                        .where((ticket) => ticket.status.isActive)
                        .length;
                    return Text(
                      '${provider.tickets.length} tickets • $activeCount active',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search tickets...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _statusFilter == null,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _statusFilter = null);
                      _loadTickets();
                    }
                  },
                ),
                const SizedBox(width: 8),
                ...RepairStatus.values.map(
                  (status) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(status.displayName),
                      selected: _statusFilter == status,
                      onSelected: (selected) {
                        setState(
                          () => _statusFilter = selected ? status : null,
                        );
                        _loadTickets();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _loadTickets();
  }

  void _loadTickets() {
    context.read<RepairTicketProvider>().loadTickets(
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      status: _statusFilter,
    );
  }

  Widget _buildTicketsList() {
    return Consumer<RepairTicketProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.tickets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty && _statusFilter == null
                      ? 'No repair tickets yet'
                      : 'No tickets found',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _searchQuery.isEmpty && _statusFilter == null
                      ? 'Create your first repair ticket to get started'
                      : 'Try adjusting your search or filter criteria',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (_searchQuery.isEmpty && _statusFilter == null) ...[
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _showAddTicketDialog(),
                    icon: const Icon(Icons.add_task),
                    label: const Text('New Ticket'),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.tickets.length,
          itemBuilder: (context, index) {
            final ticket = provider.tickets[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => showTicketDetailsDialog(context, ticket.id),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ticket #${ticket.id}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ticket.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ticket.description,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                _showEditTicketDialog(ticket);
                                break;
                              case 'delete':
                                _showDeleteTicketConfirmation(ticket);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Delete',
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildStatusChip(ticket.status),
                        const SizedBox(width: 8),
                        _buildPriorityChip(ticket.priority),
                        const Spacer(),
                        if (ticket.estimatedCompletion != null)
                          Text(
                            'Due: ${DateFormat('MMM dd').format(ticket.estimatedCompletion!)}',
                            style: TextStyle(
                              color: ticket.isOverdue
                                  ? const Color(0xFF757575)
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      runSpacing: 4,
                      children: [
                        if (ticket.createdBy != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 14,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getCreatorName(ticket.createdBy),
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM dd, yyyy').format(ticket.createdAt),
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        if (ticket.estimatedCost != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.attach_money,
                                size: 14,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '\$${ticket.estimatedCost!.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              ), // InkWell closing
            );
          },
        );
      },
    );
  }

  Widget _buildStatusChip(RepairStatus status) {
    Color color;
    switch (status) {
      case RepairStatus.pending:
        color = const Color(0xFF6B7280); // slate grey
        break;
      case RepairStatus.diagnosed:
        color = const Color(0xFF8B9DC3); // steel blue
        break;
      case RepairStatus.inProgress:
        color = const Color(0xFF9CA3AF); // cool grey
        break;
      case RepairStatus.waitingForParts:
        color = const Color(0xFF94A3B8); // slate blue
        break;
      case RepairStatus.waitingForCustomer:
        color = const Color(0xFF6B7280); // slate grey
        break;
      case RepairStatus.testing:
        color = const Color(0xFF8B9DC3); // steel blue
        break;
      case RepairStatus.completed:
        color = const Color(0xFF9CA3AF); // cool grey
        break;
      case RepairStatus.cancelled:
        color = const Color(0xFF757575); // medium grey
        break;
      case RepairStatus.onHold:
        color = const Color(0xFF757575); // medium grey
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPriorityChip(Priority priority) {
    Color color;
    switch (priority) {
      case Priority.low:
        color = const Color(0xFF6B7280); // slate grey
        break;
      case Priority.medium:
        color = const Color(0xFF8B9DC3); // steel blue
        break;
      case Priority.high:
        color = const Color(0xFF9CA3AF); // cool grey
        break;
      case Priority.urgent:
        color = const Color(0xFF94A3B8); // slate blue
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        priority.displayName,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getCreatorName(String? createdBy) {
    if (createdBy == null) return 'Unknown';
    
    // Try to get user from auth provider's current user first
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser?.id == createdBy) {
      return authProvider.currentUser!.fullName;
    }
    
    // If not current user, return ID (in a real app, you'd fetch from a UserProvider)
    // For now, just show the username/ID
    return 'User ${createdBy.substring(0, 8)}'; // Show first 8 chars of ID
  }

  void _showAddTicketDialog() {
    showDialog(
      context: context,
      builder: (context) => TicketFormDialog(
        onSave: (ticket) async {
          final success = await context
              .read<RepairTicketProvider>()
              .createTicket(ticket);
          if (success != null && mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ticket "${ticket.title}" created successfully'),
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            );
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Failed to create ticket'),
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            );
          }
        },
      ),
    );
  }

  void _showEditTicketDialog(RepairTicket ticket) {
    showDialog(
      context: context,
      builder: (context) => TicketFormDialog(
        ticket: ticket,
        onSave: (updatedTicket) async {
          final success = await context
              .read<RepairTicketProvider>()
              .updateTicket(updatedTicket);
          if (success && mounted) {
            Navigator.of(context).pop();
            
            // Check if ticket was just marked as completed
            final wasCompleted = ticket.status != RepairStatus.completed && 
                                updatedTicket.status == RepairStatus.completed;
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Ticket "${updatedTicket.title}" updated successfully',
                ),
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            );
            
            // Show feedback link dialog if ticket was just completed
            if (wasCompleted) {
              _showFeedbackLinkDialog(updatedTicket);
            }
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Failed to update ticket'),
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _showFeedbackLinkDialog(RepairTicket ticket) async {
    // Get customer information
    final customerProvider = context.read<CustomerProvider>();
    final customer = customerProvider.customers.firstWhere(
      (c) => c.id == ticket.customerId,
      orElse: () => Customer(
        id: '',
        firstName: '',
        lastName: '',
        email: '',
        phone: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    if (customer.id.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer not found for this ticket'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Get device information
    final deviceProvider = context.read<DeviceProvider>();
    Device? device;
    try {
      device = deviceProvider.devices.firstWhere(
        (d) => d.id == ticket.deviceId,
      );
    } catch (e) {
      device = null;
    }

    // Get technician name
    String? technicianName;
    if (ticket.technicianId != null) {
      final techProvider = context.read<TechnicianProvider>();
      final technician = techProvider.technicians.firstWhere(
        (t) => t.id == ticket.technicianId,
        orElse: () => Technician(
          id: '',
          firstName: '',
          lastName: '',
          email: '',
          phone: '',
          status: TechnicianStatus.inactive,
          skills: [],
          hourlyRate: 0,
          hireDate: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      if (technician.id.isNotEmpty) {
        technicianName = technician.fullName;
      }
    }

    // Build feedback form URL
    final baseUrl = 'https://lkq8fgjg-8080.eun1.devtunnels.ms/feedback_form.html?';
    final params = <String, String>{
      'ticket': ticket.id,
      'customer': customer.id,
      'name': customer.fullName,
      'email': customer.email,
      'phone': customer.phone,
      'date': DateFormat('MMMM dd, yyyy').format(ticket.createdAt),
      'technician': technicianName ?? '',
      'ticketTitle': ticket.title,
      'ticketStatus': ticket.status.displayName,
      'ticketPriority': ticket.priority.displayName,
      if (device != null) ...{
        'deviceBrand': device.brand,
        'deviceModel': device.model,
        'deviceType': device.type.displayName,
        if (device.serialNumber != null) 'deviceSerial': device.serialNumber!,
      },
    };
    
    final fullUrl = baseUrl + params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    // Create short URL
    String feedbackUrl = fullUrl;
    if (mounted) {
      final shortUrlProvider = context.read<ShortUrlProvider>();
      final shortUrl = await shortUrlProvider.createShortUrl(
        fullUrl: fullUrl,
        ticketId: ticket.id,
        customerId: customer.id,
        expiresAt: DateTime.now().add(const Duration(days: 90)),
      );

      if (shortUrl != null) {
        feedbackUrl = 'https://lkq8fgjg-8080.eun1.devtunnels.ms/s/${shortUrl.shortCode}';
      }
    }

    // Show dialog with feedback link
    if (mounted) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.link, color: Colors.blue),
              SizedBox(width: 8),
              Text('Feedback Link Generated'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ticket "${ticket.title}" is completed!',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Send this feedback link to ${customer.fullName}:',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: SelectableText(
                    feedbackUrl,
                    style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lightbulb, size: 20, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Copy this link and send it via email, SMS, or WhatsApp',
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: feedbackUrl));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Link copied to clipboard!'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy Link'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  void _showDeleteTicketConfirmation(RepairTicket ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Ticket'),
        content: Text(
          'Are you sure you want to delete ticket "${ticket.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final success = await context
                  .read<RepairTicketProvider>()
                  .deleteTicket(ticket.id);
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Ticket "${ticket.title}" deleted successfully'
                          : 'Failed to delete ticket',
                    ),
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class TicketFormDialog extends StatefulWidget {
  final RepairTicket? ticket;
  final Function(RepairTicket) onSave;

  const TicketFormDialog({super.key, this.ticket, required this.onSave});

  @override
  State<TicketFormDialog> createState() => _TicketFormDialogState();
}

class _TicketFormDialogState extends State<TicketFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _estimatedCostController;
  late RepairStatus _status;
  late Priority _priority;
  DateTime? _estimatedCompletion;
  String? _selectedCustomerId;
  String? _selectedDeviceId;
  String? _selectedTechnicianId;

  @override
  void initState() {
    super.initState();
    final ticket = widget.ticket;
    _titleController = TextEditingController(text: ticket?.title ?? '');
    _descriptionController = TextEditingController(
      text: ticket?.description ?? '',
    );
    _estimatedCostController = TextEditingController(
      text: ticket?.estimatedCost?.toString() ?? '',
    );
    _status = ticket?.status ?? RepairStatus.pending;
    _priority = ticket?.priority ?? Priority.medium;
    _estimatedCompletion = ticket?.estimatedCompletion;
    _selectedCustomerId = ticket?.customerId;
    _selectedDeviceId = ticket?.deviceId;
    _selectedTechnicianId = ticket?.technicianId;
    
    // Load devices and technicians after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedCustomerId != null) {
        // If editing, load devices for the selected customer
        context.read<DeviceProvider>().loadDevices(customerId: _selectedCustomerId);
      } else {
        // If creating new, load all devices
        context.read<DeviceProvider>().loadDevices();
      }
      // Load technicians for admin users
      context.read<TechnicianProvider>().loadTechnicians();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _estimatedCostController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.ticket == null ? 'New Repair Ticket' : 'Edit Ticket'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title*',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description*',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) =>
                      value?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                // Customer dropdown
                Consumer<CustomerProvider>(
                  builder: (context, customerProvider, _) {
                    final customers = customerProvider.customers;
                    return DropdownButtonFormField<String>(
                      initialValue: _selectedCustomerId,
                      decoration: const InputDecoration(
                        labelText: 'Customer*',
                        border: OutlineInputBorder(),
                      ),
                      items: customers.map((customer) {
                        return DropdownMenuItem(
                          value: customer.id,
                          child: Text('${customer.fullName} (${customer.email})'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCustomerId = value;
                          _selectedDeviceId = null; // Reset device when customer changes
                        });
                        // Load devices for the selected customer
                        if (value != null) {
                          context.read<DeviceProvider>().loadDevices(customerId: value);
                        }
                      },
                      validator: (value) => value == null ? 'Please select a customer' : null,
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Device dropdown
                Consumer<DeviceProvider>(
                  builder: (context, deviceProvider, _) {
                    final devices = deviceProvider.devices;
                    final hasCustomer = _selectedCustomerId != null;
                    final isLoading = deviceProvider.isLoading;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _selectedDeviceId,
                          decoration: InputDecoration(
                            labelText: 'Device*',
                            border: const OutlineInputBorder(),
                            enabled: hasCustomer && !isLoading,
                            helperText: !hasCustomer 
                                ? 'Select a customer first'
                                : devices.isEmpty 
                                    ? 'No devices found for this customer'
                                    : null,
                          ),
                          items: hasCustomer && devices.isNotEmpty
                              ? devices.map((device) {
                                  return DropdownMenuItem(
                                    value: device.id,
                                    child: Text('${device.type.displayName} - ${device.brand} ${device.model}'),
                                  );
                                }).toList()
                              : [
                                  const DropdownMenuItem(
                                    value: null,
                                    enabled: false,
                                    child: Text('No devices available'),
                                  ),
                                ],
                          onChanged: hasCustomer && devices.isNotEmpty
                              ? (value) => setState(() => _selectedDeviceId = value)
                              : null,
                          validator: (value) {
                            if (!hasCustomer) return 'Please select a customer';
                            if (devices.isEmpty) return 'Please add a device for this customer first';
                            if (value == null) return 'Please select a device';
                            return null;
                          },
                        ),
                        if (hasCustomer && devices.isEmpty && !isLoading) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => _showAddDeviceDialog(context),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Device'),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Technician assignment dropdown (Admin only)
                Consumer2<AuthProvider, TechnicianProvider>(
                  builder: (context, authProvider, technicianProvider, _) {
                    final isAdmin = authProvider.currentUser?.role == UserRole.admin;
                    
                    if (!isAdmin) {
                      return const SizedBox.shrink(); // Don't show for non-admin users
                    }
                    
                    final technicians = technicianProvider.technicians
                        .where((t) => t.status == TechnicianStatus.active)
                        .toList();
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _selectedTechnicianId,
                          decoration: const InputDecoration(
                            labelText: 'Assign to Technician',
                            border: OutlineInputBorder(),
                            helperText: 'Optional - Leave empty to auto-assign',
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('Auto-assign (Current User)'),
                            ),
                            ...technicians.map((technician) {
                              return DropdownMenuItem(
                                value: technician.id,
                                child: Text('${technician.fullName} - ${technician.status.displayName}'),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedTechnicianId = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<RepairStatus>(
                        value: _status,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: RepairStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status.displayName),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _status = value!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<Priority>(
                        value: _priority,
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                          border: OutlineInputBorder(),
                        ),
                        items: Priority.values.map((priority) {
                          return DropdownMenuItem(
                            value: priority,
                            child: Text(priority.displayName),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _priority = value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _estimatedCostController,
                        decoration: const InputDecoration(
                          labelText: 'Estimated Cost',
                          prefixText: '\$',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isNotEmpty == true) {
                            final cost = double.tryParse(value!);
                            if (cost == null || cost < 0) {
                              return 'Enter a valid amount';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate:
                                _estimatedCompletion ??
                                DateTime.now().add(const Duration(days: 7)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) {
                            setState(() => _estimatedCompletion = date);
                          }
                        },
                        child: Text(
                          _estimatedCompletion != null
                              ? DateFormat(
                                  'MMM dd, yyyy',
                                ).format(_estimatedCompletion!)
                              : 'Set Due Date',
                        ),
                      ),
                    ),
                  ],
                ),
                if (_estimatedCompletion != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Spacer(),
                      TextButton(
                        onPressed: () =>
                            setState(() => _estimatedCompletion = null),
                        child: const Text('Clear Date'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saveTicket,
          child: Text(widget.ticket == null ? 'Create' : 'Save'),
        ),
      ],
    );
  }

  Future<void> _showAddDeviceDialog(BuildContext context) async {
    if (_selectedCustomerId == null) return;

    final formKey = GlobalKey<FormState>();
    DeviceType selectedType = DeviceType.laptop;
    final brandController = TextEditingController();
    final modelController = TextEditingController();
    final serialController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Device'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<DeviceType>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Device Type*',
                    border: OutlineInputBorder(),
                  ),
                  items: DeviceType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) selectedType = value;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: brandController,
                  decoration: const InputDecoration(
                    labelText: 'Brand*',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: modelController,
                  decoration: const InputDecoration(
                    labelText: 'Model*',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: serialController,
                  decoration: const InputDecoration(
                    labelText: 'Serial Number',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final device = Device(
                id: '',
                customerId: _selectedCustomerId!,
                type: selectedType,
                brand: brandController.text.trim(),
                model: modelController.text.trim(),
                serialNumber: serialController.text.trim().isEmpty 
                    ? null 
                    : serialController.text.trim(),
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

              try {
                final deviceId = await context.read<DeviceProvider>().createDevice(device);
                if (deviceId != null && context.mounted) {
                  // Reload devices for the customer
                  await context.read<DeviceProvider>().loadDevices(
                    customerId: _selectedCustomerId,
                  );
                  if (context.mounted) {
                    Navigator.pop(dialogContext, true);
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error creating device: $e')),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    // Auto-select the new device if one was created
    if (result == true && mounted) {
      final devices = context.read<DeviceProvider>().devices;
      if (devices.isNotEmpty) {
        setState(() {
          _selectedDeviceId = devices.first.id;
        });
      }
    }
  }

  void _saveTicket() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    
    // Get current user ID from AuthProvider
    final currentUserId = context.read<AuthProvider>().currentUser?.id;
    
    // Check if status changed to completed
    final wasCompleted = widget.ticket?.status == RepairStatus.completed;
    final isNowCompleted = _status == RepairStatus.completed;
    final shouldSetActualCompletion = !wasCompleted && isNowCompleted;
    
    final ticket = RepairTicket(
      id: widget.ticket?.id ?? '',
      customerId: _selectedCustomerId ?? widget.ticket?.customerId ?? '',
      deviceId: _selectedDeviceId ?? widget.ticket?.deviceId ?? '',
      technicianId: _selectedTechnicianId ?? widget.ticket?.technicianId ?? currentUserId, // Use selected technician or auto-assign
      createdBy: widget.ticket?.createdBy ?? currentUserId, // Track who created the ticket
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      status: _status,
      priority: _priority,
      estimatedCost: _estimatedCostController.text.trim().isNotEmpty
          ? double.tryParse(_estimatedCostController.text.trim())
          : null,
      estimatedCompletion: _estimatedCompletion,
      actualCompletion: shouldSetActualCompletion 
          ? now 
          : widget.ticket?.actualCompletion, // Set completion time when status changes to completed
      createdAt: widget.ticket?.createdAt ?? now,
      updatedAt: now,
    );

    widget.onSave(ticket);
  }
}

// Ticket Details Dialog - Can be used from any screen
void showTicketDetailsDialog(BuildContext context, String ticketId) {
  showDialog(
    context: context,
    builder: (context) => TicketDetailsDialog(ticketId: ticketId),
  );
}

class TicketDetailsDialog extends StatelessWidget {
  final String ticketId;

  const TicketDetailsDialog({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Consumer5<RepairTicketProvider, CustomerProvider, DeviceProvider, TechnicianProvider, AuthProvider>(
          builder: (context, ticketProvider, customerProvider, deviceProvider, technicianProvider, authProvider, _) {
            final ticket = ticketProvider.tickets
                .where((t) => t.id == ticketId)
                .firstOrNull;

            if (ticket == null) {
              return const Padding(
                padding: EdgeInsets.all(40.0),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Ticket not found'),
                    ],
                  ),
                ),
              );
            }

            // Get related data
            final customer = customerProvider.customers
                .where((c) => c.id == ticket.customerId)
                .firstOrNull;
            final device = deviceProvider.devices
                .where((d) => d.id == ticket.deviceId)
                .firstOrNull;
            final technician = technicianProvider.technicians
                .where((t) => t.id == ticket.technicianId)
                .firstOrNull;

            // Find who created the ticket - check if it's the current user
            final creatorName = ticket.createdBy != null
                ? (authProvider.currentUser?.id == ticket.createdBy
                    ? authProvider.currentUser!.fullName
                    : 'User ${ticket.createdBy!.substring(0, 8)}')
                : 'Unknown';

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.confirmation_number,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ticket #${ticket.id}',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              ticket.title,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status and Priority
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(ticket.status),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                ticket.status.displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getPriorityColor(ticket.priority),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                ticket.priority.displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Description
                        _buildInfoSection(
                          'Description',
                          ticket.description,
                          Icons.description,
                        ),
                        const SizedBox(height: 16),
                        // Customer Info
                        if (customer != null)
                          _buildInfoSection(
                            'Customer',
                            '${customer.fullName}\n${customer.email}\n${customer.phone}',
                            Icons.person,
                          ),
                        const SizedBox(height: 16),
                        // Device Info
                        if (device != null)
                          _buildInfoSection(
                            'Device',
                            '${device.type.displayName} - ${device.brand} ${device.model}${device.serialNumber != null ? '\nS/N: ${device.serialNumber}' : ''}',
                            Icons.devices,
                          ),
                        const SizedBox(height: 16),
                        // Technician Info
                        if (technician != null)
                          _buildInfoSection(
                            'Assigned Technician',
                            '${technician.fullName}\n${technician.email}\n${technician.phone}',
                            Icons.engineering,
                          ),
                        const SizedBox(height: 16),
                        // Created By
                        if (ticket.createdBy != null)
                          _buildInfoSection(
                            'Created By',
                            creatorName,
                            Icons.person_add,
                          ),
                        const SizedBox(height: 16),
                        // Dates
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateInfo(
                                'Created',
                                ticket.createdAt,
                                Icons.calendar_today,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildDateInfo(
                                'Due Date',
                                ticket.estimatedCompletion,
                                Icons.event,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Cost
                        if (ticket.estimatedCost != null)
                          _buildInfoSection(
                            'Estimated Cost',
                            '\$${ticket.estimatedCost!.toStringAsFixed(2)}',
                            Icons.attach_money,
                          ),
                      ],
                    ),
                  ),
                ),
                // Footer Actions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                      const SizedBox(width: 8),
                      // Show Complete button only if ticket is not completed
                      if (ticket.status != RepairStatus.completed) ...[
                        FilledButton.icon(
                          onPressed: () async {
                            // Show confirmation dialog
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Complete Ticket'),
                                content: Text(
                                  'Mark ticket "${ticket.title}" as completed?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(dialogContext).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.of(dialogContext).pop(true),
                                    child: const Text('Complete'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true && context.mounted) {
                              // Update ticket status to completed
                              final now = DateTime.now();
                              final completedTicket = ticket.copyWith(
                                status: RepairStatus.completed,
                                actualCompletion: now,
                                updatedAt: now,
                              );

                              final success = await context
                                  .read<RepairTicketProvider>()
                                  .updateTicket(completedTicket);

                              if (success && context.mounted) {
                                // Close the details dialog
                                Navigator.of(context).pop();
                                
                                // Show success message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle, color: Colors.white),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Ticket "${ticket.title}" marked as completed!',
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );

                                // Show feedback link dialog
                                await _showFeedbackLinkDialogFromDetails(
                                  context,
                                  completedTicket,
                                  customerProvider,
                                  deviceProvider,
                                  technicianProvider,
                                );
                              } else if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to complete ticket'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Complete'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushNamed('/tickets');
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('View All Tickets'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            content,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildDateInfo(String label, DateTime? date, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          date != null
              ? DateFormat('MMM dd, yyyy').format(date)
              : 'Not set',
          style: TextStyle(
            fontSize: 13,
            color: date != null ? Colors.black87 : Colors.grey,
          ),
        ),
      ],
    );
  }

  Future<void> _showFeedbackLinkDialogFromDetails(
    BuildContext context,
    RepairTicket ticket,
    CustomerProvider customerProvider,
    DeviceProvider deviceProvider,
    TechnicianProvider technicianProvider,
  ) async {
    // Get customer information
    final customer = customerProvider.customers.firstWhere(
      (c) => c.id == ticket.customerId,
      orElse: () => Customer(
        id: '',
        firstName: '',
        lastName: '',
        email: '',
        phone: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    if (customer.id.isEmpty) return;

    // Get device information
    Device? device;
    try {
      device = deviceProvider.devices.firstWhere(
        (d) => d.id == ticket.deviceId,
      );
    } catch (e) {
      device = null;
    }

    // Get technician name
    String? technicianName;
    if (ticket.technicianId != null) {
      final technician = technicianProvider.technicians.firstWhere(
        (t) => t.id == ticket.technicianId,
        orElse: () => Technician(
          id: '',
          firstName: '',
          lastName: '',
          email: '',
          phone: '',
          status: TechnicianStatus.inactive,
          skills: [],
          hourlyRate: 0,
          hireDate: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      if (technician.id.isNotEmpty) {
        technicianName = technician.fullName;
      }
    }

    // Build feedback form URL
    final baseUrl = 'https://lkq8fgjg-8080.eun1.devtunnels.ms/feedback_form.html?';
    final params = <String, String>{
      'ticket': ticket.id,
      'customer': customer.id,
      'name': customer.fullName,
      'email': customer.email,
      'phone': customer.phone,
      'date': DateFormat('MMMM dd, yyyy').format(ticket.createdAt),
      'technician': technicianName ?? '',
      'ticketTitle': ticket.title,
      'ticketStatus': ticket.status.displayName,
      'ticketPriority': ticket.priority.displayName,
      if (device != null) ...{
        'deviceBrand': device.brand,
        'deviceModel': device.model,
        'deviceType': device.type.displayName,
        if (device.serialNumber != null) 'deviceSerial': device.serialNumber!,
      },
    };
    
    final fullUrl = baseUrl + params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    // Create short URL
    String feedbackUrl = fullUrl;
    if (context.mounted) {
      final shortUrlProvider = context.read<ShortUrlProvider>();
      final shortUrl = await shortUrlProvider.createShortUrl(
        fullUrl: fullUrl,
        ticketId: ticket.id,
        customerId: customer.id,
        expiresAt: DateTime.now().add(const Duration(days: 90)),
      );

      if (shortUrl != null) {
        feedbackUrl = 'https://lkq8fgjg-8080.eun1.devtunnels.ms/s/${shortUrl.shortCode}';
      }
    }

    // Show dialog with feedback link
    if (context.mounted) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.link, color: Colors.blue),
              SizedBox(width: 8),
              Text('Feedback Link Generated'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ticket "${ticket.title}" is completed!',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Send this feedback link to ${customer.fullName}:',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: SelectableText(
                    feedbackUrl,
                    style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lightbulb, size: 20, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Copy this link and send it via email, SMS, or WhatsApp',
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: feedbackUrl));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Link copied to clipboard!'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy Link'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  Color _getStatusColor(RepairStatus status) {
    switch (status) {
      case RepairStatus.pending:
        return Colors.orange;
      case RepairStatus.inProgress:
        return Colors.blue;
      case RepairStatus.diagnosed:
        return Colors.purple;
      case RepairStatus.waitingForParts:
        return Colors.amber;
      case RepairStatus.waitingForCustomer:
        return Colors.lightBlue;
      case RepairStatus.testing:
        return Colors.teal;
      case RepairStatus.completed:
        return Colors.green;
      case RepairStatus.cancelled:
        return Colors.red;
      case RepairStatus.onHold:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.low:
        return Colors.green;
      case Priority.medium:
        return Colors.orange;
      case Priority.high:
        return Colors.red;
      case Priority.urgent:
        return Colors.deepOrange;
    }
  }
}
