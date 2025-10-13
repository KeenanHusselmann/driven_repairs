import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = 'This Month';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Defer data loading until after the first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadAnalyticsData();
      }
    });
    _setupRealTimeUpdates();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _setupRealTimeUpdates() {
    // Refresh data every 60 seconds for real-time updates (reduced frequency to prevent rebuild loops)
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (mounted) {
        // Only reload if user is on this screen to prevent unnecessary updates
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _loadAnalyticsData();
          }
        });
      }
    });
  }

  void _loadAnalyticsData() {
    // Load all necessary data for analytics
    context.read<RepairTicketProvider>().loadTickets();
    context.read<CustomerProvider>().loadCustomers();
    context.read<PartProvider>().loadParts();
    context.read<DeviceProvider>().loadDevices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: DropdownButton<String>(
              value: _selectedPeriod,
              underline: const SizedBox.shrink(),
              items:
                  ['Today', 'This Week', 'This Month', 'This Year', 'All Time']
                      .map(
                        (period) => DropdownMenuItem(
                          value: period,
                          child: Text(period),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPeriod = value!;
                });
              },
            ),
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (!authProvider.hasPermission(Permission.viewReports)) {
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
                    'You do not have permission to view analytics.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Key Metrics Row
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Total Tickets',
                        _getTotalTickets(),
                        Icons.confirmation_number,
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetricCard(
                        'Active Customers',
                        _getActiveCustomers(),
                        Icons.people,
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetricCard(
                        'Parts in Stock',
                        _getPartsInStock(),
                        Icons.inventory,
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetricCard(
                        'Devices Managed',
                        _getTotalDevices(),
                        Icons.devices,
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Ticket Status Chart
                Row(
                  children: [
                    Expanded(flex: 2, child: _buildTicketStatusChart()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildRecentActivity()),
                  ],
                ),

                const SizedBox(height: 24),

                // Revenue and Parts Charts
                Row(
                  children: [
                    Expanded(child: _buildRevenueChart()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildLowStockAlert()),
                  ],
                ),

                const SizedBox(height: 24),

                // Device Types Chart
                _buildDeviceTypesChart(),

                const SizedBox(height: 32),

                // Real-Time Analytics Section
                Text(
                  'Real-Time Business Intelligence',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Revenue Trend Graph
                _buildRevenueTrendChart(),

                const SizedBox(height: 24),

                // Performance Charts Row
                Row(
                  children: [
                    Expanded(child: _buildTechnicianPerformanceChart()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildRepairTimeAnalysisChart()),
                  ],
                ),

                const SizedBox(height: 24),

                // Customer Analytics
                _buildCustomerAnalyticsChart(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _selectedPeriod,
                    style: TextStyle(color: color, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketStatusChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ticket Status Distribution',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            Consumer<RepairTicketProvider>(
              builder: (context, ticketProvider, _) {
                final statusCounts = _getTicketStatusCounts(
                  ticketProvider.tickets,
                );
                return Column(
                  children: statusCounts.entries.map((entry) {
                    final total = statusCounts.values.fold(
                      0,
                      (sum, count) => sum + count,
                    );
                    final percentage = total > 0
                        ? (entry.value / total * 100).round()
                        : 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getStatusColor(entry.key),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(entry.key)),
                          Text('${entry.value} ($percentage%)'),
                        ],
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
  }

  Widget _buildRecentActivity() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: Colors.blue, size: 8),
                      SizedBox(width: 4),
                      Text(
                        'Live',
                        style: TextStyle(color: Colors.blue, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<ActivityLog>>(
              future: ActivityService().getRecentActivities(limit: 5),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  return _buildRealTimeActivityFallback();
                }

                final activities = snapshot.data!;
                return Column(
                  children: [
                    ...activities.map((activity) {
                      return _buildRealTimeActivityItem(activity);
                    }).toList(),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showFullActivityLog(),
                        icon: const Icon(Icons.list_alt, size: 18),
                        label: const Text('View Full Activity Log'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealTimeActivityItem(ActivityLog activity) {
    IconData icon;
    const color = Color(0xFF757575); // Neutral grey for all activities
    String title;
    String subtitle;
    
    switch (activity.activityType) {
      case ActivityType.create:
        icon = Icons.add_circle;
        title = 'Created ${_getEntityDisplayName(activity.entityType)}';
        break;
      case ActivityType.update:
        icon = Icons.edit;
        title = 'Updated ${_getEntityDisplayName(activity.entityType)}';
        break;
      case ActivityType.delete:
        icon = Icons.delete;
        title = 'Deleted ${_getEntityDisplayName(activity.entityType)}';
        break;
      case ActivityType.login:
        icon = Icons.login;
        title = 'User Login';
        break;
      case ActivityType.logout:
        icon = Icons.logout;
        title = 'User Logout';
        break;
      default:
        icon = Icons.info;
        title = _getActivityDisplayName(activity.activityType);
    }

    subtitle = '${activity.username} • ${_formatTimeAgo(activity.timestamp)}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealTimeActivityFallback() {
    return Consumer4<
      RepairTicketProvider,
      CustomerProvider,
      DeviceProvider,
      PartProvider
    >(
      builder:
          (
            context,
            ticketProvider,
            customerProvider,
            deviceProvider,
            partProvider,
            _,
          ) {
            final recentActivities = <Map<String, dynamic>>[];

            // Get recent tickets
            final recentTickets =
                ticketProvider.tickets
                    .where(
                      (t) =>
                          DateTime.now().difference(t.createdAt).inHours < 24,
                    )
                    .toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            for (final ticket in recentTickets.take(2)) {
              recentActivities.add({
                'title': ticket.status == RepairStatus.completed
                    ? 'Ticket completed'
                    : 'New ticket created',
                'subtitle': ticket.title,
                'icon': ticket.status == RepairStatus.completed
                    ? Icons.check_circle
                    : Icons.add_circle,
                'color': ticket.status == RepairStatus.completed
                    ? Colors.green
                    : Colors.blue,
                'time': ticket.createdAt,
              });
            }

            // Get recent customers
            final recentCustomers =
                customerProvider.customers
                    .where(
                      (c) =>
                          DateTime.now().difference(c.createdAt).inHours < 24,
                    )
                    .toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            for (final customer in recentCustomers.take(2)) {
              recentActivities.add({
                'title': 'New customer added',
                'subtitle': '${customer.firstName} ${customer.lastName}',
                'icon': Icons.person_add,
                'color': Colors.teal,
                'time': customer.createdAt,
              });
            }

            // Get recent devices
            final recentDevices =
                deviceProvider.devices
                    .where(
                      (d) =>
                          DateTime.now().difference(d.createdAt).inHours < 24,
                    )
                    .toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            for (final device in recentDevices.take(1)) {
              recentActivities.add({
                'title': 'Device registered',
                'subtitle': '${device.type.displayName} - ${device.brand}',
                'icon': Icons.phone_android,
                'color': Colors.purple,
                'time': device.createdAt,
              });
            }

            // Sort all activities by time
            recentActivities.sort(
              (a, b) =>
                  (b['time'] as DateTime).compareTo(a['time'] as DateTime),
            );

            if (recentActivities.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No recent activity',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }

            return Column(
              children: recentActivities.take(5).map((activity) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        activity['icon'] as IconData,
                        color: activity['color'] as Color,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity['title'] as String,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${activity['subtitle']} • ${_formatTimeAgo(activity['time'] as DateTime)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
    );
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

  Widget _buildRevenueChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            Consumer<RepairTicketProvider>(
              builder: (context, ticketProvider, _) {
                final completedTickets = ticketProvider.tickets
                    .where((ticket) => ticket.status == RepairStatus.completed)
                    .length;
                final totalRevenue =
                    completedTickets * 150.0; // Average repair cost
                return Column(
                  children: [
                    Text(
                      '\$${totalRevenue.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const Text('Total Revenue'),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text(
                              'Avg. Ticket',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '\$150',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text(
                              'Completed',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '$completedTickets',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockAlert() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Low Stock Alerts',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            Consumer<PartProvider>(
              builder: (context, partProvider, _) {
                final lowStockParts = partProvider.parts
                    .where((part) => part.quantityInStock <= part.minimumStock)
                    .toList();

                if (lowStockParts.isEmpty) {
                  return const Column(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 48),
                      SizedBox(height: 8),
                      Text(
                        'All parts in stock',
                        style: TextStyle(color: Colors.green),
                      ),
                    ],
                  );
                }

                return Column(
                  children: lowStockParts.take(5).map((part) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning,
                            color: Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              part.name,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Text(
                            '${part.quantityInStock}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                            ),
                          ),
                        ],
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
  }

  Widget _buildDeviceTypesChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.devices, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Device Types Distribution',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Consumer<DeviceProvider>(
              builder: (context, deviceProvider, _) {
                final deviceTypeCounts = _getDeviceTypeCounts(
                  deviceProvider.devices,
                );
                if (deviceTypeCounts.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'No devices registered yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                return Row(
                  children: [
                    // Pie Chart
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: _getDeviceTypePieChartData(
                              deviceTypeCounts,
                            ),
                            centerSpaceRadius: 50,
                            sectionsSpace: 2,
                          ),
                        ),
                      ),
                    ),
                    // Legend
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: deviceTypeCounts.entries.map((entry) {
                          final total = deviceTypeCounts.values.fold(
                            0,
                            (sum, count) => sum + count,
                          );
                          final percentage = total > 0
                              ? ((entry.value / total) * 100).round()
                              : 0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _getDeviceTypeColor(entry.key),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    entry.key.displayName,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                Text(
                                  '${entry.value} ($percentage%)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Real-Time Revenue Trend Chart
  Widget _buildRevenueTrendChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Revenue Trend Analysis',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: Colors.green, size: 8),
                      SizedBox(width: 4),
                      Text(
                        'Live',
                        style: TextStyle(color: Colors.green, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: Consumer<RepairTicketProvider>(
                builder: (context, ticketProvider, _) {
                  final revenueData = _getRevenueDataPoints(
                    ticketProvider.tickets,
                  );
                  return LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: 1000,
                        verticalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withValues(alpha: 0.2),
                            strokeWidth: 1,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withValues(alpha: 0.2),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              const style = TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              );
                              final months = [
                                'Jan',
                                'Feb',
                                'Mar',
                                'Apr',
                                'May',
                                'Jun',
                              ];
                              if (value.toInt() >= 0 &&
                                  value.toInt() < months.length) {
                                return Text(
                                  months[value.toInt()],
                                  style: style,
                                );
                              }
                              return const Text('', style: style);
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1000,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              return Text(
                                '\$${(value / 1000).toStringAsFixed(0)}k',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              );
                            },
                            reservedSize: 42,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                      minX: 0,
                      maxX: 5,
                      minY: 0,
                      maxY: 8000,
                      lineBarsData: [
                        LineChartBarData(
                          spots: revenueData,
                          isCurved: true,
                          gradient: LinearGradient(
                            colors: [
                              _chartColor1.withValues(alpha: 0.8),
                              _chartColor2.withValues(alpha: 0.8),
                            ],
                          ),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: _chartColor1,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                _chartColor1.withValues(alpha: 0.3),
                                _chartColor1.withValues(alpha: 0.1),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Consumer<RepairTicketProvider>(
              builder: (context, ticketProvider, _) {
                final now = DateTime.now();
                final thisMonth = ticketProvider.tickets
                    .where(
                      (t) =>
                          t.status == RepairStatus.completed &&
                          t.actualCompletion != null &&
                          t.actualCompletion!.year == now.year &&
                          t.actualCompletion!.month == now.month,
                    )
                    .fold<double>(
                      0,
                      (sum, ticket) => sum + _getEstimatedRevenue(ticket),
                    );

                final lastMonth = ticketProvider.tickets
                    .where(
                      (t) =>
                          t.status == RepairStatus.completed &&
                          t.actualCompletion != null &&
                          t.actualCompletion!.year == now.year &&
                          t.actualCompletion!.month == now.month - 1,
                    )
                    .fold<double>(
                      0,
                      (sum, ticket) => sum + _getEstimatedRevenue(ticket),
                    );

                final growth = lastMonth > 0
                    ? ((thisMonth - lastMonth) / lastMonth * 100)
                    : 0;
                final growthSign = growth > 0 ? '+' : '';

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildRevenueMetric(
                      'This Month',
                      '\$${thisMonth.toStringAsFixed(0)}',
                      Colors.green,
                    ),
                    _buildRevenueMetric(
                      'Last Month',
                      '\$${lastMonth.toStringAsFixed(0)}',
                      Colors.blue,
                    ),
                    _buildRevenueMetric(
                      'Growth',
                      '$growthSign${growth.toStringAsFixed(1)}%',
                      growth >= 0 ? Colors.green : Colors.red,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  // Technician Performance Chart
  Widget _buildTechnicianPerformanceChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Technician Performance',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Consumer<RepairTicketProvider>(
                builder: (context, ticketProvider, _) {
                  final performanceData = _getTechnicianPerformanceData(
                    ticketProvider.tickets,
                  );
                  return BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 20,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              const style = TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              );

                              // Get real technician names from current performance data
                              final technicianNames =
                                  _getTechnicianNamesFromData(
                                    ticketProvider.tickets,
                                  );

                              if (value.toInt() >= 0 &&
                                  value.toInt() < technicianNames.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    technicianNames[value.toInt()],
                                    style: style,
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: 5,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: performanceData,
                      gridData: const FlGridData(show: false),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Repair Time Analysis Chart
  Widget _buildRepairTimeAnalysisChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Repair Time Analysis',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Consumer<DeviceProvider>(
                builder: (context, deviceProvider, _) {
                  final repairTimeData = _getRepairTimeData();
                  return LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 2,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withValues(alpha: 0.2),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              const devices = [
                                'Laptop',
                                'Phone',
                                'Tablet',
                                'Desktop',
                              ];
                              if (value.toInt() >= 0 &&
                                  value.toInt() < devices.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    devices[value.toInt()],
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: 2,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              return Text(
                                '${value.toInt()}h',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                      minX: 0,
                      maxX: 3,
                      minY: 0,
                      maxY: 10,
                      lineBarsData: [
                        LineChartBarData(
                          spots: repairTimeData,
                          isCurved: true,
                          color: Colors.orange,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 3,
                                color: Colors.orange,
                                strokeWidth: 1,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Customer Analytics Chart
  Widget _buildCustomerAnalyticsChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'Customer Retention & Satisfaction Analytics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                // Customer Satisfaction Pie Chart
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Customer Satisfaction',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 150,
                        child: PieChart(
                          PieChartData(
                            sections: _getCustomerSatisfactionData(),
                            centerSpaceRadius: 40,
                            sectionsSpace: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                // Repeat Customer Metrics
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Repeat Business',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                      Consumer<CustomerProvider>(
                        builder: (context, customerProvider, _) {
                          final repeatCustomers = _getRepeatCustomerStats(
                            customerProvider.customers,
                          );
                          return Column(
                            children: [
                              _buildCustomerStatCard(
                                'Repeat Customers',
                                '${repeatCustomers['repeat']}',
                                _chartColor1,
                              ),
                              const SizedBox(height: 8),
                              _buildCustomerStatCard(
                                'New Customers',
                                '${repeatCustomers['new']}',
                                _chartColor2,
                              ),
                              const SizedBox(height: 8),
                              _buildCustomerStatCard(
                                'Retention Rate',
                                '${repeatCustomers['retention']}%',
                                _chartColor3,
                              ),
                              const SizedBox(height: 8),
                              _buildCustomerStatCard(
                                'Avg. Lifetime Value',
                                '\$${repeatCustomers['ltv']}',
                                _chartColor4,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getTotalTickets() {
    final ticketProvider = context.read<RepairTicketProvider>();
    return ticketProvider.tickets.length.toString();
  }

  String _getActiveCustomers() {
    final customerProvider = context.read<CustomerProvider>();
    return customerProvider.customers.length.toString();
  }

  String _getPartsInStock() {
    final partProvider = context.read<PartProvider>();
    final totalStock = partProvider.parts.fold<int>(
      0,
      (sum, part) => sum + part.quantityInStock,
    );
    return totalStock.toString();
  }

  String _getTotalDevices() {
    final deviceProvider = context.read<DeviceProvider>();
    return deviceProvider.devices.length.toString();
  }

  Map<String, int> _getTicketStatusCounts(List<RepairTicket> tickets) {
    final counts = <String, int>{};
    for (final ticket in tickets) {
      final statusName = ticket.status.displayName;
      counts[statusName] = (counts[statusName] ?? 0) + 1;
    }
    return counts;
  }

  Map<DeviceType, int> _getDeviceTypeCounts(List<Device> devices) {
    final counts = <DeviceType, int>{};
    for (final device in devices) {
      counts[device.type] = (counts[device.type] ?? 0) + 1;
    }
    return counts;
  }

  // Neutral chart color palette - distinguishable but professional
  static const _chartColor1 = Color(0xFF6B7280); // Slate grey
  static const _chartColor2 = Color(0xFF8B9DC3); // Steel blue
  static const _chartColor3 = Color(0xFF9CA3AF); // Cool grey
  static const _chartColor4 = Color(0xFF94A3B8); // Slate blue
  
  Color _getStatusColor(String status) {
    // Use neutral grey palette for all statuses
    switch (status.toLowerCase()) {
      case 'open':
      case 'pending':
        return _chartColor1;
      case 'in progress':
      case 'working':
        return _chartColor2;
      case 'completed':
      case 'closed':
        return _chartColor3;
      case 'cancelled':
        return _chartColor4;
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  Color _getDeviceTypeColor(DeviceType type) {
    // Use neutral grey palette for all device types
    return const Color(0xFF757575);
  }

  // Data processing methods for real-time charts
  List<FlSpot> _getRevenueDataPoints(List<RepairTicket> tickets) {
    final now = DateTime.now();
    final revenueByMonth = <int, double>{};

    // Initialize last 6 months
    for (int i = 0; i < 6; i++) {
      revenueByMonth[i] = 0;
    }

    // Process actual tickets from the database
    for (final ticket in tickets) {
      if (ticket.status == RepairStatus.completed &&
          ticket.actualCompletion != null) {
        final completionDate = ticket.actualCompletion!;
        final monthsDifference =
            (now.year - completionDate.year) * 12 +
            (now.month - completionDate.month);

        if (monthsDifference >= 0 && monthsDifference < 6) {
          final revenue = _getEstimatedRevenue(ticket);
          revenueByMonth[monthsDifference] =
              (revenueByMonth[monthsDifference] ?? 0) + revenue;
        }
      }
    }

    // Convert to FlSpot format (reverse order for chronological display)
    return List.generate(6, (index) {
      final reversedIndex = 5 - index;
      return FlSpot(index.toDouble(), revenueByMonth[reversedIndex] ?? 0);
    });
  }

  double _getEstimatedRevenue(RepairTicket ticket) {
    // Estimate revenue based on final cost or estimated cost
    if (ticket.finalCost != null && ticket.finalCost! > 0) {
      return ticket.finalCost!;
    }
    if (ticket.estimatedCost != null && ticket.estimatedCost! > 0) {
      return ticket.estimatedCost!;
    }

    // Fallback calculation based on priority and description complexity
    double baseRevenue = 100.0;
    switch (ticket.priority) {
      case Priority.urgent:
        baseRevenue = 300.0;
        break;
      case Priority.high:
        baseRevenue = 200.0;
        break;
      case Priority.medium:
        baseRevenue = 150.0;
        break;
      case Priority.low:
        baseRevenue = 100.0;
        break;
    }

    // Add complexity factor based on description length
    final complexityFactor = (ticket.description.length / 50).clamp(1.0, 3.0);
    return baseRevenue * complexityFactor;
  }

  List<BarChartGroupData> _getTechnicianPerformanceData(
    List<RepairTicket> tickets,
  ) {
    // Get real technician data from tickets with technicianId
    final technicianPerformance = <String, int>{};
    final technicianNames = <String>[];

    // Count tickets by actual technician assignments
    for (final ticket in tickets) {
      if (ticket.technicianId != null &&
          ticket.status == RepairStatus.completed) {
        // For now, use technician ID as name (could be enhanced to lookup real names)
        final techName = ticket.technicianId!.substring(
          0,
          8,
        ); // Use first 8 chars of ID
        technicianPerformance[techName] =
            (technicianPerformance[techName] ?? 0) + 1;

        if (!technicianNames.contains(techName)) {
          technicianNames.add(techName);
        }
      }
    }

    // If no real technician data, show default structure
    if (technicianPerformance.isEmpty) {
      final defaultNames = ['Tech-1', 'Tech-2', 'Tech-3', 'Tech-4'];
      return List.generate(defaultNames.length, (index) {
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: 0,
              color: _getTechnicianColor(index),
              width: 16,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ],
        );
      });
    }

    // Sort technicians by performance
    final sortedTechnicians = technicianPerformance.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Take top 4 technicians
    final topTechnicians = sortedTechnicians.take(4).toList();

    return List.generate(topTechnicians.length, (index) {
      final entry = topTechnicians[index];
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: entry.value.toDouble(),
            color: _getTechnicianColor(index),
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });
  }

  Color _getTechnicianColor(int index) {
    // Neutral chart color palette for technicians
    final colors = [_chartColor1, _chartColor2, _chartColor3, _chartColor4];
    return colors[index % colors.length];
  }

  List<FlSpot> _getRepairTimeData() {
    final deviceProvider = context.read<DeviceProvider>();
    final ticketProvider = context.read<RepairTicketProvider>();

    // Calculate actual repair times by device type
    final deviceTypeRepairTimes = <DeviceType, List<double>>{};

    for (final ticket in ticketProvider.tickets) {
      if (ticket.status == RepairStatus.completed &&
          ticket.actualCompletion != null) {
        // Find the device for this ticket
        final device = deviceProvider.devices.firstWhere(
          (d) => d.id == ticket.deviceId,
          orElse: () => Device(
            id: '',
            customerId: '',
            type: DeviceType.other,
            brand: '',
            model: '',
            serialNumber: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        if (device.id.isNotEmpty) {
          // Calculate repair time in hours
          final repairTime = ticket.actualCompletion!
              .difference(ticket.createdAt)
              .inHours
              .toDouble();
          if (repairTime > 0 && repairTime < 720) {
            // Reasonable range (< 30 days)
            deviceTypeRepairTimes
                .putIfAbsent(device.type, () => [])
                .add(repairTime);
          }
        }
      }
    }

    // Calculate averages for top 4 device types
    final deviceTypes = [
      DeviceType.laptop,
      DeviceType.smartphone,
      DeviceType.tablet,
      DeviceType.desktop,
    ];
    final repairTimeData = <FlSpot>[];

    for (int i = 0; i < deviceTypes.length; i++) {
      final deviceType = deviceTypes[i];
      final times = deviceTypeRepairTimes[deviceType] ?? [];

      double avgTime;
      if (times.isNotEmpty) {
        avgTime = times.reduce((a, b) => a + b) / times.length;
      } else {
        // Fallback estimates if no data
        switch (deviceType) {
          case DeviceType.laptop:
            avgTime = 6;
            break;
          case DeviceType.smartphone:
            avgTime = 3;
            break;
          case DeviceType.tablet:
            avgTime = 4;
            break;
          case DeviceType.desktop:
            avgTime = 8;
            break;
          default:
            avgTime = 5;
        }
      }

      repairTimeData.add(FlSpot(i.toDouble(), avgTime));
    }

    return repairTimeData;
  }

  List<PieChartSectionData> _getCustomerSatisfactionData() {
    final ticketProvider = context.read<RepairTicketProvider>();
    final completedTickets = ticketProvider.tickets
        .where((t) => t.status == RepairStatus.completed)
        .toList();

    // Calculate satisfaction based on completion speed vs estimated time
    int excellent = 0;
    int good = 0;
    int fair = 0;
    int poor = 0;

    for (final ticket in completedTickets) {
      if (ticket.actualCompletion != null &&
          ticket.estimatedCompletion != null) {
        final completedEarly = ticket.actualCompletion!.isBefore(
          ticket.estimatedCompletion!,
        );
        final daysDifference = ticket.actualCompletion!
            .difference(ticket.estimatedCompletion!)
            .inDays
            .abs();

        if (completedEarly) {
          excellent++;
        } else if (daysDifference <= 1) {
          good++;
        } else if (daysDifference <= 3) {
          fair++;
        } else {
          poor++;
        }
      } else {
        // If no completion data, consider based on priority vs time taken
        final daysTaken =
            ticket.actualCompletion?.difference(ticket.createdAt).inDays ?? 0;
        switch (ticket.priority) {
          case Priority.urgent:
            if (daysTaken <= 1) {
              excellent++;
            } else if (daysTaken <= 2) {
              good++;
            } else if (daysTaken <= 3) {
              fair++;
            } else {
              poor++;
            }
            break;
          case Priority.high:
            if (daysTaken <= 2) {
              excellent++;
            } else if (daysTaken <= 4) {
              good++;
            } else if (daysTaken <= 7) {
              fair++;
            } else {
              poor++;
            }
            break;
          case Priority.medium:
            if (daysTaken <= 5) {
              excellent++;
            } else if (daysTaken <= 10) {
              good++;
            } else if (daysTaken <= 14) {
              fair++;
            } else {
              poor++;
            }
            break;
          case Priority.low:
            if (daysTaken <= 10) {
              excellent++;
            } else if (daysTaken <= 20) {
              good++;
            } else if (daysTaken <= 30) {
              fair++;
            } else {
              poor++;
            }
            break;
        }
      }
    }

    final total = excellent + good + fair + poor;

    // If no data, show default distribution
    if (total == 0) {
      return [
        PieChartSectionData(
          color: Colors.grey,
          value: 100,
          title: 'No Data\n100%',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ];
    }

    return [
      if (excellent > 0)
        PieChartSectionData(
          color: _chartColor1,
          value: excellent.toDouble(),
          title: 'Excellent\n${((excellent / total) * 100).round()}%',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      if (good > 0)
        PieChartSectionData(
          color: _chartColor2,
          value: good.toDouble(),
          title: 'Good\n${((good / total) * 100).round()}%',
          radius: 45,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      if (fair > 0)
        PieChartSectionData(
          color: _chartColor3,
          value: fair.toDouble(),
          title: 'Fair\n${((fair / total) * 100).round()}%',
          radius: 40,
          titleStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      if (poor > 0)
        PieChartSectionData(
          color: _chartColor4,
          value: poor.toDouble(),
          title: 'Poor\n${((poor / total) * 100).round()}%',
          radius: 35,
          titleStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
    ];
  }

  Map<String, dynamic> _getRepeatCustomerStats(List<Customer> customers) {
    final now = DateTime.now();
    final sixMonthsAgo = now.subtract(const Duration(days: 180));

    // Simulate repeat customer analysis
    final totalCustomers = customers.length;
    final newCustomers = customers
        .where((c) => c.createdAt.isAfter(sixMonthsAgo))
        .length;
    final repeatCustomers = totalCustomers - newCustomers;

    final retentionRate = totalCustomers > 0
        ? ((repeatCustomers / totalCustomers) * 100).round()
        : 0;
    final avgLifetimeValue =
        (repeatCustomers * 450) + (newCustomers * 200); // Simulate LTV

    return {
      'repeat': repeatCustomers,
      'new': newCustomers,
      'retention': retentionRate,
      'ltv': (avgLifetimeValue / (totalCustomers > 0 ? totalCustomers : 1))
          .round(),
    };
  }

  // Helper methods for display names
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

  String _getActivityDisplayName(ActivityType activityType) {
    switch (activityType) {
      case ActivityType.login:
        return 'Login';
      case ActivityType.logout:
        return 'Logout';
      case ActivityType.create:
        return 'Create';
      case ActivityType.update:
        return 'Update';
      case ActivityType.delete:
        return 'Delete';
      case ActivityType.view:
        return 'View';
      case ActivityType.statusChange:
        return 'Status Change';
      case ActivityType.assignment:
        return 'Assignment';
      case ActivityType.export:
        return 'Export';
      case ActivityType.import:
        return 'Import';
      case ActivityType.backup:
        return 'Backup';
      case ActivityType.restore:
        return 'Restore';
    }
  }

  // Device Types Pie Chart Data
  List<PieChartSectionData> _getDeviceTypePieChartData(
    Map<DeviceType, int> deviceTypeCounts,
  ) {
    final total = deviceTypeCounts.values.fold(0, (sum, count) => sum + count);
    final sections = <PieChartSectionData>[];

    for (final entry in deviceTypeCounts.entries) {
      final percentage = total > 0 ? (entry.value / total * 100) : 0;
      sections.add(
        PieChartSectionData(
          color: _getDeviceTypeColor(entry.key),
          value: entry.value.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return sections;
  }

  List<String> _getTechnicianNamesFromData(List<RepairTicket> tickets) {
    final technicianPerformance = <String, int>{};

    // Count tickets by actual technician assignments
    for (final ticket in tickets) {
      if (ticket.technicianId != null &&
          ticket.status == RepairStatus.completed) {
        final techName = ticket.technicianId!.substring(
          0,
          8,
        ); // Use first 8 chars of ID
        technicianPerformance[techName] =
            (technicianPerformance[techName] ?? 0) + 1;
      }
    }

    // If no real technician data, show default names
    if (technicianPerformance.isEmpty) {
      return ['Tech-1', 'Tech-2', 'Tech-3', 'Tech-4'];
    }

    // Sort technicians by performance and return top 4
    final sortedTechnicians = technicianPerformance.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedTechnicians.take(4).map((e) => e.key).toList();
  }

  void _showFullActivityLog() {
    showDialog(context: context, builder: (context) => FullActivityLogDialog());
  }
}

class FullActivityLogDialog extends StatefulWidget {
  @override
  State<FullActivityLogDialog> createState() => _FullActivityLogDialogState();
}

class _FullActivityLogDialogState extends State<FullActivityLogDialog> {
  final ScrollController _scrollController = ScrollController();
  List<ActivityLog> _activities = [];
  bool _isLoading = true;
  String _filterType = 'All';
  String _filterUser = 'All';
  final List<String> _activityTypes = [
    'All',
    'Create',
    'Update',
    'Delete',
    'Login',
    'Logout',
  ];

  @override
  void initState() {
    super.initState();
    _loadAllActivities();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAllActivities() async {
    setState(() => _isLoading = true);
    try {
      // Try to get all activities, if that fails, get recent activities with higher limit
      List<ActivityLog> activities;
      try {
        activities = await ActivityService().getAllActivities();
        if (activities.isEmpty) {
          // Fallback to recent activities with high limit
          activities = await ActivityService().getRecentActivities(limit: 100);
        }
      } catch (e) {
        // If getAllActivities fails, use getRecentActivities as fallback
        activities = await ActivityService().getRecentActivities(limit: 100);
      }

      setState(() {
        _activities = activities;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading activities: $e'); // Debug print
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading activities: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<ActivityLog> get _filteredActivities {
    return _activities.where((activity) {
      final matchesType =
          _filterType == 'All' ||
          activity.activityType.toString().split('.').last.toLowerCase() ==
              _filterType.toLowerCase();
      final matchesUser =
          _filterUser == 'All' || activity.username == _filterUser;
      return matchesType && matchesUser;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final uniqueUsers = [
      'All',
      ..._activities.map((a) => a.username).toSet().toList(),
    ];

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.list_alt,
                  size: 28,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Full Activity Log',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
            const SizedBox(height: 16),

            // Filters
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _filterType,
                    decoration: const InputDecoration(
                      labelText: 'Activity Type',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: _activityTypes
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _filterType = value!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _filterUser,
                    decoration: const InputDecoration(
                      labelText: 'User',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: uniqueUsers
                        .map(
                          (user) =>
                              DropdownMenuItem(value: user, child: Text(user)),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _filterUser = value!),
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: _loadAllActivities,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Activity count
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Showing ${_filteredActivities.length} of ${_activities.length} activities',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 16),

            // Activity list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredActivities.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No activities found',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your filters',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _filteredActivities.length,
                      itemBuilder: (context, index) {
                        final activity = _filteredActivities[index];
                        return _buildFullActivityItem(activity);
                      },
                    ),
            ),

            // Footer
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Total activities: ${_activities.length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullActivityItem(ActivityLog activity) {
    IconData icon;
    const color = Color(0xFF757575); // Neutral grey for all activities

    switch (activity.activityType) {
      case ActivityType.create:
        icon = Icons.add_circle;
        break;
      case ActivityType.update:
        icon = Icons.edit;
        break;
      case ActivityType.delete:
        icon = Icons.delete;
        break;
      case ActivityType.login:
        icon = Icons.login;
        break;
      case ActivityType.logout:
        icon = Icons.logout;
        break;
      default:
        icon = Icons.info;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          activity.description,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User: ${activity.username} (${activity.userRole.displayName})',
            ),
            Text(
              'Entity: ${activity.entityType.toString().split('.').last} ${activity.entityId != null ? '(ID: ${activity.entityId})' : ''}',
            ),
            Text('Time: ${_formatDateTime(activity.timestamp)}'),
          ],
        ),
        isThreeLine: true,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            activity.activityType.toString().split('.').last.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
