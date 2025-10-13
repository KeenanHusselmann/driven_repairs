import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';

class PartsScreen extends StatefulWidget {
  const PartsScreen({super.key});

  @override
  State<PartsScreen> createState() => _PartsScreenState();
}

class _PartsScreenState extends State<PartsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  bool _showLowStock = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PartProvider>().loadParts();
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
      appBar: AppBar(title: const Text('Parts Management')),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (!authProvider.hasPermission(Permission.viewParts)) {
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
                    'You do not have permission to view parts.',
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
                        hintText: 'Search parts...',
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
                            initialValue: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(),
                            ),
                            items: _getCategories().map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value!;
                              });
                              _performSearch();
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        FilterChip(
                          label: const Text('Low Stock'),
                          selected: _showLowStock,
                          onSelected: (selected) {
                            setState(() {
                              _showLowStock = selected;
                            });
                            _performSearch();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Parts List
              Expanded(
                child: Consumer<PartProvider>(
                  builder: (context, partProvider, _) {
                    if (partProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final parts = _getFilteredParts(partProvider.parts);

                    if (parts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No parts found',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 18,
                              ),
                            ),
                            if (_searchController.text.isNotEmpty ||
                                _selectedCategory != 'All' ||
                                _showLowStock) ...[
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
                      itemCount: parts.length,
                      itemBuilder: (context, index) {
                        final part = parts[index];
                        return _buildPartCard(part, authProvider);
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
          if (authProvider.hasPermission(Permission.createParts)) {
            return FloatingActionButton.extended(
              onPressed: () => _showAddPartDialog(),
              icon: const Icon(Icons.add_box),
              label: const Text('Add Part'),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildPartCard(Part part, AuthProvider authProvider) {
    final isLowStock = part.quantityInStock <= part.minimumStock;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isLowStock 
              ? const Color(0xFF757575) 
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.inventory_outlined, 
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          part.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (part.partNumber != null) Text('Part #: ${part.partNumber}'),
            if (part.manufacturer != null) Text('Mfg: ${part.manufacturer}'),
            Row(
              children: [
                Text(
                  'Stock: ${part.quantityInStock}',
                  style: TextStyle(
                    color: isLowStock ? const Color(0xFF757575) : null,
                    fontWeight: isLowStock ? FontWeight.bold : null,
                  ),
                ),
                if (isLowStock) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'LOW',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Text('\$${part.cost.toStringAsFixed(2)}'),
              ],
            ),
          ],
        ),
        trailing: authProvider.hasPermission(Permission.editParts)
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
                      _showEditPartDialog(part);
                      break;
                    case 'delete':
                      _showDeletePartDialog(part);
                      break;
                  }
                },
              )
            : null,
        onTap: () => _showPartDetails(part),
      ),
    );
  }

  List<String> _getCategories() {
    return [
      'All',
      'Hardware',
      'Software',
      'Components',
      'Accessories',
      'Tools',
      'Consumables',
      'Other',
    ];
  }

  List<Part> _getFilteredParts(List<Part> parts) {
    var filtered = parts;

    // Filter by search term
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = filtered.where((part) {
        return part.name.toLowerCase().contains(searchTerm) ||
            (part.partNumber?.toLowerCase().contains(searchTerm) ?? false) ||
            (part.manufacturer?.toLowerCase().contains(searchTerm) ?? false) ||
            (part.description?.toLowerCase().contains(searchTerm) ?? false);
      }).toList();
    }

    // Filter by category
    if (_selectedCategory != 'All') {
      filtered = filtered.where((part) {
        return part.category?.toLowerCase() == _selectedCategory.toLowerCase();
      }).toList();
    }

    // Filter by low stock
    if (_showLowStock) {
      filtered = filtered.where((part) {
        return part.quantityInStock <= part.minimumStock;
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
      _selectedCategory = 'All';
      _showLowStock = false;
    });
  }

  void _showAddPartDialog() {
    _showPartDialog(null);
  }

  void _showEditPartDialog(Part part) {
    _showPartDialog(part);
  }

  void _showPartDialog(Part? part) {
    showDialog(
      context: context,
      builder: (context) => PartDialog(part: part),
    );
  }

  void _showDeletePartDialog(Part part) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Part'),
        content: Text('Are you sure you want to delete ${part.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await context.read<PartProvider>().deletePart(part.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Part deleted successfully'),
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting part: $e'),
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

  void _showPartDetails(Part part) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(part.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (part.partNumber != null)
                _buildDetailRow('Part Number', part.partNumber!),
              if (part.manufacturer != null)
                _buildDetailRow('Manufacturer', part.manufacturer!),
              if (part.category != null)
                _buildDetailRow('Category', part.category!),
              if (part.description != null)
                _buildDetailRow('Description', part.description!),
              _buildDetailRow('Cost', '\$${part.cost.toStringAsFixed(2)}'),
              _buildDetailRow('Stock Quantity', '${part.quantityInStock}'),
              _buildDetailRow('Minimum Stock', '${part.minimumStock}'),
              if (part.supplier != null)
                _buildDetailRow('Supplier', part.supplier!),
              if (part.location != null)
                _buildDetailRow('Location', part.location!),
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

class PartDialog extends StatefulWidget {
  final Part? part;

  const PartDialog({super.key, this.part});

  @override
  State<PartDialog> createState() => _PartDialogState();
}

class _PartDialogState extends State<PartDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _partNumberController;
  late TextEditingController _manufacturerController;
  late TextEditingController _descriptionController;
  late TextEditingController _costController;
  late TextEditingController _quantityController;
  late TextEditingController _minimumStockController;
  late TextEditingController _supplierController;
  late TextEditingController _locationController;
  String _selectedCategory = 'Hardware';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.part?.name ?? '');
    _partNumberController = TextEditingController(
      text: widget.part?.partNumber ?? '',
    );
    _manufacturerController = TextEditingController(
      text: widget.part?.manufacturer ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.part?.description ?? '',
    );
    _costController = TextEditingController(
      text: widget.part?.cost.toString() ?? '',
    );
    _quantityController = TextEditingController(
      text: widget.part?.quantityInStock.toString() ?? '',
    );
    _minimumStockController = TextEditingController(
      text: widget.part?.minimumStock.toString() ?? '0',
    );
    _supplierController = TextEditingController(
      text: widget.part?.supplier ?? '',
    );
    _locationController = TextEditingController(
      text: widget.part?.location ?? '',
    );
    _selectedCategory = widget.part?.category ?? 'Hardware';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _partNumberController.dispose();
    _manufacturerController.dispose();
    _descriptionController.dispose();
    _costController.dispose();
    _quantityController.dispose();
    _minimumStockController.dispose();
    _supplierController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.part == null ? 'Add Part' : 'Edit Part'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Part Name *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a part name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _partNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Part Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _manufacturerController,
                  decoration: const InputDecoration(
                    labelText: 'Manufacturer',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      [
                        'Hardware',
                        'Software',
                        'Components',
                        'Accessories',
                        'Tools',
                        'Consumables',
                        'Other',
                      ].map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _costController,
                  decoration: const InputDecoration(
                    labelText: 'Cost *',
                    border: OutlineInputBorder(),
                    prefixText: '\$',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a cost';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Quantity *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter quantity';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _minimumStockController,
                        decoration: const InputDecoration(
                          labelText: 'Min Stock',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (int.tryParse(value) == null) {
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
                TextFormField(
                  controller: _supplierController,
                  decoration: const InputDecoration(
                    labelText: 'Supplier',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
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
          onPressed: _savePart,
          child: Text(widget.part == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }

  void _savePart() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final part = Part(
        id: widget.part?.id ?? '',
        name: _nameController.text,
        partNumber: _partNumberController.text.isEmpty
            ? null
            : _partNumberController.text,
        manufacturer: _manufacturerController.text.isEmpty
            ? null
            : _manufacturerController.text,
        category: _selectedCategory,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        cost: double.parse(_costController.text),
        quantityInStock: int.parse(_quantityController.text),
        minimumStock: int.parse(
          _minimumStockController.text.isEmpty
              ? '0'
              : _minimumStockController.text,
        ),
        supplier: _supplierController.text.isEmpty
            ? null
            : _supplierController.text,
        location: _locationController.text.isEmpty
            ? null
            : _locationController.text,
        createdAt: widget.part?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.part == null) {
        await context.read<PartProvider>().createPart(part);
      } else {
        await context.read<PartProvider>().updatePart(part);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.part == null
                  ? 'Part added successfully'
                  : 'Part updated successfully',
            ),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving part: $e'),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        );
      }
    }
  }
}
