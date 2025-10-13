import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../models/models.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              if (authProvider.hasPermission(Permission.createUsers)) {
                return IconButton(
                  icon: const Icon(Icons.person_add),
                  onPressed: () => _showAddUserDialog(),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (!authProvider.canViewUsers()) {
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
                    'You do not have permission to view user management.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // System Users Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'System Users',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          _buildUserTile(
                            username: 'admin',
                            role: UserRole.admin,
                            email: 'admin@drivenrepairs.com',
                            isCurrentUser:
                                authProvider.currentUser?.username == 'admin',
                            lastLogin: 'Currently logged in',
                          ),
                          const Divider(),
                          _buildUserTile(
                            username: 'technician',
                            role: UserRole.technician,
                            email: 'tech@drivenrepairs.com',
                            isCurrentUser:
                                authProvider.currentUser?.username ==
                                'technician',
                            lastLogin: 'Never logged in',
                          ),
                          const Divider(),
                          _buildUserTile(
                            username: 'sales',
                            role: UserRole.sales,
                            email: 'sales@drivenrepairs.com',
                            isCurrentUser:
                                authProvider.currentUser?.username == 'sales',
                            lastLogin: 'Never logged in',
                          ),
                          const Divider(),
                          _buildUserTile(
                            username: 'accountant',
                            role: UserRole.accountant,
                            email: 'accounting@drivenrepairs.com',
                            isCurrentUser:
                                authProvider.currentUser?.username ==
                                'accountant',
                            lastLogin: 'Never logged in',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Admin Tools Card (only for admins)
                  if (authProvider.currentUser?.role == UserRole.admin) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Administrator Tools',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              leading: const Icon(Icons.security),
                              title: const Text('Reset User Password'),
                              subtitle: const Text(
                                'Reset password for any system user',
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () => _showResetPasswordDialog(context),
                            ),
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.person_add),
                              title: const Text('Create New User'),
                              subtitle: const Text(
                                'Add new users to the system',
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () => _showCreateUserDialog(context),
                            ),
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.history),
                              title: const Text('User Activity Logs'),
                              subtitle: const Text(
                                'View system-wide user activities',
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () => _showSystemActivityDialog(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserTile({
    required String username,
    required UserRole role,
    required String email,
    required bool isCurrentUser,
    required String lastLogin,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF757575), // Neutral grey for all users
        child: Text(
          username[0].toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Row(
        children: [
          Text(
            username,
            style: TextStyle(
              fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF757575), // Neutral grey
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'You',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(role.displayName),
          Text(email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(
            'Last login: $lastLogin',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'reset_password',
            child: Row(
              children: [
                Icon(Icons.lock_reset, size: 18),
                SizedBox(width: 8),
                Text('Reset Password'),
              ],
            ),
          ),
          if (!isCurrentUser)
            PopupMenuItem(
              value: 'deactivate',
              child: Row(
                children: [
                  Icon(Icons.person_off, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  const Text('Deactivate'),
                ],
              ),
            ),
        ],
        onSelected: (value) {
          switch (value) {
            case 'reset_password':
              _showResetPasswordDialog(context, username);
              break;
            case 'deactivate':
              _showDeactivateUserDialog(context, username);
              break;
          }
        },
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context, [String? username]) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              username != null
                  ? 'Reset password for user: $username'
                  : 'Select a user to reset their password',
            ),
            const SizedBox(height: 16),
            const Text(
              'This feature will be implemented in the next update.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
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

  void _showCreateUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateUserDialog(),
    );
  }

  void _showSystemActivityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('System Activity Logs'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('View comprehensive activity logs for all system users.'),
            SizedBox(height: 16),
            Text(
              'For now, you can view individual user activities from the dashboard.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
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

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateUserDialog(),
    );
  }

  void _showDeactivateUserDialog(BuildContext context, String username) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to deactivate user: $username?'),
            const SizedBox(height: 16),
            const Text(
              'This feature will be implemented in the next update.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }
}

class CreateUserDialog extends StatefulWidget {
  const CreateUserDialog({super.key});

  @override
  State<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  UserRole _selectedRole = UserRole.technician;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New User'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a username';
                    }
                    if (value.length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                      return 'Username can only contain letters, numbers, and underscores';
                    }
                    return null;
                  },
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
                DropdownButtonFormField<UserRole>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                  ),
                  items: UserRole.values.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Row(
                        children: [
                          Icon(
                            _getRoleIcon(role),
                            size: 20,
                            color: _getRoleColor(role),
                          ),
                          const SizedBox(width: 8),
                          Text(role.displayName),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !_isPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password *',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !_isConfirmPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Role Permissions for ${_selectedRole.displayName}:',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ..._selectedRole.permissions.map((permission) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check,
                                size: 16,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _getPermissionDisplayName(permission),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
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
        FilledButton(onPressed: _createUser, child: const Text('Create User')),
      ],
    );
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.technician:
        return Icons.build;
      case UserRole.sales:
        return Icons.sell;
      case UserRole.accountant:
        return Icons.calculate;
    }
  }

  Color _getRoleColor(UserRole role) {
    // Use neutral grey for all roles
    return const Color(0xFF757575);
  }

  String _getPermissionDisplayName(Permission permission) {
    switch (permission) {
      case Permission.viewCustomers:
        return 'View Customers';
      case Permission.createCustomers:
        return 'Create Customers';
      case Permission.editCustomers:
        return 'Edit Customers';
      case Permission.deleteCustomers:
        return 'Delete Customers';
      case Permission.viewTickets:
        return 'View Tickets';
      case Permission.createTickets:
        return 'Create Tickets';
      case Permission.editTickets:
        return 'Edit Tickets';
      case Permission.deleteTickets:
        return 'Delete Tickets';
      case Permission.assignTickets:
        return 'Assign Tickets';
      case Permission.viewDevices:
        return 'View Devices';
      case Permission.createDevices:
        return 'Create Devices';
      case Permission.editDevices:
        return 'Edit Devices';
      case Permission.deleteDevices:
        return 'Delete Devices';
      case Permission.viewParts:
        return 'View Parts';
      case Permission.createParts:
        return 'Create Parts';
      case Permission.editParts:
        return 'Edit Parts';
      case Permission.deleteParts:
        return 'Delete Parts';
      case Permission.viewUsers:
        return 'View Users';
      case Permission.createUsers:
        return 'Create Users';
      case Permission.editUsers:
        return 'Edit Users';
      case Permission.deleteUsers:
        return 'Delete Users';
      case Permission.viewReports:
        return 'View Reports';
      case Permission.viewSettings:
        return 'View Settings';
      case Permission.editSettings:
        return 'Edit Settings';
      case Permission.viewAuditLogs:
        return 'View Audit Logs';
      case Permission.updateTicketStatus:
        return 'Update Ticket Status';
      case Permission.addTicketNotes:
        return 'Add Ticket Notes';
      case Permission.createQuotes:
        return 'Create Quotes';
      case Permission.viewSalesReports:
        return 'View Sales Reports';
      case Permission.viewFinancialReports:
        return 'View Financial Reports';
      case Permission.manageBilling:
        return 'Manage Billing';
    }
  }

  void _createUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      // Check if username already exists (this would be a real database check)
      final existingUsernames = ['admin', 'technician', 'sales', 'accountant'];
      if (existingUsernames.contains(_usernameController.text.toLowerCase())) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Username already exists'),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        );
        return;
      }

      // In a real implementation, this would save to database
      // For now, we'll simulate success
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        // In a real implementation, we would log this to the activity log
        debugPrint(
          'User created: ${_usernameController.text} with role: ${_selectedRole.displayName}',
        );

        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'User "${_usernameController.text}" created successfully',
            ),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating user: $e'),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        );
      }
    }
  }
}
