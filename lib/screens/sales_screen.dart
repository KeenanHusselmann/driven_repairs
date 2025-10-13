import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/repair_ticket_provider.dart';
import '../providers/auth_provider.dart';
import '../models/repair_ticket.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen>
    with TickerProviderStateMixin {
  // Neutral chart color palette
  static const Color _chartColor1 = Color(0xFF6B7280); // slate grey
  static const Color _chartColor2 = Color(0xFF8B9DC3); // steel blue
  static const Color _chartColor3 = Color(0xFF9CA3AF); // cool grey
  static const Color _chartColor4 = Color(0xFF94A3B8); // slate blue

  late TabController _tabController;
  String _selectedPeriod = 'This Month';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RepairTicketProvider>(context, listen: false).loadTickets();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (!authProvider.canViewSales()) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Sales'),
              backgroundColor: Theme.of(context).colorScheme.surface,
            ),
            body: const Center(
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
                    'You do not have permission to view sales data.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Sales & Accounting'),
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            actions: [
              _buildPeriodSelector(),
              const SizedBox(width: 16),
              _buildExportButton(),
              const SizedBox(width: 16),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: const [
                Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
                Tab(icon: Icon(Icons.account_balance), text: 'P&L'),
                Tab(icon: Icon(Icons.book), text: 'Bookkeeping'),
                Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
                Tab(icon: Icon(Icons.build), text: 'Tools'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildProfitLossTab(),
              _buildBookkeepingTab(),
              _buildAnalyticsTab(),
              _buildToolsTab(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeriodSelector() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.date_range),
      onSelected: (value) {
        setState(() {
          _selectedPeriod = value;
          _updateDateRange(value);
        });
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'Today', child: Text('Today')),
        const PopupMenuItem(value: 'This Week', child: Text('This Week')),
        const PopupMenuItem(value: 'This Month', child: Text('This Month')),
        const PopupMenuItem(
          value: 'Last 3 Months',
          child: Text('Last 3 Months'),
        ),
        const PopupMenuItem(value: 'This Year', child: Text('This Year')),
        const PopupMenuItem(value: 'Custom', child: Text('Custom Range')),
      ],
    );
  }

  Widget _buildExportButton() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.download),
      onSelected: (value) {
        _exportData(value);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'pdf', child: Text('Export PDF')),
        const PopupMenuItem(value: 'excel', child: Text('Export Excel')),
        const PopupMenuItem(value: 'csv', child: Text('Export CSV')),
      ],
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSalesKPIs(),
          const SizedBox(height: 24),
          _buildRevenueChart(),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildTopServices()),
              const SizedBox(width: 16),
              Expanded(child: _buildRecentTransactions()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSalesKPIs() {
    return Consumer<RepairTicketProvider>(
      builder: (context, ticketProvider, _) {
        final tickets = _getFilteredTickets(ticketProvider.tickets);
        final totalRevenue = _calculateTotalRevenue(tickets);
        final totalCost = _calculateTotalCost(tickets);
        final profit = totalRevenue - totalCost;
        final profitMargin = totalRevenue > 0
            ? (profit / totalRevenue) * 100
            : 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sales Overview - $_selectedPeriod',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildKPICard(
                    'Total Revenue',
                    '\$${totalRevenue.toStringAsFixed(2)}',
                    Icons.attach_money,
                    _chartColor1,
                    '+12%',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildKPICard(
                    'Total Profit',
                    '\$${profit.toStringAsFixed(2)}',
                    Icons.trending_up,
                    _chartColor2,
                    '+8%',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildKPICard(
                    'Profit Margin',
                    '${profitMargin.toStringAsFixed(1)}%',
                    Icons.percent,
                    _chartColor3,
                    '+2%',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildKPICard(
                    'Transactions',
                    '${tickets.length}',
                    Icons.receipt,
                    _chartColor4,
                    '+15%',
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildKPICard(
    String title,
    String value,
    IconData icon,
    Color color,
    String trend,
  ) {
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
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                  'Revenue Trend',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                ToggleButtons(
                  isSelected: const [true, false, false],
                  onPressed: (index) {},
                  borderRadius: BorderRadius.circular(8),
                  textStyle: const TextStyle(fontSize: 12),
                  constraints: const BoxConstraints(
                    minWidth: 60,
                    minHeight: 32,
                  ),
                  children: const [
                    Text('Daily'),
                    Text('Weekly'),
                    Text('Monthly'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text('\$${value.toInt()}');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final days = [
                            'Mon',
                            'Tue',
                            'Wed',
                            'Thu',
                            'Fri',
                            'Sat',
                            'Sun',
                          ];
                          return Text(days[value.toInt() % days.length]);
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _generateRevenueSpots(),
                      isCurved: true,
                      color: _chartColor1,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: _chartColor1.withValues(alpha: 0.1),
                      ),
                    ),
                    LineChartBarData(
                      spots: _generateProfitSpots(),
                      isCurved: true,
                      color: _chartColor2,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: _chartColor2.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Revenue', _chartColor1),
                const SizedBox(width: 24),
                _buildLegendItem('Profit', _chartColor2),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  Widget _buildTopServices() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Services',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _buildServiceItem('Screen Repair', '\$2,450', '28%', _chartColor1),
            _buildServiceItem(
              'Battery Replacement',
              '\$1,890',
              '21%',
              _chartColor2,
            ),
            _buildServiceItem('Water Damage', '\$1,560', '18%', _chartColor3),
            _buildServiceItem('Charging Port', '\$1,230', '14%', _chartColor4),
            _buildServiceItem('Other Services', '\$1,670', '19%', Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceItem(
    String service,
    String amount,
    String percentage,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              service,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                percentage,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Consumer<RepairTicketProvider>(
      builder: (context, ticketProvider, _) {
        final recentTickets = ticketProvider.tickets
            .where(
              (t) => t.status == RepairStatus.completed && t.finalCost != null,
            )
            .take(5)
            .toList();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Recent Transactions',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    TextButton(onPressed: () {}, child: const Text('View All')),
                  ],
                ),
                const SizedBox(height: 16),
                ...recentTickets.map((ticket) => _buildTransactionItem(ticket)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionItem(RepairTicket ticket) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  'Ticket #${ticket.id}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${ticket.finalCost?.toStringAsFixed(2) ?? '0.00'}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitLossTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profit & Loss Statement',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          _buildPLStatement(),
          const SizedBox(height: 24),
          _buildPLChart(),
        ],
      ),
    );
  }

  Widget _buildPLStatement() {
    return Consumer<RepairTicketProvider>(
      builder: (context, ticketProvider, _) {
        final tickets = _getFilteredTickets(ticketProvider.tickets);
        final revenue = _calculateTotalRevenue(tickets);
        final cogs = _calculateCOGS(tickets);
        final grossProfit = revenue - cogs;
        final expenses = _calculateExpenses();
        final netProfit = grossProfit - expenses;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildPLRow('REVENUE', '', true),
                _buildPLRow(
                  'Service Revenue',
                  '\$${revenue.toStringAsFixed(2)}',
                  false,
                ),
                _buildPLRow(
                  'Total Revenue',
                  '\$${revenue.toStringAsFixed(2)}',
                  false,
                  isBold: true,
                ),
                const Divider(height: 32),

                _buildPLRow('COST OF GOODS SOLD', '', true),
                _buildPLRow(
                  'Parts & Materials',
                  '\$${cogs.toStringAsFixed(2)}',
                  false,
                ),
                _buildPLRow(
                  'Labor Costs',
                  '\$${(cogs * 0.3).toStringAsFixed(2)}',
                  false,
                ),
                _buildPLRow(
                  'Total COGS',
                  '\$${(cogs * 1.3).toStringAsFixed(2)}',
                  false,
                  isBold: true,
                ),
                const Divider(height: 32),

                _buildPLRow(
                  'GROSS PROFIT',
                  '\$${(grossProfit - cogs * 0.3).toStringAsFixed(2)}',
                  false,
                  isBold: true,
                  color: Colors.green,
                ),
                const Divider(height: 32),

                _buildPLRow('OPERATING EXPENSES', '', true),
                _buildPLRow(
                  'Rent & Utilities',
                  '\$${(expenses * 0.4).toStringAsFixed(2)}',
                  false,
                ),
                _buildPLRow(
                  'Marketing',
                  '\$${(expenses * 0.15).toStringAsFixed(2)}',
                  false,
                ),
                _buildPLRow(
                  'Insurance',
                  '\$${(expenses * 0.1).toStringAsFixed(2)}',
                  false,
                ),
                _buildPLRow(
                  'Equipment',
                  '\$${(expenses * 0.2).toStringAsFixed(2)}',
                  false,
                ),
                _buildPLRow(
                  'Other Expenses',
                  '\$${(expenses * 0.15).toStringAsFixed(2)}',
                  false,
                ),
                _buildPLRow(
                  'Total Expenses',
                  '\$${expenses.toStringAsFixed(2)}',
                  false,
                  isBold: true,
                ),
                const Divider(height: 32),

                _buildPLRow(
                  'NET PROFIT',
                  '\$${netProfit.toStringAsFixed(2)}',
                  false,
                  isBold: true,
                  color: netProfit >= 0 ? Colors.green : Colors.red,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPLRow(
    String label,
    String amount,
    bool isHeader, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isHeader || isBold
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: isHeader
                    ? Colors.blue
                    : (color ?? Theme.of(context).colorScheme.onSurface),
                fontSize: isHeader ? 14 : 13,
              ),
            ),
          ),
          if (amount.isNotEmpty)
            Text(
              amount,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: color ?? Theme.of(context).colorScheme.onSurface,
                fontSize: 13,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPLChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profit & Loss Breakdown',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: 65,
                      title: 'Revenue\n65%',
                      color: Colors.green,
                      radius: 60,
                    ),
                    PieChartSectionData(
                      value: 25,
                      title: 'COGS\n25%',
                      color: Colors.orange,
                      radius: 60,
                    ),
                    PieChartSectionData(
                      value: 10,
                      title: 'Expenses\n10%',
                      color: Colors.red,
                      radius: 60,
                    ),
                  ],
                  centerSpaceRadius: 80,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookkeepingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bookkeeping & Accounts',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildAccountsReceivable()),
              const SizedBox(width: 16),
              Expanded(child: _buildAccountsPayable()),
            ],
          ),
          const SizedBox(height: 24),
          _buildGeneralLedger(),
        ],
      ),
    );
  }

  Widget _buildAccountsReceivable() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Accounts Receivable',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildAccountItem(
              'Outstanding Invoices',
              '\$3,450.00',
              Colors.orange,
            ),
            _buildAccountItem('Overdue (30+ days)', '\$890.00', Colors.red),
            _buildAccountItem(
              'Current (0-30 days)',
              '\$2,560.00',
              Colors.green,
            ),
            const Divider(),
            _buildAccountItem(
              'Total A/R',
              '\$3,450.00',
              Colors.blue,
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountsPayable() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Accounts Payable',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildAccountItem('Outstanding Bills', '\$1,230.00', Colors.orange),
            _buildAccountItem('Due This Week', '\$450.00', Colors.red),
            _buildAccountItem('Due This Month', '\$780.00', Colors.yellow),
            const Divider(),
            _buildAccountItem(
              'Total A/P',
              '\$1,230.00',
              Colors.blue,
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountItem(
    String label,
    String amount,
    Color color, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralLedger() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'General Ledger - Recent Entries',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showAddEntryDialog(),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Entry'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(3),
                2: FlexColumnWidth(2),
                3: FlexColumnWidth(2),
                4: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Date',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Description',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Account',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Debit',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Credit',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                ..._generateLedgerEntries().map(
                  (entry) => TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(entry['date']!),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(entry['description']!),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(entry['account']!),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(entry['debit']!),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(entry['credit']!),
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

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sales Analytics',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildSalesMetrics()),
              const SizedBox(width: 16),
              Expanded(child: _buildCustomerMetrics()),
            ],
          ),
          const SizedBox(height: 24),
          _buildSalesTrendChart(),
        ],
      ),
    );
  }

  Widget _buildSalesMetrics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sales Metrics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              'Average Order Value',
              '\$125.50',
              '+8%',
              Colors.green,
            ),
            _buildMetricRow('Conversion Rate', '68%', '+12%', Colors.green),
            _buildMetricRow(
              'Customer Acquisition Cost',
              '\$45.20',
              '-5%',
              Colors.green,
            ),
            _buildMetricRow(
              'Customer Lifetime Value',
              '\$890.00',
              '+15%',
              Colors.green,
            ),
            _buildMetricRow('Return Customer Rate', '42%', '+3%', Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerMetrics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Insights',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            _buildMetricRow('New Customers', '23', '+18%', Colors.green),
            _buildMetricRow('Returning Customers', '45', '+12%', Colors.green),
            _buildMetricRow('Churn Rate', '5.2%', '-8%', Colors.green),
            _buildMetricRow(
              'Satisfaction Score',
              '4.6/5',
              '+0.3',
              Colors.green,
            ),
            _buildMetricRow('Referral Rate', '28%', '+5%', Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(
    String label,
    String value,
    String change,
    Color changeColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                change,
                style: TextStyle(
                  color: changeColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSalesTrendChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sales Trend Analysis',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 5000,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text('\$${(value / 1000).toInt()}K');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final months = [
                            'Jan',
                            'Feb',
                            'Mar',
                            'Apr',
                            'May',
                            'Jun',
                          ];
                          return Text(months[value.toInt() % months.length]);
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _generateBarData(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Financial Tools',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildToolCard(
                'Invoice Generator',
                Icons.receipt,
                () => _showInvoiceGenerator(),
              ),
              _buildToolCard(
                'Tax Calculator',
                Icons.calculate,
                () => _showTaxCalculator(),
              ),
              _buildToolCard(
                'Cash Flow',
                Icons.trending_up,
                () => _showCashFlowTool(),
              ),
              _buildToolCard(
                'Budget Planner',
                Icons.savings,
                () => _showBudgetPlanner(),
              ),
              _buildToolCard(
                'ROI Calculator',
                Icons.account_balance,
                () => _showROICalculator(),
              ),
              _buildToolCard(
                'Expense Tracker',
                Icons.money_off,
                () => _showExpenseTracker(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard(String title, IconData icon, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.blue, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods
  void _updateDateRange(String period) {
    final now = DateTime.now();
    switch (period) {
      case 'Today':
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = now;
        break;
      case 'This Week':
        _startDate = now.subtract(Duration(days: now.weekday - 1));
        _endDate = now;
        break;
      case 'This Month':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
        break;
      case 'Last 3 Months':
        _startDate = DateTime(now.year, now.month - 3, now.day);
        _endDate = now;
        break;
      case 'This Year':
        _startDate = DateTime(now.year, 1, 1);
        _endDate = now;
        break;
      case 'Custom':
        _showDateRangePicker();
        break;
    }
  }

  List<RepairTicket> _getFilteredTickets(List<RepairTicket> tickets) {
    return tickets
        .where(
          (ticket) =>
              ticket.createdAt.isAfter(_startDate) &&
              ticket.createdAt.isBefore(_endDate.add(const Duration(days: 1))),
        )
        .toList();
  }

  double _calculateTotalRevenue(List<RepairTicket> tickets) {
    return tickets
        .where((t) => t.status == RepairStatus.completed && t.finalCost != null)
        .map((t) => t.finalCost!)
        .fold(0.0, (sum, cost) => sum + cost);
  }

  double _calculateTotalCost(List<RepairTicket> tickets) {
    return tickets
        .where(
          (t) => t.status == RepairStatus.completed && t.estimatedCost != null,
        )
        .map((t) => t.estimatedCost! * 0.6) // Assume 60% cost ratio
        .fold(0.0, (sum, cost) => sum + cost);
  }

  double _calculateCOGS(List<RepairTicket> tickets) {
    return _calculateTotalCost(tickets);
  }

  double _calculateExpenses() {
    return 2500.0; // Fixed monthly expenses for demo
  }

  List<FlSpot> _generateRevenueSpots() {
    return [
      const FlSpot(0, 1200),
      const FlSpot(1, 1800),
      const FlSpot(2, 1500),
      const FlSpot(3, 2200),
      const FlSpot(4, 1900),
      const FlSpot(5, 2500),
      const FlSpot(6, 2100),
    ];
  }

  List<FlSpot> _generateProfitSpots() {
    return [
      const FlSpot(0, 800),
      const FlSpot(1, 1200),
      const FlSpot(2, 900),
      const FlSpot(3, 1500),
      const FlSpot(4, 1300),
      const FlSpot(5, 1800),
      const FlSpot(6, 1400),
    ];
  }

  List<BarChartGroupData> _generateBarData() {
    return [
      BarChartGroupData(
        x: 0,
        barRods: [BarChartRodData(toY: 3200, color: Colors.blue)],
      ),
      BarChartGroupData(
        x: 1,
        barRods: [BarChartRodData(toY: 3800, color: Colors.blue)],
      ),
      BarChartGroupData(
        x: 2,
        barRods: [BarChartRodData(toY: 3500, color: Colors.blue)],
      ),
      BarChartGroupData(
        x: 3,
        barRods: [BarChartRodData(toY: 4200, color: Colors.blue)],
      ),
      BarChartGroupData(
        x: 4,
        barRods: [BarChartRodData(toY: 4600, color: Colors.blue)],
      ),
      BarChartGroupData(
        x: 5,
        barRods: [BarChartRodData(toY: 4100, color: Colors.blue)],
      ),
    ];
  }

  List<Map<String, String>> _generateLedgerEntries() {
    return [
      {
        'date': '2024-10-12',
        'description': 'Service Revenue - Screen Repair',
        'account': 'Revenue',
        'debit': '',
        'credit': '\$150.00',
      },
      {
        'date': '2024-10-12',
        'description': 'Parts Purchase - iPhone Screen',
        'account': 'COGS',
        'debit': '\$80.00',
        'credit': '',
      },
      {
        'date': '2024-10-11',
        'description': 'Rent Payment',
        'account': 'Expenses',
        'debit': '\$1,200.00',
        'credit': '',
      },
      {
        'date': '2024-10-11',
        'description': 'Customer Payment',
        'account': 'Cash',
        'debit': '\$275.00',
        'credit': '',
      },
    ];
  }

  void _exportData(String format) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Exporting data as $format...')));
  }

  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedPeriod = 'Custom';
      });
    }
  }

  void _showAddEntryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Ledger Entry'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: 'Description')),
            SizedBox(height: 16),
            TextField(decoration: InputDecoration(labelText: 'Account')),
            SizedBox(height: 16),
            TextField(decoration: InputDecoration(labelText: 'Amount')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Add Entry'),
          ),
        ],
      ),
    );
  }

  void _showInvoiceGenerator() {
    showDialog(
      context: context,
      builder: (context) => _InvoiceGeneratorDialog(),
    );
  }

  void _showTaxCalculator() {
    showDialog(context: context, builder: (context) => _TaxCalculatorDialog());
  }

  void _showCashFlowTool() {
    showDialog(context: context, builder: (context) => _CashFlowDialog());
  }

  void _showBudgetPlanner() {
    showDialog(context: context, builder: (context) => _BudgetPlannerDialog());
  }

  void _showROICalculator() {
    showDialog(context: context, builder: (context) => _ROICalculatorDialog());
  }

  void _showExpenseTracker() {
    showDialog(context: context, builder: (context) => _ExpenseTrackerDialog());
  }
}

// Invoice Generator Dialog
class _InvoiceGeneratorDialog extends StatefulWidget {
  @override
  _InvoiceGeneratorDialogState createState() => _InvoiceGeneratorDialogState();
}

class _InvoiceGeneratorDialogState extends State<_InvoiceGeneratorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _itemDescController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final List<Map<String, dynamic>> _items = [];
  double _taxRate = 8.5;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Invoice Generator',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer Information',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _customerNameController,
                        decoration: const InputDecoration(
                          labelText: 'Customer Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value?.isEmpty == true ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _customerEmailController,
                        decoration: const InputDecoration(
                          labelText: 'Customer Email',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value?.isEmpty == true ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Items',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _itemDescController,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _quantityController,
                              decoration: const InputDecoration(
                                labelText: 'Qty',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              decoration: const InputDecoration(
                                labelText: 'Price',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _addItem,
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_items.isNotEmpty) ...[
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(8),
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        'Description',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Qty',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Price',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Total',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 40),
                                  ],
                                ),
                              ),
                              ..._items.map(
                                (item) => Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Text(item['description']),
                                      ),
                                      Expanded(
                                        child: Text(
                                          item['quantity'].toString(),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          '\$${item['price'].toStringAsFixed(2)}',
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          '\$${(item['quantity'] * item['price']).toStringAsFixed(2)}',
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () =>
                                            _removeItem(_items.indexOf(item)),
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text('Tax Rate (%):'),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 80,
                              child: TextFormField(
                                initialValue: _taxRate.toString(),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) =>
                                    _taxRate = double.tryParse(value) ?? 8.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Subtotal:'),
                                    Text(
                                      '\$${_calculateSubtotal().toStringAsFixed(2)}',
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Tax ($_taxRate%):'),
                                    Text(
                                      '\$${_calculateTax().toStringAsFixed(2)}',
                                    ),
                                  ],
                                ),
                                const Divider(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Total:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      '\$${_calculateTotal().toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _items.isNotEmpty ? _generateInvoice : null,
                  child: const Text('Generate Invoice'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addItem() {
    if (_itemDescController.text.isNotEmpty &&
        _quantityController.text.isNotEmpty &&
        _priceController.text.isNotEmpty) {
      setState(() {
        _items.add({
          'description': _itemDescController.text,
          'quantity': int.tryParse(_quantityController.text) ?? 1,
          'price': double.tryParse(_priceController.text) ?? 0.0,
        });
        _itemDescController.clear();
        _quantityController.clear();
        _priceController.clear();
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  double _calculateSubtotal() {
    return _items.fold(
      0.0,
      (sum, item) => sum + (item['quantity'] * item['price']),
    );
  }

  double _calculateTax() {
    return _calculateSubtotal() * (_taxRate / 100);
  }

  double _calculateTotal() {
    return _calculateSubtotal() + _calculateTax();
  }

  void _generateInvoice() {
    if (_formKey.currentState!.validate() && _items.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Invoice generated for ${_customerNameController.text} - Total: \$${_calculateTotal().toStringAsFixed(2)}',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }
}

// Tax Calculator Dialog
class _TaxCalculatorDialog extends StatefulWidget {
  @override
  _TaxCalculatorDialogState createState() => _TaxCalculatorDialogState();
}

class _TaxCalculatorDialogState extends State<_TaxCalculatorDialog> {
  final _amountController = TextEditingController();
  double _federalRate = 21.0;
  double _stateRate = 8.5;
  double _localRate = 2.0;
  double _totalTax = 0.0;
  double _afterTaxAmount = 0.0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tax Calculator',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (\$)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => _calculateTax(),
            ),
            const SizedBox(height: 20),
            Text(
              'Tax Rates',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildTaxRateSlider('Federal Tax', _federalRate, 0, 40, (value) {
              setState(() {
                _federalRate = value;
                _calculateTax();
              });
            }),
            _buildTaxRateSlider('State Tax', _stateRate, 0, 15, (value) {
              setState(() {
                _stateRate = value;
                _calculateTax();
              });
            }),
            _buildTaxRateSlider('Local Tax', _localRate, 0, 5, (value) {
              setState(() {
                _localRate = value;
                _calculateTax();
              });
            }),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildCalculationRow(
                      'Original Amount',
                      _amountController.text.isEmpty
                          ? 0.0
                          : double.tryParse(_amountController.text) ?? 0.0,
                    ),
                    _buildCalculationRow(
                      'Federal Tax (${_federalRate.toStringAsFixed(1)}%)',
                      _calculateIndividualTax(_federalRate),
                    ),
                    _buildCalculationRow(
                      'State Tax (${_stateRate.toStringAsFixed(1)}%)',
                      _calculateIndividualTax(_stateRate),
                    ),
                    _buildCalculationRow(
                      'Local Tax (${_localRate.toStringAsFixed(1)}%)',
                      _calculateIndividualTax(_localRate),
                    ),
                    const Divider(),
                    _buildCalculationRow('Total Tax', _totalTax, isTotal: true),
                    _buildCalculationRow(
                      'After Tax Amount',
                      _afterTaxAmount,
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _resetCalculator,
                  child: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxRateSlider(
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label), Text('${value.toStringAsFixed(1)}%')],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) * 2).toInt(),
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildCalculationRow(
    String label,
    double amount, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateIndividualTax(double rate) {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    return amount * (rate / 100);
  }

  void _calculateTax() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final federalTax = amount * (_federalRate / 100);
    final stateTax = amount * (_stateRate / 100);
    final localTax = amount * (_localRate / 100);

    setState(() {
      _totalTax = federalTax + stateTax + localTax;
      _afterTaxAmount = amount + _totalTax;
    });
  }

  void _resetCalculator() {
    setState(() {
      _amountController.clear();
      _federalRate = 21.0;
      _stateRate = 8.5;
      _localRate = 2.0;
      _totalTax = 0.0;
      _afterTaxAmount = 0.0;
    });
  }
}

// Cash Flow Dialog
class _CashFlowDialog extends StatefulWidget {
  @override
  _CashFlowDialogState createState() => _CashFlowDialogState();
}

class _CashFlowDialogState extends State<_CashFlowDialog> {
  final List<Map<String, dynamic>> _cashFlowItems = [
    {
      'type': 'Income',
      'description': 'Service Revenue',
      'amount': 15000.0,
      'date': DateTime.now(),
    },
    {
      'type': 'Income',
      'description': 'Parts Sales',
      'amount': 3500.0,
      'date': DateTime.now(),
    },
    {
      'type': 'Expense',
      'description': 'Rent',
      'amount': -2000.0,
      'date': DateTime.now(),
    },
    {
      'type': 'Expense',
      'description': 'Utilities',
      'amount': -300.0,
      'date': DateTime.now(),
    },
    {
      'type': 'Expense',
      'description': 'Inventory Purchase',
      'amount': -5000.0,
      'date': DateTime.now(),
    },
    {
      'type': 'Expense',
      'description': 'Salaries',
      'amount': -8000.0,
      'date': DateTime.now(),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final totalIncome = _cashFlowItems
        .where((item) => item['amount'] > 0)
        .fold(0.0, (sum, item) => sum + item['amount']);
    final totalExpenses = _cashFlowItems
        .where((item) => item['amount'] < 0)
        .fold(0.0, (sum, item) => sum + item['amount'].abs());
    final netCashFlow = totalIncome - totalExpenses;

    return Dialog(
      child: Container(
        width: 700,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cash Flow Analysis',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Income',
                    totalIncome,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    'Total Expenses',
                    totalExpenses,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    'Net Cash Flow',
                    netCashFlow,
                    netCashFlow >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Cash Flow Details',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Type',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Description',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Amount',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Date',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _cashFlowItems.length,
                        itemBuilder: (context, index) {
                          final item = _cashFlowItems[index];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: item['type'] == 'Income'
                                          ? Colors.green.withValues(alpha: 0.1)
                                          : Colors.red.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      item['type'],
                                      style: TextStyle(
                                        color: item['type'] == 'Income'
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(item['description']),
                                ),
                                Expanded(
                                  child: Text(
                                    '\$${item['amount'].abs().toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: item['amount'] > 0
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${item['date'].month}/${item['date'].day}/${item['date'].year}',
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
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _exportCashFlow,
                  child: const Text('Export'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _exportCashFlow() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cash flow report exported successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

// Budget Planner Dialog
class _BudgetPlannerDialog extends StatefulWidget {
  @override
  _BudgetPlannerDialogState createState() => _BudgetPlannerDialogState();
}

class _BudgetPlannerDialogState extends State<_BudgetPlannerDialog> {
  final Map<String, Map<String, double>> _budgetData = {
    'Revenue': {'budgeted': 20000, 'actual': 18500},
    'Cost of Goods Sold': {'budgeted': 8000, 'actual': 7200},
    'Rent': {'budgeted': 2000, 'actual': 2000},
    'Utilities': {'budgeted': 400, 'actual': 350},
    'Marketing': {'budgeted': 1000, 'actual': 1200},
    'Salaries': {'budgeted': 8000, 'actual': 8000},
    'Insurance': {'budgeted': 500, 'actual': 500},
    'Supplies': {'budgeted': 300, 'actual': 280},
  };

  @override
  Widget build(BuildContext context) {
    final totalBudgeted = _budgetData.values.fold(
      0.0,
      (sum, item) => item.keys.first == 'Revenue'
          ? sum + item['budgeted']!
          : sum - item['budgeted']!,
    );
    final totalActual = _budgetData.values.fold(
      0.0,
      (sum, item) => item.keys.first == 'Revenue'
          ? sum + item['actual']!
          : sum - item['actual']!,
    );
    final variance = totalActual - totalBudgeted;

    return Dialog(
      child: Container(
        width: 800,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Budget Planner',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildBudgetSummaryCard(
                    'Budgeted Net',
                    totalBudgeted,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildBudgetSummaryCard(
                    'Actual Net',
                    totalActual,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildBudgetSummaryCard(
                    'Variance',
                    variance,
                    variance >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Budget vs Actual',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Category',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Budgeted',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Actual',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Variance',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '% Variance',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _budgetData.keys.length,
                        itemBuilder: (context, index) {
                          final category = _budgetData.keys.elementAt(index);
                          final data = _budgetData[category]!;
                          final budgeted = data['budgeted']!;
                          final actual = data['actual']!;
                          final variance = actual - budgeted;
                          final percentVariance = budgeted != 0
                              ? (variance / budgeted) * 100
                              : 0.0;

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    category,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '\$${budgeted.toStringAsFixed(0)}',
                                  ),
                                ),
                                Expanded(
                                  child: Text('\$${actual.toStringAsFixed(0)}'),
                                ),
                                Expanded(
                                  child: Text(
                                    '\$${variance.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: variance >= 0
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${percentVariance.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      color: percentVariance >= 0
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.w500,
                                    ),
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
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _editBudget,
                  child: const Text('Edit Budget'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _exportBudget,
                  child: const Text('Export'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetSummaryCard(String title, double amount, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editBudget() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Budget editing feature coming soon')),
    );
  }

  void _exportBudget() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Budget report exported successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

// ROI Calculator Dialog
class _ROICalculatorDialog extends StatefulWidget {
  @override
  _ROICalculatorDialogState createState() => _ROICalculatorDialogState();
}

class _ROICalculatorDialogState extends State<_ROICalculatorDialog> {
  final _initialInvestmentController = TextEditingController();
  final _finalValueController = TextEditingController();
  final _annualRevenueController = TextEditingController();
  final _annualCostController = TextEditingController();
  int _timeHorizonYears = 1;
  double _roi = 0.0;
  double _annualizedROI = 0.0;
  double _paybackPeriod = 0.0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ROI Calculator',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _initialInvestmentController,
                    decoration: const InputDecoration(
                      labelText: 'Initial Investment (\$)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _calculateROI(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _finalValueController,
                    decoration: const InputDecoration(
                      labelText: 'Final Value (\$)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _calculateROI(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _annualRevenueController,
                    decoration: const InputDecoration(
                      labelText: 'Annual Revenue (\$)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _calculateROI(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _annualCostController,
                    decoration: const InputDecoration(
                      labelText: 'Annual Cost (\$)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _calculateROI(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Time Horizon: $_timeHorizonYears years',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Slider(
              value: _timeHorizonYears.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (value) {
                setState(() {
                  _timeHorizonYears = value.toInt();
                  _calculateROI();
                });
              },
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ROI Analysis',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildROIMetric(
                      'Total ROI',
                      '${_roi.toStringAsFixed(2)}%',
                      _roi >= 0 ? Colors.green : Colors.red,
                    ),
                    _buildROIMetric(
                      'Annualized ROI',
                      '${_annualizedROI.toStringAsFixed(2)}%',
                      _annualizedROI >= 0 ? Colors.green : Colors.red,
                    ),
                    _buildROIMetric(
                      'Payback Period',
                      '${_paybackPeriod.toStringAsFixed(1)} years',
                      Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    _buildROIInterpretation(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _resetROICalculator,
                  child: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildROIMetric(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildROIInterpretation() {
    String interpretation;
    Color color;

    if (_roi > 20) {
      interpretation = 'Excellent ROI - Very profitable investment';
      color = Colors.green;
    } else if (_roi > 10) {
      interpretation = 'Good ROI - Profitable investment';
      color = Colors.green;
    } else if (_roi > 0) {
      interpretation = 'Positive ROI - Marginal profitability';
      color = Colors.orange;
    } else {
      interpretation = 'Negative ROI - Investment loss';
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              interpretation,
              style: TextStyle(fontWeight: FontWeight.w500, color: color),
            ),
          ),
        ],
      ),
    );
  }

  void _calculateROI() {
    final initialInvestment =
        double.tryParse(_initialInvestmentController.text) ?? 0.0;
    final finalValue = double.tryParse(_finalValueController.text) ?? 0.0;
    final annualRevenue = double.tryParse(_annualRevenueController.text) ?? 0.0;
    final annualCost = double.tryParse(_annualCostController.text) ?? 0.0;

    setState(() {
      if (initialInvestment > 0) {
        if (finalValue > 0) {
          // Simple ROI calculation
          _roi = ((finalValue - initialInvestment) / initialInvestment) * 100;
          _annualizedROI = _roi / _timeHorizonYears;
        } else if (annualRevenue > 0 && annualCost >= 0) {
          // Annual cash flow based ROI
          final annualProfit = annualRevenue - annualCost;
          final totalProfit = annualProfit * _timeHorizonYears;
          _roi = (totalProfit / initialInvestment) * 100;
          _annualizedROI = _roi / _timeHorizonYears;
        }

        // Calculate payback period
        if (annualRevenue > annualCost && (annualRevenue - annualCost) > 0) {
          _paybackPeriod = initialInvestment / (annualRevenue - annualCost);
        } else if (finalValue > initialInvestment) {
          _paybackPeriod = _timeHorizonYears.toDouble();
        }
      }
    });
  }

  void _resetROICalculator() {
    setState(() {
      _initialInvestmentController.clear();
      _finalValueController.clear();
      _annualRevenueController.clear();
      _annualCostController.clear();
      _timeHorizonYears = 1;
      _roi = 0.0;
      _annualizedROI = 0.0;
      _paybackPeriod = 0.0;
    });
  }
}

// Expense Tracker Dialog
class _ExpenseTrackerDialog extends StatefulWidget {
  @override
  _ExpenseTrackerDialogState createState() => _ExpenseTrackerDialogState();
}

class _ExpenseTrackerDialogState extends State<_ExpenseTrackerDialog> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = 'Office Supplies';
  final List<String> _categories = [
    'Office Supplies',
    'Rent',
    'Utilities',
    'Marketing',
    'Travel',
    'Equipment',
    'Insurance',
    'Professional Services',
    'Other',
  ];

  final List<Map<String, dynamic>> _expenses = [
    {
      'description': 'Office rent',
      'amount': 2000.0,
      'category': 'Rent',
      'date': DateTime.now().subtract(const Duration(days: 1)),
    },
    {
      'description': 'Electricity bill',
      'amount': 150.0,
      'category': 'Utilities',
      'date': DateTime.now().subtract(const Duration(days: 2)),
    },
    {
      'description': 'Paper and pens',
      'amount': 45.0,
      'category': 'Office Supplies',
      'date': DateTime.now().subtract(const Duration(days: 3)),
    },
    {
      'description': 'Google Ads',
      'amount': 300.0,
      'category': 'Marketing',
      'date': DateTime.now().subtract(const Duration(days: 4)),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final totalExpenses = _expenses.fold(
      0.0,
      (sum, expense) => sum + expense['amount'],
    );
    final categoryTotals = <String, double>{};
    for (var expense in _expenses) {
      categoryTotals[expense['category']] =
          (categoryTotals[expense['category']] ?? 0) + expense['amount'];
    }

    return Dialog(
      child: Container(
        width: 800,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Expense Tracker',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add New Expense',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _amountController,
                            decoration: const InputDecoration(
                              labelText: 'Amount (\$)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(),
                            ),
                            items: _categories
                                .map(
                                  (category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(category),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _selectedCategory = value!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _addExpense,
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'Total Expenses',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '\$${totalExpenses.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Top Categories',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          ...categoryTotals.entries
                              .take(3)
                              .map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(entry.key),
                                      Text(
                                        '\$${entry.value.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Recent Expenses',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Date',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Description',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Category',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Amount',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(width: 40),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _expenses.length,
                        itemBuilder: (context, index) {
                          final expense = _expenses[index];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${expense['date'].month}/${expense['date'].day}/${expense['date'].year}',
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(expense['description']),
                                ),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      expense['category'],
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '\$${expense['amount'].toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _removeExpense(index),
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
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
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _exportExpenses,
                  child: const Text('Export'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addExpense() {
    if (_descriptionController.text.isNotEmpty &&
        _amountController.text.isNotEmpty) {
      setState(() {
        _expenses.insert(0, {
          'description': _descriptionController.text,
          'amount': double.tryParse(_amountController.text) ?? 0.0,
          'category': _selectedCategory,
          'date': DateTime.now(),
        });
        _descriptionController.clear();
        _amountController.clear();
      });
    }
  }

  void _removeExpense(int index) {
    setState(() {
      _expenses.removeAt(index);
    });
  }

  void _exportExpenses() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Expenses exported successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
