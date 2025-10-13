import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../models/models.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Timer? _activityRefreshTimer;
  List<ActivityLog> _recentActivities = [];
  bool _isLoadingActivities = false;

  @override
  void initState() {
    super.initState();
    _setupRealTimeUpdates();
  }

  @override
  void dispose() {
    _activityRefreshTimer?.cancel();
    super.dispose();
  }

  void _setupRealTimeUpdates() {
    _loadRecentActivities();
    // Refresh activity data every 30 seconds
    _activityRefreshTimer = Timer.periodic(const Duration(seconds: 30), (
      timer,
    ) {
      if (mounted) {
        _loadRecentActivities();
      }
    });
  }

  Future<void> _loadRecentActivities() async {
    if (!mounted) return;

    setState(() {
      _isLoadingActivities = true;
    });

    try {
      final activities = await ActivityService().getRecentActivities(limit: 10);
      if (mounted) {
        setState(() {
          _recentActivities = activities;
          _isLoadingActivities = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingActivities = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (!authProvider.canViewSettings()) {
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
                    'You do not have permission to view settings.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // User Profile Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User Profile',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: CircleAvatar(
                          child: Text(authProvider.userInitials),
                        ),
                        title: Text(authProvider.userDisplayName),
                        subtitle: Text(
                          authProvider.currentUser?.role.displayName ?? '',
                        ),
                        trailing: const Icon(Icons.edit),
                        onTap: () => _showEditProfileDialog(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Activity Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Recent Activity',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Spacer(),
                          if (_isLoadingActivities)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF757575).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.circle,
                                    color: const Color(0xFF757575),
                                    size: 8,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Live',
                                    style: TextStyle(
                                      color: const Color(0xFF757575),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_recentActivities.isEmpty && !_isLoadingActivities)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'No recent activities',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        Column(
                          children: _recentActivities.take(5).map((activity) {
                            return _buildActivityItem(activity);
                          }).toList(),
                        ),
                      const SizedBox(height: 8),
                      if (authProvider.isAdmin)
                        TextButton(
                          onPressed: () => _showAuditLogsDialog(),
                          child: const Text('View All Audit Logs'),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Security Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Security',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.lock),
                        title: const Text('Change Password'),
                        subtitle: const Text('Update your account password'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => _showChangePasswordDialog(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // System Settings (Admin only)
              if (authProvider.isAdmin) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'System Settings',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.history),
                          title: const Text('System Audit Logs'),
                          subtitle: const Text(
                            'View comprehensive system activity logs',
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () => _showAuditLogsDialog(),
                        ),
                        ListTile(
                          leading: const Icon(Icons.backup),
                          title: const Text('Database Backup'),
                          subtitle: const Text('Export system data to file'),
                          trailing: const Icon(Icons.download),
                          onTap: () => _performDatabaseBackup(),
                        ),
                        ListTile(
                          leading: const Icon(Icons.restore),
                          title: const Text('Database Restore'),
                          subtitle: const Text('Import system data from file'),
                          trailing: const Icon(Icons.upload),
                          onTap: () => _performDatabaseRestore(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Logout Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListTile(
                    leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    title: const Text(
                      'Logout',
                    ),
                    subtitle: const Text('Sign out of your account'),
                    onTap: () => _showLogoutDialog(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final authProvider = context.read<AuthProvider>();
                final success = await authProvider.changePassword(
                  currentPasswordController.text,
                  newPasswordController.text,
                );

                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Password changed successfully'
                            : 'Failed to change password',
                      ),
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                  );
                }
              }
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final authProvider = context.read<AuthProvider>();
              await authProvider.logout();
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(ActivityLog activity) {
    IconData icon;
    Color color;
    String title;

    // Use neutral grey for all activity types
    const neutralGrey = Color(0xFF757575);
    
    switch (activity.activityType) {
      case ActivityType.create:
        icon = Icons.add_circle;
        color = neutralGrey;
        title = 'Created ${_getEntityDisplayName(activity.entityType)}';
        break;
      case ActivityType.update:
        icon = Icons.edit;
        color = neutralGrey;
        title = 'Updated ${_getEntityDisplayName(activity.entityType)}';
        break;
      case ActivityType.delete:
        icon = Icons.delete;
        color = neutralGrey;
        title = 'Deleted ${_getEntityDisplayName(activity.entityType)}';
        break;
      case ActivityType.login:
        icon = Icons.login;
        color = neutralGrey;
        title = 'User Login';
        break;
      case ActivityType.logout:
        icon = Icons.logout;
        color = neutralGrey;
        title = 'User Logout';
        break;
      default:
        icon = Icons.info;
        color = neutralGrey;
        title = activity.description;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${activity.username} • ${_formatTimeAgo(activity.timestamp)}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getEntityDisplayName(EntityType entityType) {
    switch (entityType) {
      case EntityType.customer:
        return 'Customer';
      case EntityType.ticket:
        return 'Ticket';
      case EntityType.device:
        return 'Device';
      case EntityType.part:
        return 'Part';
      case EntityType.user:
        return 'User';
      case EntityType.system:
        return 'System';
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  void _showEditProfileDialog() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    if (user == null) return;

    final firstNameController = TextEditingController(text: user.firstName);
    final lastNameController = TextEditingController(text: user.lastName);
    final emailController = TextEditingController(text: user.email);
    final phoneController = TextEditingController(text: user.phone ?? '');
    final departmentController = TextEditingController(
      text: user.department ?? '',
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'First Name',
                          border: OutlineInputBorder(),
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
                        controller: lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Last Name',
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
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: departmentController,
                  decoration: const InputDecoration(
                    labelText: 'Department (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final success = await authProvider.updateUserProfile(
                  firstName: firstNameController.text,
                  lastName: lastNameController.text,
                  email: emailController.text,
                  phone: phoneController.text.isEmpty
                      ? null
                      : phoneController.text,
                );

                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Profile updated successfully'
                            : 'Failed to update profile',
                      ),
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                  );
                }
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showAuditLogsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 800,
          height: 600,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'System Audit Logs',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<ActivityLog>>(
                  future: ActivityService().getActivityLogs(limit: 100),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError || !snapshot.hasData) {
                      return const Center(
                        child: Text('Failed to load audit logs'),
                      );
                    }

                    final logs = snapshot.data!;
                    if (logs.isEmpty) {
                      return const Center(
                        child: Text('No audit logs available'),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                              _getActivityIcon(log.activityType),
                              color: _getActivityColor(log.activityType),
                            ),
                            title: Text(log.description),
                            subtitle: Text(
                              '${log.username} (${log.userRole.displayName}) • ${_formatTimeAgo(log.timestamp)}',
                            ),
                            trailing: Text(
                              log.entityType.name.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.create:
        return Icons.add_circle;
      case ActivityType.update:
        return Icons.edit;
      case ActivityType.delete:
        return Icons.delete;
      case ActivityType.login:
        return Icons.login;
      case ActivityType.logout:
        return Icons.logout;
      case ActivityType.backup:
        return Icons.backup;
      case ActivityType.restore:
        return Icons.restore;
      default:
        return Icons.info;
    }
  }

  Color _getActivityColor(ActivityType type) {
    // Use neutral grey for all activity types
    return const Color(0xFF757575);
  }

  Future<void> _performDatabaseBackup() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Creating database backup...'),
            ],
          ),
        ),
      );

      // Get the database file path
      final dbService = DatabaseService();
      final dbPath = await dbService.getDatabasePath();

      // Let user choose where to save the backup
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Database Backup',
        fileName:
            'driven_repairs_backup_${DateTime.now().millisecondsSinceEpoch}.db',
        type: FileType.custom,
        allowedExtensions: ['db'],
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
      }

      if (result != null) {
        // Copy database file to selected location
        final dbFile = File(dbPath);
        await dbFile.copy(result);

        // Log the backup activity
        final authProvider = context.read<AuthProvider>();
        if (authProvider.currentUser != null) {
          await ActivityService().logActivity(
            userId: authProvider.currentUser!.id,
            username: authProvider.currentUser!.username,
            userRole: authProvider.currentUser!.role,
            activityType: ActivityType.backup,
            entityType: EntityType.system,
            description: 'Database backup created',
            metadata: {'backupPath': result},
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Database backup created successfully'),
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog if still open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create backup: $e'),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        );
      }
    }
  }

  Future<void> _performDatabaseRestore() async {
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Database'),
        content: const Text(
          'WARNING: This will replace all current data with the backup data. '
          'This action cannot be undone. Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Let user select backup file
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select Database Backup',
        type: FileType.custom,
        allowedExtensions: ['db'],
      );

      if (result == null || result.files.isEmpty) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Restoring database...'),
            ],
          ),
        ),
      );

      // Get the database file path
      final dbService = DatabaseService();
      final dbPath = await dbService.getDatabasePath();

      // Copy backup file to database location
      final backupFile = File(result.files.first.path!);
      await backupFile.copy(dbPath);

      // Log the restore activity
      final authProvider = context.read<AuthProvider>();
      if (authProvider.currentUser != null) {
        await ActivityService().logActivity(
          userId: authProvider.currentUser!.id,
          username: authProvider.currentUser!.username,
          userRole: authProvider.currentUser!.role,
          activityType: ActivityType.restore,
          entityType: EntityType.system,
          description: 'Database restored from backup',
          metadata: {'backupPath': result.files.first.path},
        );
      }

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Database restored successfully. Please restart the application.',
            ),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog if still open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore database: $e'),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        );
      }
    }
  }
}
