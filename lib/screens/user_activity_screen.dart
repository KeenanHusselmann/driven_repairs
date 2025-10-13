import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';

class UserActivityScreen extends StatefulWidget {
  const UserActivityScreen({super.key});

  @override
  State<UserActivityScreen> createState() => _UserActivityScreenState();
}

class _UserActivityScreenState extends State<UserActivityScreen>
    with TickerProviderStateMixin {
  final ActivityService _activityService = ActivityService();
  late TabController _tabController;
  List<ActivityLog> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserActivities();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserActivities() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        final activities = await _activityService.getUserActivities(
          authProvider.currentUser!.id,
          limit: 100,
        );
        setState(() {
          _activities = activities;
        });
      }
    } catch (e) {
      debugPrint('Error loading user activities: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildActivityCard(ActivityLog activity) {
    Color getActivityColor(ActivityType type) {
      // Use neutral grey for all activity types
      return const Color(0xFF757575);
    }

    IconData getActivityIcon(ActivityType type) {
      switch (type) {
        case ActivityType.create:
          return Icons.add_circle;
        case ActivityType.update:
          return Icons.edit;
        case ActivityType.delete:
          return Icons.delete;
        case ActivityType.view:
          return Icons.visibility;
        case ActivityType.login:
          return Icons.login;
        case ActivityType.logout:
          return Icons.logout;
        default:
          return Icons.info;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: getActivityColor(activity.activityType),
          child: Icon(
            getActivityIcon(activity.activityType),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          activity.description,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${activity.activityType.value} • ${activity.entityType.value}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDateTime(activity.timestamp),
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
        trailing: activity.metadata != null && activity.metadata!.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.info_outline, size: 20),
                onPressed: () => _showActivityDetails(activity),
              )
            : null,
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  void _showActivityDetails(ActivityLog activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(activity.description),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Activity Type', activity.activityType.value),
            _buildDetailRow('Entity Type', activity.entityType.value),
            _buildDetailRow('Entity ID', activity.entityId ?? 'N/A'),
            _buildDetailRow('Timestamp', activity.timestamp.toString()),
            if (activity.metadata != null && activity.metadata!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Additional Details:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...activity.metadata!.entries.map(
                (entry) => _buildDetailRow(entry.key, entry.value.toString()),
              ),
            ],
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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

  List<ActivityLog> _getFilteredActivities(ActivityType? filterType) {
    if (filterType == null) return _activities;
    return _activities.where((a) => a.activityType == filterType).toList();
  }

  Widget _buildActivityList(ActivityType? filterType) {
    final filteredActivities = _getFilteredActivities(filterType);

    if (filteredActivities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              filterType == null
                  ? 'No activities found'
                  : 'No ${filterType.value.toLowerCase()} activities found',
              style: TextStyle(color: Colors.grey[600], fontSize: 18),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUserActivities,
      child: ListView.builder(
        itemCount: filteredActivities.length,
        itemBuilder: (context, index) {
          return _buildActivityCard(filteredActivities[index]);
        },
      ),
    );
  }

  Widget _buildModificationsList() {
    final modificationActivities = _activities
        .where(
          (a) =>
              a.activityType == ActivityType.create ||
              a.activityType == ActivityType.update ||
              a.activityType == ActivityType.delete,
        )
        .toList();

    if (modificationActivities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No modification activities found',
              style: TextStyle(color: Colors.grey[600], fontSize: 18),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUserActivities,
      child: ListView.builder(
        itemCount: modificationActivities.length,
        itemBuilder: (context, index) {
          return _buildActivityCard(modificationActivities[index]);
        },
      ),
    );
  }

  Widget _buildSessionsList() {
    final sessionActivities = _activities
        .where(
          (a) =>
              a.activityType == ActivityType.login ||
              a.activityType == ActivityType.logout,
        )
        .toList();

    if (sessionActivities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.login, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No session activities found',
              style: TextStyle(color: Colors.grey[600], fontSize: 18),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUserActivities,
      child: ListView.builder(
        itemCount: sessionActivities.length,
        itemBuilder: (context, index) {
          return _buildActivityCard(sessionActivities[index]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Activities'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.all_inbox), text: 'All'),
            Tab(icon: Icon(Icons.edit), text: 'Modifications'),
            Tab(icon: Icon(Icons.login), text: 'Sessions'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserActivities,
            tooltip: 'Refresh Activities',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildActivityList(null), // All activities
                _buildModificationsList(), // Create/Update/Delete activities
                _buildSessionsList(), // Login/Logout activities
              ],
            ),
    );
  }
}
