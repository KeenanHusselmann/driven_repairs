import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../models/models.dart';

class PerformanceOverviewScreen extends StatefulWidget {
  const PerformanceOverviewScreen({super.key});

  @override
  State<PerformanceOverviewScreen> createState() =>
      _PerformanceOverviewScreenState();
}

class _PerformanceOverviewScreenState extends State<PerformanceOverviewScreen> {
  // Neutral chart color palette
  static const Color _chartColor1 = Color(0xFF6B7280); // slate grey
  static const Color _chartColor2 = Color(0xFF8B9DC3); // steel blue
  static const Color _chartColor3 = Color(0xFF9CA3AF); // cool grey
  static const Color _chartColor4 = Color(0xFF94A3B8); // slate blue

  bool _isLoading = true;
  Map<String, dynamic>? _metricsData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Future.wait([
        context.read<RepairTicketProvider>().loadTickets(),
        context.read<ServiceRatingProvider>().loadRatings(),
        context.read<TicketResolutionMetricProvider>().loadMetrics(),
        context.read<CustomerProvider>().loadCustomers(),
      ]);

      // Fetch real-time metrics
      final ratingProvider = context.read<ServiceRatingProvider>();
      final metricProvider = context.read<TicketResolutionMetricProvider>();

      final metrics = await Future.wait([
        ratingProvider.getAverageSatisfactionRating(),
        metricProvider.getOnTimeDeliveryRate(),
        metricProvider.getFirstCallResolutionRate(),
        metricProvider.getAverageResourceUtilization(),
      ]);

      setState(() {
        _metricsData = {
          'satisfaction': metrics[0],
          'onTimeRate': metrics[1],
          'fcrRate': metrics[2],
          'utilization': metrics[3],
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Overview'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
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
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            _buildPerformanceMetrics(),
            const SizedBox(height: 32),
            _buildPerformanceTrends(),
            const SizedBox(height: 32),
            _buildPerformanceInsights(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading metrics',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final customerSatisfactionRate = _metricsData?['satisfaction'] ?? 0.0;
    final onTimeDeliveryRate = _metricsData?['onTimeRate'] ?? 0.0;
    final firstCallResolutionRate = _metricsData?['fcrRate'] ?? 0.0;
    final resourceUtilizationRate = _metricsData?['utilization'] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Key Performance Metrics',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadData,
                  tooltip: 'Refresh metrics',
                ),
                FilledButton.icon(
                  onPressed: _showSendFeedbackOptions,
                  icon: const Icon(Icons.email),
                  label: const Text('Send Customer Feedback'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Customer Satisfaction',
                value: customerSatisfactionRate > 0
                    ? '${customerSatisfactionRate.toStringAsFixed(1)}/5.0'
                    : 'No data',
                icon: Icons.star,
                color: const Color(0xFF6B7280), // Neutral slate grey
                progress: customerSatisfactionRate / 5.0,
                description: 'Average customer rating',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                title: 'On-Time Delivery',
                value: '${(onTimeDeliveryRate).toStringAsFixed(1)}%',
                icon: Icons.schedule,
                color: const Color(0xFF8B9DC3), // Neutral steel blue
                progress: onTimeDeliveryRate / 100,
                description: 'Repairs completed on time',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'First-Call Resolution',
                value: '${(firstCallResolutionRate).toStringAsFixed(1)}%',
                icon: Icons.done_all,
                color: const Color(0xFF9CA3AF), // Neutral cool grey
                progress: firstCallResolutionRate / 100,
                description: 'Issues resolved on first attempt',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                title: 'Resource Utilization',
                value: '${(resourceUtilizationRate).toStringAsFixed(1)} hrs/ticket',
                icon: Icons.engineering,
                color: const Color(0xFF94A3B8), // Neutral slate blue
                progress: (resourceUtilizationRate / 10).clamp(0.0, 1.0),
                description: 'Average labor hours per ticket',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required double progress,
    required String description,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceTrends() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Trends',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _buildTrendItem(
              'Customer Satisfaction',
              '+12%',
              'vs last month',
              _chartColor1,
              Icons.trending_up,
            ),
            const Divider(height: 24),
            _buildTrendItem(
              'On-Time Delivery',
              '+8%',
              'vs last month',
              _chartColor2,
              Icons.trending_up,
            ),
            const Divider(height: 24),
            _buildTrendItem(
              'Resolution Time',
              '-15%',
              'faster than last month',
              _chartColor3,
              Icons.trending_down,
            ),
            const Divider(height: 24),
            _buildTrendItem(
              'Resource Utilization',
              '+5%',
              'vs last month',
              _chartColor4,
              Icons.trending_up,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendItem(
    String title,
    String change,
    String period,
    Color color,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                period,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            change,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceInsights() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Insights',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _buildInsightItem(
              Icons.lightbulb_outline,
              'Peak Performance Hours',
              'Best performance observed between 10 AM - 2 PM',
              _chartColor1,
            ),
            const SizedBox(height: 12),
            _buildInsightItem(
              Icons.warning_amber_outlined,
              'Improvement Opportunity',
              'Weekend response times are 23% slower than weekdays',
              _chartColor2,
            ),
            const SizedBox(height: 12),
            _buildInsightItem(
              Icons.celebration_outlined,
              'Achievement Unlock',
              'Customer satisfaction reached highest level this quarter!',
              _chartColor3,
            ),
            const SizedBox(height: 12),
            _buildInsightItem(
              Icons.analytics_outlined,
              'Trend Analysis',
              'Repair completion rate improved by 18% over last 3 months',
              _chartColor4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Email feedback functionality
  void _showSendFeedbackOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Customer Feedback Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select customers to send feedback requests to:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            const Text(
              'This will open your email client with a pre-formatted feedback request email.',
            ),
            const SizedBox(height: 16),
            Consumer2<CustomerProvider, RepairTicketProvider>(
              builder: (context, customerProvider, ticketProvider, _) {
                final completedTickets = ticketProvider.tickets
                    .where((t) => t.status == RepairStatus.completed)
                    .toList();

                if (completedTickets.isEmpty) {
                  return const Text(
                    'No completed tickets found.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${completedTickets.length} completed ticket(s) found',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _sendBatchFeedbackEmails(
                          completedTickets,
                          customerProvider,
                        );
                      },
                      icon: const Icon(Icons.email),
                      label: const Text('Send to All Customers'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showCustomerSelectionDialog();
            },
            child: const Text('Select Customers'),
          ),
        ],
      ),
    );
  }

  void _showCustomerSelectionDialog() {
    Customer? selectedCustomer;
    RepairTicket? selectedTicket;
    
    showDialog(
      context: context,
      builder: (context) => Consumer3<CustomerProvider, RepairTicketProvider, DeviceProvider>(
        builder: (context, customerProvider, ticketProvider, deviceProvider, _) {
          return StatefulBuilder(
            builder: (context, setState) {
              // Filter open tickets for selected customer
              final customerTickets = selectedCustomer != null
                  ? ticketProvider.tickets
                      .where((t) =>
                          t.customerId == selectedCustomer!.id &&
                          (t.status == RepairStatus.pending ||
                              t.status == RepairStatus.inProgress ||
                              t.status == RepairStatus.completed))
                      .toList()
                  : <RepairTicket>[];
              
              // Get device information if ticket is selected
              Device? ticketDevice;
              if (selectedTicket != null) {
                try {
                  ticketDevice = deviceProvider.devices.firstWhere(
                    (d) => d.id == selectedTicket!.deviceId,
                  );
                } catch (e) {
                  ticketDevice = null;
                }
              }

              return AlertDialog(
                title: const Text('Send Customer Feedback'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Customer:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<Customer>(
                            isExpanded: true,
                            value: selectedCustomer,
                            hint: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('Choose a customer...'),
                            ),
                            items: customerProvider.customers.map((customer) {
                              return DropdownMenuItem(
                                value: customer,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        child: Text(
                                          customer.firstName.isNotEmpty
                                              ? customer.firstName[0]
                                                  .toUpperCase()
                                              : '?',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              customer.fullName,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w500),
                                            ),
                                            Text(
                                              customer.email,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (customer) {
                              setState(() {
                                selectedCustomer = customer;
                                selectedTicket =
                                    null; // Reset ticket when customer changes
                              });
                              
                              // Auto-load customer's devices when customer is selected
                              if (customer != null) {
                                deviceProvider.loadDevices(customerId: customer.id);
                              }
                            },
                          ),
                        ),
                      ),
                      if (selectedCustomer != null) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Select Ticket (Optional):',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (customerTickets.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'No open tickets for this customer',
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<RepairTicket>(
                                isExpanded: true,
                                value: selectedTicket,
                                hint: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('Choose a ticket (optional)...'),
                                ),
                                items: [
                                  const DropdownMenuItem<RepairTicket>(
                                    value: null,
                                    child: Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 12),
                                      child: Text('General Feedback (No Ticket)'),
                                    ),
                                  ),
                                  ...customerTickets.map((ticket) {
                                    return DropdownMenuItem(
                                      value: ticket,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        child: Text(
                                          'Ticket #${ticket.id} - ${ticket.title}',
                                          style: const TextStyle(fontSize: 14),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                                onChanged: (ticket) {
                                  setState(() {
                                    selectedTicket = ticket;
                                  });
                                },
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: selectedCustomer == null || customerTickets.isEmpty
                        ? null
                        : () {
                            Navigator.of(context).pop();
                            _sendFeedbackEmailToCustomer(
                              selectedCustomer!,
                              selectedTicket,
                              ticketDevice,
                            );
                          },
                    child: const Text('Generate Link'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _sendBatchFeedbackEmails(
    List<RepairTicket> tickets,
    CustomerProvider customerProvider,
  ) async {
    final deviceProvider = context.read<DeviceProvider>();
    
    for (final ticket in tickets) {
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

      if (customer.id.isNotEmpty) {
        // Try to get device information
        Device? device;
        try {
          device = deviceProvider.devices.firstWhere(
            (d) => d.id == ticket.deviceId,
          );
        } catch (e) {
          device = null;
        }
        
        await _sendFeedbackEmailToCustomer(customer, ticket, device);
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  Future<void> _sendFeedbackEmailToCustomer(
    Customer customer, [
    RepairTicket? ticket,
    Device? device,
  ]) async {
    // Get technician name if ticket has one
    String? technicianName;
    if (ticket?.technicianId != null && mounted) {
      final techProvider = context.read<TechnicianProvider>();
      final technician = techProvider.technicians.firstWhere(
        (t) => t.id == ticket!.technicianId,
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

    // Build feedback form URL with enhanced parameters (VS Code Dev Tunnel - Public Access)
    final baseUrl = 'https://lkq8fgjg-8080.eun1.devtunnels.ms/feedback_form.html?';
    final params = <String, String>{
      'ticket': ticket?.id ?? '',
      'customer': customer.id,
      'name': customer.fullName,
      'email': customer.email,
      'phone': customer.phone,
      'date': ticket != null ? DateFormat('MMMM dd, yyyy').format(ticket.createdAt) : 'N/A',
      'technician': technicianName ?? '',
      if (ticket != null) ...{
        'ticketTitle': ticket.title,
        'ticketStatus': ticket.status.displayName,
        'ticketPriority': ticket.priority.displayName,
      },
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
        ticketId: ticket?.id,
        customerId: customer.id,
        expiresAt: DateTime.now().add(const Duration(days: 90)), // Link expires in 90 days
      );

      if (shortUrl != null) {
        feedbackUrl = 'https://lkq8fgjg-8080.eun1.devtunnels.ms/s/${shortUrl.shortCode}';
        debugPrint('Created short URL: $feedbackUrl -> $fullUrl');
      } else {
        debugPrint('Failed to create short URL, using full URL');
      }
    }

    final subject = Uri.encodeComponent('🔧 Share Your Experience with Driven Repairs');
    
    // Create a simple body that works with Windows mailto limitations
    final bodyText = 'Hi ${customer.firstName},\n\n'
        'Thank you for choosing Driven Repairs!\n\n'
        'Please share your feedback by clicking the link below:\n'
        '[PASTE LINK HERE]\n\n'
        'Thank you,\n'
        'Driven Repairs Team';
    
    final body = Uri.encodeComponent(bodyText);

    // Show dialog with copyable feedback link
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
                  'Send this link to ${customer.fullName}:',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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

    final emailUrl = 'mailto:${customer.email}'
        '?subject=$subject'
        '&body=$body'
        '&cc=keenan.husselmann39@gmail.com';

    try {
      // This will open the default email client on Windows
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Open Email Client'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('To: ${customer.email}'),
                const SizedBox(height: 8),
                Text('CC: keenan.husselmann39@gmail.com'),
                const SizedBox(height: 16),
                const Text(
                  'Your default email client will open with a pre-filled feedback request email.',
                ),
                const SizedBox(height: 16),
                SelectableText(
                  emailUrl,
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  // Launch email URL
                  await _launchEmail(emailUrl, customer);
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open Email Client'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening email client: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _launchEmail(String emailUrl, Customer customer) async {
    try {
      // On Windows, use PowerShell Start-Process for better mailto URL handling
      final result = await Process.run(
        'powershell',
        ['-Command', 'Start-Process', '"$emailUrl"'],
        runInShell: true,
      );

      if (result.exitCode != 0) {
        throw Exception('Failed to open email client: ${result.stderr}');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Email client opened for ${customer.fullName}',
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
            content: Text('Could not open email client: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
