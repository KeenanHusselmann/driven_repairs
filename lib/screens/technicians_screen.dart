import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';

class TechniciansScreen extends StatefulWidget {
  const TechniciansScreen({super.key});

  @override
  State<TechniciansScreen> createState() => _TechniciansScreenState();
}

class _TechniciansScreenState extends State<TechniciansScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedSkill = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TechnicianProvider>().loadTechnicians();
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
      appBar: AppBar(
        title: const Text('Technicians'),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              if (authProvider.hasPermission(Permission.createUsers)) {
                return IconButton(
                  icon: const Icon(Icons.person_add),
                  onPressed: () => _showAddTechnicianDialog(),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (!authProvider.hasPermission(Permission.viewUsers)) {
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
                    'You do not have permission to view technicians.',
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
                        hintText: 'Search technicians...',
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
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedSkill,
                            decoration: const InputDecoration(
                              labelText: 'Skill Filter',
                              border: OutlineInputBorder(),
                            ),
                            items:
                                [
                                  'All',
                                  'Hardware Repair',
                                  'Software Troubleshooting',
                                  'Networking',
                                  'Data Recovery',
                                  'Mobile Devices',
                                ].map((skill) {
                                  return DropdownMenuItem(
                                    value: skill,
                                    child: Text(skill),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedSkill = value!;
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
              // Technicians List
              Expanded(
                child: Consumer<TechnicianProvider>(
                  builder: (context, technicianProvider, _) {
                    if (technicianProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final technicians = _getFilteredTechnicians(
                      technicianProvider.technicians,
                    );

                    if (technicians.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.engineering_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No technicians found',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 18,
                              ),
                            ),
                            if (_searchController.text.isNotEmpty ||
                                _selectedSkill != 'All') ...[
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
                      itemCount: technicians.length,
                      itemBuilder: (context, index) {
                        final technician = technicians[index];
                        return _buildTechnicianCard(technician, authProvider);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTechnicianCard(
    Technician technician,
    AuthProvider authProvider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF757575), // Neutral grey
          child: Text(
            '${technician.firstName[0]}${technician.lastName[0]}'.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          technician.fullName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (technician.email.isNotEmpty) Text('Email: ${technician.email}'),
            if (technician.phone.isNotEmpty) Text('Phone: ${technician.phone}'),
            if (technician.skills.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: technician.skills.take(3).map((skill) {
                  return Chip(
                    label: Text(skill),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    labelStyle: const TextStyle(fontSize: 10),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
        trailing: authProvider.hasPermission(Permission.editUsers)
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
                      _showEditTechnicianDialog(technician);
                      break;
                    case 'delete':
                      _showDeleteTechnicianDialog(technician);
                      break;
                  }
                },
              )
            : null,
        onTap: () => _showTechnicianDetails(technician),
      ),
    );
  }

  List<Technician> _getFilteredTechnicians(List<Technician> technicians) {
    var filtered = technicians;

    // Filter by search term
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = filtered.where((technician) {
        return technician.fullName.toLowerCase().contains(searchTerm) ||
            technician.email.toLowerCase().contains(searchTerm) ||
            technician.phone.toLowerCase().contains(searchTerm) ||
            technician.skills.any(
              (skill) => skill.toLowerCase().contains(searchTerm),
            );
      }).toList();
    }

    // Filter by skill
    if (_selectedSkill != 'All') {
      filtered = filtered.where((technician) {
        return technician.skills.contains(_selectedSkill);
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
      _selectedSkill = 'All';
    });
  }

  void _showAddTechnicianDialog() {
    _showTechnicianDialog(null);
  }

  void _showEditTechnicianDialog(Technician technician) {
    _showTechnicianDialog(technician);
  }

  void _showTechnicianDialog(Technician? technician) {
    showDialog(
      context: context,
      builder: (context) => TechnicianDialog(technician: technician),
    );
  }

  void _showDeleteTechnicianDialog(Technician technician) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Technician'),
        content: Text(
          'Are you sure you want to delete ${technician.fullName}?',
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
                await context.read<TechnicianProvider>().deleteTechnician(
                  technician.id,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Technician deleted successfully'),
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting technician: $e'),
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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

  void _showTechnicianDetails(Technician technician) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(technician.fullName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Name', technician.fullName),
              _buildDetailRow('Email', technician.email),
              _buildDetailRow('Phone', technician.phone),
              if (technician.skills.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Skills:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: technician.skills.map((skill) {
                    return Chip(
                      label: Text(skill),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],
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
            width: 80,
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

class TechnicianDialog extends StatefulWidget {
  final Technician? technician;

  const TechnicianDialog({super.key, this.technician});

  @override
  State<TechnicianDialog> createState() => _TechnicianDialogState();
}

class _TechnicianDialogState extends State<TechnicianDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late List<String> _selectedSkills;
  TechnicianStatus _selectedStatus = TechnicianStatus.active;
  late TextEditingController _hourlyRateController;

  final List<String> _availableSkills = [
    'Hardware Repair',
    'Software Troubleshooting',
    'Networking',
    'Data Recovery',
    'Mobile Devices',
    'Computer Assembly',
    'Virus Removal',
    'System Installation',
    'Performance Optimization',
    'Backup Solutions',
  ];

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.technician?.firstName ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.technician?.lastName ?? '',
    );
    _emailController = TextEditingController(
      text: widget.technician?.email ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.technician?.phone ?? '',
    );
    _hourlyRateController = TextEditingController(
      text: widget.technician?.hourlyRate.toString() ?? '0.0',
    );
    _selectedSkills = List.from(widget.technician?.skills ?? []);
    _selectedStatus = widget.technician?.status ?? TechnicianStatus.active;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.technician == null ? 'Add Technician' : 'Edit Technician',
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'First Name *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter first name';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Last Name *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter last name';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<TechnicianStatus>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: TechnicianStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status.displayName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _hourlyRateController,
                        decoration: const InputDecoration(
                          labelText: 'Hourly Rate',
                          border: OutlineInputBorder(),
                          prefixText: '\$',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Skills:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _availableSkills.map((skill) {
                        final isSelected = _selectedSkills.contains(skill);
                        return FilterChip(
                          label: Text(skill),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedSkills.add(skill);
                              } else {
                                _selectedSkills.remove(skill);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
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
          onPressed: _saveTechnician,
          child: Text(widget.technician == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }

  void _saveTechnician() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final technician = Technician(
        id: widget.technician?.id ?? '',
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        status: _selectedStatus,
        skills: _selectedSkills,
        hourlyRate: double.tryParse(_hourlyRateController.text) ?? 0.0,
        hireDate: widget.technician?.hireDate ?? DateTime.now(),
        createdAt: widget.technician?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.technician == null) {
        await context.read<TechnicianProvider>().createTechnician(technician);
      } else {
        await context.read<TechnicianProvider>().updateTechnician(technician);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.technician == null
                  ? 'Technician added successfully'
                  : 'Technician updated successfully',
            ),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving technician: $e'),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        );
      }
    }
  }
}
