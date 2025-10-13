import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../screens/customers_screen.dart';

// Placeholder screens for sections not yet fully implemented

class CustomerDetailScreen extends StatefulWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomers();
      context.read<DeviceProvider>().loadDevices();
      context.read<RepairTicketProvider>().loadTickets();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<CustomerProvider, DeviceProvider, RepairTicketProvider>(
      builder: (context, customerProvider, deviceProvider, ticketProvider, _) {
        final customer = customerProvider.customers.firstWhere(
          (c) => c.id == widget.customerId,
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
          return Scaffold(
            appBar: AppBar(title: const Text('Customer Not Found')),
            body: const Center(child: Text('Customer not found')),
          );
        }

        final customerDevices = deviceProvider.devices
            .where((d) => d.customerId == widget.customerId)
            .toList();

        final customerTickets = ticketProvider.tickets
            .where((t) => t.customerId == widget.customerId)
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Customer Details'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditCustomerDialog(customer),
                tooltip: 'Edit Customer',
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _showDeleteConfirmation(customer),
                tooltip: 'Delete Customer',
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCustomerHeader(customer),
                _buildInfoSection(customer),
                _buildDevicesSection(customerDevices),
                _buildTicketsSection(customerTickets),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomerHeader(Customer customer) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              customer.firstName.isNotEmpty
                  ? customer.firstName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 32,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.fullName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Customer since ${DateFormat('MMMM dd, yyyy').format(customer.createdAt)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(Customer customer) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Contact Information',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditCustomerDialog(customer),
                    tooltip: 'Edit',
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.email, 'Email', customer.email),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.phone, 'Phone', customer.phone),
              if (customer.address != null) ...[
                const SizedBox(height: 12),
                _buildInfoRow(Icons.home, 'Address', _formatAddress(customer)),
              ],
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.update,
                'Last Updated',
                DateFormat('MMMM dd, yyyy at h:mm a').format(customer.updatedAt),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDevicesSection(List<Device> devices) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Devices (${devices.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.go('/devices'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Device'),
                  ),
                ],
              ),
              const Divider(),
              if (devices.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No devices registered',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: devices.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.devices,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        device.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(device.type.displayName),
                          if (device.serialNumber != null)
                            Text('S/N: ${device.serialNumber}'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 16),
                        onPressed: () => context.go('/devices/${device.id}'),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketsSection(List<RepairTicket> tickets) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Repair Tickets (${tickets.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.go('/tickets'),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Ticket'),
                  ),
                ],
              ),
              const Divider(),
              if (tickets.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No repair tickets',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tickets.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final ticket = tickets[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.confirmation_number,
                        color: _getStatusColor(ticket.status),
                      ),
                      title: Text(
                        ticket.title,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ticket.description),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(ticket.status)
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  ticket.status.toString().split('.').last,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _getStatusColor(ticket.status),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('MMM dd, yyyy').format(ticket.createdAt),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 16),
                        onPressed: () => context.go('/tickets/${ticket.id}'),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(RepairStatus status) {
    switch (status) {
      case RepairStatus.pending:
        return Colors.orange;
      case RepairStatus.inProgress:
        return Colors.blue;
      case RepairStatus.completed:
        return Colors.green;
      case RepairStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatAddress(Customer customer) {
    final parts = <String>[];
    if (customer.address != null) parts.add(customer.address!);
    if (customer.city != null) parts.add(customer.city!);
    if (customer.state != null) parts.add(customer.state!);
    if (customer.zipCode != null) parts.add(customer.zipCode!);
    return parts.join(', ');
  }

  void _showEditCustomerDialog(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => CustomerFormDialog(
        customer: customer,
        onSave: (updatedCustomer) async {
          try {
            final success = await context
                .read<CustomerProvider>()
                .updateCustomer(updatedCustomer);
            if (success && mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Customer ${updatedCustomer.fullName} updated successfully',
                  ),
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error updating customer: $e'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showDeleteConfirmation(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text(
          'Are you sure you want to delete ${customer.fullName}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                final success = await context
                    .read<CustomerProvider>()
                    .deleteCustomer(customer.id);
                if (success && mounted) {
                  Navigator.of(context).pop();
                  context.go('/customers');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Customer ${customer.fullName} deleted successfully',
                      ),
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting customer: $e'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// DevicesScreen is now implemented in devices_screen.dart

class DeviceDetailScreen extends StatelessWidget {
  final String deviceId;

  const DeviceDetailScreen({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Device Details')),
      body: Center(child: Text('Device ID: $deviceId')),
    );
  }
}

class RepairTicketDetailScreen extends StatelessWidget {
  final String ticketId;

  const RepairTicketDetailScreen({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ticket Details')),
      body: Center(child: Text('Ticket ID: $ticketId')),
    );
  }
}

// TechniciansScreen is now implemented in technicians_screen.dart

class TechnicianDetailScreen extends StatelessWidget {
  final String technicianId;

  const TechnicianDetailScreen({super.key, required this.technicianId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Technician Details')),
      body: Center(child: Text('Technician ID: $technicianId')),
    );
  }
}

// PartsScreen is now implemented in parts_screen.dart

// ReportsScreen will be replaced with AnalyticsScreen
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(child: Text('Reports Screen - Coming Soon')),
    );
  }
}
