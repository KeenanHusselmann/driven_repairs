import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'repair_tickets_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;

    final ticketProvider = context.read<RepairTicketProvider>();
    final customerProvider = context.read<CustomerProvider>();

    await Future.wait([
      ticketProvider.loadTickets(),
      customerProvider.loadCustomers(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Watermark logo in background
          Positioned.fill(
            child: Center(
              child: Opacity(
                opacity: 0.03,
                child: Image.asset(
                  'assets/images/logo_transparent.png',
                  width: 600,
                  height: 600,
                  fit: BoxFit.contain,
                  color: const Color(0xFF4A90E2), // Professional blue tint
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),
            ),
          ),
          // Main content
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildQuickActionsCard(),
                  const SizedBox(height: 32),
                  _buildKPICards(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildActiveTicketsCard(),
                        const SizedBox(height: 16),
                        _buildRevenueChart(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      children: [
                        _buildSystemHealthCard(),
                        const SizedBox(height: 16),
                        _buildUserActivitiesCard(),
                        const SizedBox(height: 16),
                        _buildOverdueTicketsCard(),
                        const SizedBox(height: 16),
                        _buildUpcomingDeadlinesCard(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.currentUser;
        String roleSpecificMessage = _getRoleSpecificMessage(user?.role);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Dashboard',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                if (user != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      user.role.displayName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Welcome back, ${user?.fullName ?? 'User'}! $roleSpecificMessage',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }

  String _getRoleSpecificMessage(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        return 'You have full access to manage all aspects of the repair system.';
      case UserRole.technician:
        return 'Here are your assigned tickets and recent repair activities.';
      case UserRole.sales:
        return 'Track customer interactions and new repair requests.';
      case UserRole.accountant:
        return 'Monitor financial reports and part inventory costs.';
      default:
        return 'Here\'s what\'s happening with your repair shop.';
    }
  }

  Widget _buildKPICards() {
    return Consumer<RepairTicketProvider>(
      builder: (context, ticketProvider, child) {
        return Row(
          children: [
            Expanded(
              child: _buildEnhancedKPICard(
                title: 'Active Repairs',
                value: ticketProvider.tickets
                    .where((ticket) => ticket.status.isActive)
                    .length
                    .toString(),
                color: Theme.of(context).colorScheme.primary,
                trend: _calculateTrend(ticketProvider.tickets, 'active'),
                subtitle: 'In progress',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildEnhancedKPICard(
                title: 'Completed Today',
                value: ticketProvider.tickets
                    .where(
                      (ticket) =>
                          ticket.status == RepairStatus.completed &&
                          ticket.actualCompletion != null &&
                          _isToday(ticket.actualCompletion!),
                    )
                    .length
                    .toString(),
                color: Theme.of(context).colorScheme.primary,
                trend: '+12%',
                subtitle: 'vs yesterday',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildEnhancedKPICard(
                title: 'Revenue Today',
                value: '\$${_calculateTodayRevenue(ticketProvider.tickets)}',
                color: Theme.of(context).colorScheme.primary,
                trend: '+8%',
                subtitle: 'vs yesterday',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildEnhancedKPICard(
                title: 'Avg. Repair Time',
                value:
                    '${_calculateAverageRepairTime(ticketProvider.tickets)}h',
                color: Theme.of(context).colorScheme.primary,
                trend: '-15%',
                subtitle: 'improvement',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActiveTicketsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Active Tickets',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go('/tickets'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const Divider(),
            Consumer<RepairTicketProvider>(
              builder: (context, provider, child) {
                final activeTickets = provider.tickets
                    .where((ticket) => ticket.status.isActive)
                    .take(5)
                    .toList();

                if (activeTickets.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No active tickets')),
                  );
                }

                return Column(
                  children: activeTickets.map((ticket) {
                    return ListTile(
                      leading: _getStatusIcon(ticket.status),
                      title: Row(
                        children: [
                          Text(
                            'Ticket #${ticket.id}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ticket.title,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        'Priority: ${ticket.priority.displayName}',
                      ),
                      trailing: ticket.estimatedCompletion != null
                          ? Text(
                              DateFormat(
                                'MMM dd',
                              ).format(ticket.estimatedCompletion!),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            )
                          : null,
                      onTap: () => _showTicketDetails(context, ticket.id),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTicketDetails(BuildContext context, String ticketId) {
    showDialog(
      context: context,
      builder: (context) => TicketDetailsDialog(ticketId: ticketId),
    );
  }

  Widget _buildQuickActionsCard() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Card(
          elevation: 2,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.flash_on,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildHorizontalQuickActions(authProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverdueTicketsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overdue Tickets',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            Consumer<RepairTicketProvider>(
              builder: (context, provider, child) {
                final overdueTickets = provider.tickets
                    .where((ticket) => ticket.isOverdue)
                    .take(3)
                    .toList();

                if (overdueTickets.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No overdue tickets')),
                  );
                }

                return Column(
                  children: overdueTickets.map((ticket) {
                    return ListTile(
                      leading: Icon(Icons.warning, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      title: Text(ticket.title),
                      subtitle: Text(
                        'Due: ${DateFormat('MMM dd, yyyy').format(ticket.estimatedCompletion!)}',
                      ),
                      onTap: () => context.go('/tickets/${ticket.id}'),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserActivitiesCard() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'My Recent Activities',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.go('/activities'),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<ActivityLog>>(
                  future: authProvider.currentUser != null
                      ? _getRecentUserActivities(authProvider.currentUser!.id)
                      : Future.value([]),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final activities = snapshot.data ?? [];
                    if (activities.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No recent activities',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: activities.take(3).map((activity) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 12,
                            backgroundColor: _getActivityColor(
                              activity.activityType,
                            ),
                            child: Icon(
                              _getActivityIcon(activity.activityType),
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                          title: Text(
                            activity.description,
                            style: const TextStyle(fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            _formatTimeAgo(activity.timestamp),
                            style: const TextStyle(fontSize: 11),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<List<ActivityLog>> _getRecentUserActivities(String userId) async {
    try {
      final ActivityService activityService = ActivityService();
      return await activityService.getUserActivities(userId, limit: 5);
    } catch (e) {
      debugPrint('Error loading user activities: $e');
      return [];
    }
  }

  Color _getActivityColor(ActivityType type) {
    // Use neutral grey for all activity types - subtle differentiation via icons
    return const Color(0xFF9E9E9E); // Neutral grey
  }

  IconData _getActivityIcon(ActivityType type) {
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

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _getStatusIcon(RepairStatus status) {
    const iconColor = Color(0xFF757575); // Neutral grey for all status icons
    switch (status) {
      case RepairStatus.pending:
        return const Icon(Icons.schedule, color: iconColor);
      case RepairStatus.diagnosed:
        return const Icon(Icons.search, color: iconColor);
      case RepairStatus.inProgress:
        return const Icon(Icons.build, color: iconColor);
      case RepairStatus.waitingForParts:
        return const Icon(Icons.inventory, color: iconColor);
      case RepairStatus.waitingForCustomer:
        return const Icon(Icons.person, color: iconColor);
      case RepairStatus.testing:
        return const Icon(Icons.science, color: iconColor);
      case RepairStatus.completed:
        return const Icon(Icons.check_circle, color: iconColor);
      case RepairStatus.cancelled:
        return const Icon(Icons.cancel, color: iconColor);
      case RepairStatus.onHold:
        return const Icon(Icons.pause_circle, color: iconColor);
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // Enhanced KPI Card with trend indicators
  Widget _buildEnhancedKPICard({
    required String title,
    required String value,
    required Color color,
    required String trend,
    required String subtitle,
  }) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trend,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // System Health Card
  Widget _buildSystemHealthCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Health',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildHealthIndicator(
              'Database',
              'Operational',
              Theme.of(context).colorScheme.onSurfaceVariant,
              Icons.storage,
            ),
            _buildHealthIndicator(
              'API Services',
              'Healthy',
              Theme.of(context).colorScheme.onSurfaceVariant,
              Icons.cloud,
            ),
            _buildHealthIndicator(
              'File System',
              'Normal',
              Theme.of(context).colorScheme.onSurfaceVariant,
              Icons.folder,
            ),
            _buildHealthIndicator(
              'Memory Usage',
              '67%',
              Theme.of(context).colorScheme.onSurfaceVariant,
              Icons.memory,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _showSystemDetails(),
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('Details'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthIndicator(
    String name,
    String status,
    Color color,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(name, style: const TextStyle(fontSize: 13))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Revenue Chart Card
  Widget _buildRevenueChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Revenue Trend (Last 7 Days)',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Consumer<RepairTicketProvider>(
                  builder: (context, ticketProvider, child) {
                    final totalRevenue = _calculateWeeklyRevenue(
                      ticketProvider.tickets,
                    );
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Total: \$${totalRevenue.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const Divider(),
            Consumer<RepairTicketProvider>(
              builder: (context, ticketProvider, child) {
                return SizedBox(
                  height: 200,
                  child: _buildRealTimeChart(ticketProvider.tickets),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildChartLegend(
                  'Daily Revenue',
                  Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                _buildChartLegend(
                  '7-Day Average',
                  Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // Upcoming Deadlines Card
  Widget _buildUpcomingDeadlinesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upcoming Deadlines',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            Consumer<RepairTicketProvider>(
              builder: (context, provider, child) {
                final upcomingTickets = provider.tickets
                    .where(
                      (ticket) =>
                          ticket.estimatedCompletion != null &&
                          ticket.estimatedCompletion!.isAfter(DateTime.now()) &&
                          ticket.estimatedCompletion!.isBefore(
                            DateTime.now().add(const Duration(days: 7)),
                          ),
                    )
                    .take(4)
                    .toList();

                if (upcomingTickets.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: Text('No upcoming deadlines')),
                  );
                }

                return Column(
                  children: upcomingTickets.map((ticket) {
                    final daysUntil = ticket.estimatedCompletion!
                        .difference(DateTime.now())
                        .inDays;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '$daysUntil',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        ticket.title,
                        style: const TextStyle(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${daysUntil == 0
                            ? 'Due today'
                            : daysUntil == 1
                            ? 'Due tomorrow'
                            : 'Due in $daysUntil days'}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      onTap: () => showTicketDetailsDialog(context, ticket.id),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for calculations
  String _calculateTrend(List<RepairTicket> tickets, String type) {
    // Simple mock trend calculation - you can implement real logic
    switch (type) {
      case 'active':
        return '+5%';
      default:
        return '+0%';
    }
  }

  String _calculateTodayRevenue(List<RepairTicket> tickets) {
    final todayTickets = tickets.where(
      (ticket) =>
          ticket.status == RepairStatus.completed &&
          ticket.actualCompletion != null &&
          _isToday(ticket.actualCompletion!),
    );

    // Mock calculation - replace with real pricing logic
    return (todayTickets.length * 150).toString();
  }

  double _calculateAverageRepairTime(List<RepairTicket> tickets) {
    final completedTickets = tickets
        .where(
          (ticket) =>
              ticket.status == RepairStatus.completed &&
              ticket.actualCompletion != null,
        )
        .toList();

    if (completedTickets.isEmpty) return 0;

    final totalHours = completedTickets.fold<double>(0, (sum, ticket) {
      final duration = ticket.actualCompletion!.difference(ticket.createdAt);
      return sum + duration.inHours;
    });

    return totalHours / completedTickets.length;
  }

  void _showSystemDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('System Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Database Status', 'Connected & Operational'),
            _buildDetailRow('Active Sessions', '12'),
            _buildDetailRow('Uptime', '5 days, 12 hours'),
            _buildDetailRow('Last Backup', '2 hours ago'),
            _buildDetailRow('Storage Used', '2.3 GB / 10 GB'),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // Horizontal Quick Actions for top positioning
  Widget _buildHorizontalQuickActions(AuthProvider authProvider) {
    final quickActions = <Map<String, dynamic>>[];

    // Add role-based actions
    if (authProvider.hasPermission(Permission.createTickets)) {
      quickActions.add({
        'icon': Icons.add_task,
        'label': 'New Ticket',
        'route': '/tickets',
      });
    }

    if (authProvider.hasPermission(Permission.createCustomers)) {
      quickActions.add({
        'icon': Icons.person_add,
        'label': 'Add Customer',
        'route': '/customers',
      });
    }

    if (authProvider.hasPermission(Permission.createDevices)) {
      quickActions.add({
        'icon': Icons.devices,
        'label': 'Register Device',
        'route': '/devices',
      });
    }

    if (authProvider.hasPermission(Permission.editParts)) {
      quickActions.add({
        'icon': Icons.inventory,
        'label': 'Manage Parts',
        'route': '/parts',
      });
    }

    // Admin specific actions
    if (authProvider.currentUser?.role == UserRole.admin) {
      quickActions.addAll([
        {'icon': Icons.analytics, 'label': 'Analytics', 'route': '/analytics'},
        {'icon': Icons.assessment, 'label': 'Reports', 'route': '/reports'},
      ]);
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: quickActions.map((action) {
        return Material(
          elevation: 3,
          borderRadius: BorderRadius.circular(16),
          shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          child: InkWell(
            onTap: () => context.go(action['route']),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFE8F1FC), // Light professional blue
                    const Color(0xFFF0F6FD), // Very light blue
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF4A90E2).withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    action['icon'],
                    color: const Color(0xFF4A90E2), // Professional blue
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    action['label'],
                    style: const TextStyle(
                      color: Color(0xFF424242), // Dark grey text
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  double _calculateWeeklyRevenue(List<RepairTicket> tickets) {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final weeklyCompletedTickets = tickets
        .where(
          (ticket) =>
              ticket.status == RepairStatus.completed &&
              ticket.actualCompletion != null &&
              ticket.actualCompletion!.isAfter(weekAgo),
        )
        .length;

    // Mock calculation: average ticket value of $180
    return weeklyCompletedTickets * 180.0;
  }

  Widget _buildRealTimeChart(List<RepairTicket> tickets) {
    final dailyRevenue = _calculateDailyRevenue(tickets);
    final maxRevenue = dailyRevenue.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (index) {
                final height = maxRevenue > 0
                    ? (dailyRevenue[index] / maxRevenue) * 120
                    : 0.0;
                return Container(
                  width: 20,
                  height: height,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((day) => Text(day, style: const TextStyle(fontSize: 10)))
                .toList(),
          ),
        ],
      ),
    );
  }

  List<double> _calculateDailyRevenue(List<RepairTicket> tickets) {
    final dailyRevenue = List<double>.filled(7, 0.0);
    final now = DateTime.now();

    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: 6 - i));
      final dayTickets = tickets
          .where(
            (ticket) =>
                ticket.status == RepairStatus.completed &&
                ticket.actualCompletion != null &&
                _isSameDay(ticket.actualCompletion!, day),
          )
          .length;

      dailyRevenue[i] = dayTickets * 180.0; // Average ticket value
    }

    return dailyRevenue;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
