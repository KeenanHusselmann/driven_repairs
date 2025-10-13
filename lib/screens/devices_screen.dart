import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final TextEditingController _searchController = TextEditingController();
  DeviceType? _selectedDeviceType;
  String _selectedWarrantyStatus = 'All';
  String? _selectedCustomerFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeviceProvider>().loadDevices();
      context.read<CustomerProvider>().loadCustomers();
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
      appBar: AppBar(title: const Text('Device Management')),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (!authProvider.hasPermission(Permission.viewDevices)) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Access Denied',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'You do not have permission to view devices.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Search and Filter Bar
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search devices...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _performSearch();
                                },
                              )
                            : null,
                      ),
                      onChanged: (_) => _performSearch(),
                    ),
                    const SizedBox(height: 16),
                    // Filter Row
                    Row(
                      children: [
                        Expanded(
                          child: Consumer<CustomerProvider>(
                            builder: (context, customerProvider, _) {
                              return DropdownButtonFormField<String?>(
                                initialValue: _selectedCustomerFilter,
                                decoration: const InputDecoration(
                                  labelText: 'Customer',
                                  border: OutlineInputBorder(),
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('All Customers'),
                                  ),
                                  ...customerProvider.customers.map((customer) {
                                    return DropdownMenuItem(
                                      value: customer.id,
                                      child: Text(customer.fullName),
                                    );
                                  }),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCustomerFilter = value;
                                  });
                                  _performSearch();
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<DeviceType?>(
                            initialValue: _selectedDeviceType,
                            decoration: const InputDecoration(
                              labelText: 'Device Type',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('All Types'),
                              ),
                              ...DeviceType.values.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(type.displayName),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedDeviceType = value;
                              });
                              _performSearch();
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedWarrantyStatus,
                            decoration: const InputDecoration(
                              labelText: 'Warranty Status',
                              border: OutlineInputBorder(),
                            ),
                            items: ['All', 'Under Warranty', 'Expired'].map((
                              status,
                            ) {
                              return DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedWarrantyStatus = value!;
                              });
                              _performSearch();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Devices List
              Expanded(
                child: Consumer<DeviceProvider>(
                  builder: (context, deviceProvider, _) {
                    if (deviceProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final devices = _getFilteredDevices(deviceProvider.devices);

                    if (devices.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.devices_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No devices found',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 18,
                              ),
                            ),
                            if (_searchController.text.isNotEmpty ||
                                _selectedCustomerFilter != null ||
                                _selectedDeviceType != null ||
                                _selectedWarrantyStatus != 'All') ...[
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _clearFilters,
                                child: const Text('Clear filters'),
                              ),
                            ],
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        return _buildDeviceCard(device, authProvider);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.hasPermission(Permission.createDevices)) {
            return FloatingActionButton.extended(
              onPressed: () => _showAddDeviceDialog(),
              icon: const Icon(Icons.add_circle),
              label: const Text('Add Device'),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildDeviceCard(Device device, AuthProvider authProvider) {
    final warrantyColor = const Color(0xFF757575); // Neutral grey for warranty status

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getDeviceTypeColor(device.type),
          child: Icon(_getDeviceTypeIcon(device.type), color: Colors.white),
        ),
        title: Text(
          '${device.brand} ${device.model}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Consumer<CustomerProvider>(
          builder: (context, customerProvider, _) {
            final customer = customerProvider.customers
                .where((c) => c.id == device.customerId)
                .firstOrNull;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (customer != null)
                  Text(
                    'Owner: ${customer.fullName}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                Text('Type: ${device.type.displayName}'),
                if (device.serialNumber?.isNotEmpty == true)
                  Text('S/N: ${device.serialNumber}'),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: warrantyColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        device.isUnderWarranty
                            ? 'Under Warranty'
                            : 'Warranty Expired',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (device.purchaseDate != null)
                      Text(
                        'Purchased: ${device.purchaseDate!.year}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
        trailing: authProvider.hasPermission(Permission.editDevices)
            ? PopupMenuButton<String>(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        const Text('Delete'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showEditDeviceDialog(device);
                      break;
                    case 'delete':
                      _showDeleteDeviceDialog(device);
                      break;
                  }
                },
              )
            : null,
        onTap: () => _showDeviceDetails(device),
      ),
    );
  }

  Color _getDeviceTypeColor(DeviceType type) {
    // Use neutral grey for all device types
    return const Color(0xFF757575);
  }

  IconData _getDeviceTypeIcon(DeviceType type) {
    switch (type) {
      case DeviceType.laptop:
        return Icons.laptop;
      case DeviceType.desktop:
        return Icons.computer;
      case DeviceType.tablet:
        return Icons.tablet;
      case DeviceType.smartphone:
        return Icons.phone_android;
      case DeviceType.server:
        return Icons.dns;
      case DeviceType.printer:
        return Icons.print;
      case DeviceType.monitor:
        return Icons.monitor;
      case DeviceType.accessory:
        return Icons.cable;
      case DeviceType.other:
        return Icons.device_unknown;
    }
  }

  List<Device> _getFilteredDevices(List<Device> devices) {
    var filtered = devices;

    // Filter by customer
    if (_selectedCustomerFilter != null) {
      filtered = filtered.where((device) {
        return device.customerId == _selectedCustomerFilter;
      }).toList();
    }

    // Filter by search term
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = filtered.where((device) {
        return device.brand.toLowerCase().contains(searchTerm) ||
            device.model.toLowerCase().contains(searchTerm) ||
            (device.serialNumber?.toLowerCase().contains(searchTerm) ??
                false) ||
            (device.notes?.toLowerCase().contains(searchTerm) ?? false);
      }).toList();
    }

    // Filter by device type
    if (_selectedDeviceType != null) {
      filtered = filtered.where((device) {
        return device.type == _selectedDeviceType;
      }).toList();
    }

    // Filter by warranty status
    if (_selectedWarrantyStatus != 'All') {
      filtered = filtered.where((device) {
        if (_selectedWarrantyStatus == 'Under Warranty') {
          return device.isUnderWarranty;
        } else if (_selectedWarrantyStatus == 'Expired') {
          return !device.isUnderWarranty;
        }
        return true;
      }).toList();
    }

    return filtered;
  }

  void _performSearch() {
    setState(() {
      // Trigger rebuild with new filter criteria
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCustomerFilter = null;
      _selectedDeviceType = null;
      _selectedWarrantyStatus = 'All';
    });
  }

  void _showAddDeviceDialog() {
    _showDeviceDialog(null);
  }

  void _showEditDeviceDialog(Device device) {
    _showDeviceDialog(device);
  }

  void _showDeviceDialog(Device? device) {
    showDialog(
      context: context,
      builder: (context) => DeviceDialog(device: device),
    );
  }

  void _showDeleteDeviceDialog(Device device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Device'),
        content: Text(
          'Are you sure you want to delete ${device.brand} ${device.model}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await context.read<DeviceProvider>().deleteDevice(device.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Device deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting device: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDeviceDetails(Device device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${device.brand} ${device.model}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Type', device.type.displayName),
              _buildDetailRow('Brand', device.brand),
              _buildDetailRow('Model', device.model),
              if (device.serialNumber?.isNotEmpty == true)
                _buildDetailRow('Serial Number', device.serialNumber!),
              _buildDetailRow(
                'Warranty Status',
                device.isUnderWarranty ? 'Under Warranty' : 'Expired',
              ),
              if (device.purchaseDate != null)
                _buildDetailRow(
                  'Purchase Date',
                  '${device.purchaseDate!.day}/${device.purchaseDate!.month}/${device.purchaseDate!.year}',
                ),
              if (device.warrantyExpiry != null)
                _buildDetailRow(
                  'Warranty Expires',
                  '${device.warrantyExpiry!.day}/${device.warrantyExpiry!.month}/${device.warrantyExpiry!.year}',
                ),
              if (device.operatingSystem?.isNotEmpty == true)
                _buildDetailRow('Operating System', device.operatingSystem!),
              if (device.specifications?.isNotEmpty == true)
                _buildDetailRow('Specifications', device.specifications!),
              if (device.notes?.isNotEmpty == true)
                _buildDetailRow('Notes', device.notes!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class DeviceDialog extends StatefulWidget {
  final Device? device;

  const DeviceDialog({super.key, this.device});

  @override
  State<DeviceDialog> createState() => _DeviceDialogState();
}

class _DeviceDialogState extends State<DeviceDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _brandController;
  late TextEditingController _modelController;
  late TextEditingController _serialNumberController;
  late TextEditingController _operatingSystemController;
  late TextEditingController _specificationsController;
  late TextEditingController _notesController;
  DeviceType _selectedDeviceType = DeviceType.laptop;
  DateTime? _purchaseDate;
  DateTime? _warrantyExpiry;
  String? _selectedCustomerId;

  @override
  void initState() {
    super.initState();
    _brandController = TextEditingController(text: widget.device?.brand ?? '');
    _modelController = TextEditingController(text: widget.device?.model ?? '');
    _serialNumberController = TextEditingController(
      text: widget.device?.serialNumber ?? '',
    );
    _operatingSystemController = TextEditingController(
      text: widget.device?.operatingSystem ?? '',
    );
    _specificationsController = TextEditingController(
      text: widget.device?.specifications ?? '',
    );
    _notesController = TextEditingController(text: widget.device?.notes ?? '');
    _selectedDeviceType = widget.device?.type ?? DeviceType.laptop;
    _purchaseDate = widget.device?.purchaseDate;
    _warrantyExpiry = widget.device?.warrantyExpiry;
    _selectedCustomerId = widget.device?.customerId;
    
    // Load customers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomers();
    });
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _serialNumberController.dispose();
    _operatingSystemController.dispose();
    _specificationsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.device == null ? 'Add Device' : 'Edit Device'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Customer Dropdown
                Consumer<CustomerProvider>(
                  builder: (context, customerProvider, _) {
                    final customers = customerProvider.customers;
                    return DropdownButtonFormField<String>(
                      value: _selectedCustomerId,
                      decoration: const InputDecoration(
                        labelText: 'Customer *',
                        border: OutlineInputBorder(),
                        helperText: 'Select the owner of this device',
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
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a customer';
                        }
                        return null;
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<DeviceType>(
                  value: _selectedDeviceType,
                  decoration: const InputDecoration(
                    labelText: 'Device Type *',
                    border: OutlineInputBorder(),
                  ),
                  items: DeviceType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDeviceType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _brandController,
                        decoration: const InputDecoration(
                          labelText: 'Brand *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a brand';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _modelController,
                        decoration: const InputDecoration(
                          labelText: 'Model *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a model';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _serialNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Serial Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _operatingSystemController,
                  decoration: const InputDecoration(
                    labelText: 'Operating System',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context, true),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Purchase Date',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            _purchaseDate != null
                                ? '${_purchaseDate!.day}/${_purchaseDate!.month}/${_purchaseDate!.year}'
                                : 'Select date',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context, false),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Warranty Expires',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            _warrantyExpiry != null
                                ? '${_warrantyExpiry!.day}/${_warrantyExpiry!.month}/${_warrantyExpiry!.year}'
                                : 'Select date',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _specificationsController,
                  decoration: const InputDecoration(
                    labelText: 'Specifications',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
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
          onPressed: _saveDevice,
          child: Text(widget.device == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, bool isPurchaseDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isPurchaseDate
          ? (_purchaseDate ?? DateTime.now())
          : (_warrantyExpiry ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isPurchaseDate) {
          _purchaseDate = picked;
        } else {
          _warrantyExpiry = picked;
        }
      });
    }
  }

  void _saveDevice() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final device = Device(
        id: widget.device?.id ?? '',
        customerId: _selectedCustomerId ?? '',
        type: _selectedDeviceType,
        brand: _brandController.text,
        model: _modelController.text,
        serialNumber: _serialNumberController.text.isEmpty
            ? null
            : _serialNumberController.text,
        operatingSystem: _operatingSystemController.text.isEmpty
            ? null
            : _operatingSystemController.text,
        specifications: _specificationsController.text.isEmpty
            ? null
            : _specificationsController.text,
        purchaseDate: _purchaseDate,
        warrantyExpiry: _warrantyExpiry,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        createdAt: widget.device?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.device == null) {
        await context.read<DeviceProvider>().createDevice(device);
      } else {
        await context.read<DeviceProvider>().updateDevice(device);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.device == null
                  ? 'Device added successfully'
                  : 'Device updated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving device: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
