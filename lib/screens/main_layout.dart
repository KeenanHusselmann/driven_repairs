import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                backgroundColor: Theme.of(context).colorScheme.surface,
                indicatorColor: Theme.of(context).colorScheme.primaryContainer,
                selectedIconTheme: IconThemeData(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                unselectedIconTheme: IconThemeData(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                selectedLabelTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                unselectedLabelTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                extended: MediaQuery.of(context).size.width > 1200,
                selectedIndex: _getSelectedIndex(context, authProvider),
                onDestinationSelected: (index) {
                  _onDestinationSelected(context, index, authProvider);
                },
                destinations: _buildNavigationDestinations(authProvider),
              ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 64,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          // Logo
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A90E2), // Professional blue
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image.asset(
                              'assets/images/logo_transparent.png',
                              width: 24,
                              height: 24,
                              fit: BoxFit.contain,
                              color: Colors.white, // Tint the logo white
                              colorBlendMode: BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Driven Repairs',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const Spacer(),
                          // User Profile
                          PopupMenuButton<String>(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  child: Text(
                                    authProvider.userInitials,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      authProvider.userDisplayName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                    Text(
                                      authProvider
                                              .currentUser
                                              ?.role
                                              .displayName ??
                                          '',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                            onSelected: (value) {
                              switch (value) {
                                case 'activities':
                                  context.go('/activities');
                                  break;
                                case 'settings':
                                  context.go('/settings');
                                  break;
                                case 'logout':
                                  authProvider.logout();
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'activities',
                                child: Row(
                                  children: [
                                    Icon(Icons.history),
                                    SizedBox(width: 8),
                                    Text('My Activities'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'settings',
                                child: Row(
                                  children: [
                                    Icon(Icons.settings),
                                    SizedBox(width: 8),
                                    Text('Settings'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'logout',
                                child: Row(
                                  children: [
                                    Icon(Icons.logout, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text(
                                      'Logout',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),
                    ),
                    Expanded(child: child),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<NavigationRailDestination> _buildNavigationDestinations(
    AuthProvider authProvider,
  ) {
    final destinations = <NavigationRailDestination>[];

    // Dashboard - always available
    destinations.add(
      const NavigationRailDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: Text('Dashboard'),
      ),
    );

    // Performance Overview - always available
    destinations.add(
      const NavigationRailDestination(
        icon: Icon(Icons.trending_up_outlined),
        selectedIcon: Icon(Icons.trending_up),
        label: Text('Performance'),
      ),
    );

    // Customers - available to Sales, Admin
    if (authProvider.canAccessFeature('customers')) {
      destinations.add(
        const NavigationRailDestination(
          icon: Icon(Icons.people_outlined),
          selectedIcon: Icon(Icons.people),
          label: Text('Customers'),
        ),
      );
    }

    // Devices - available to Technicians, Sales, Admin
    if (authProvider.canAccessFeature('devices')) {
      destinations.add(
        const NavigationRailDestination(
          icon: Icon(Icons.devices_outlined),
          selectedIcon: Icon(Icons.devices),
          label: Text('Devices'),
        ),
      );
    }

    // Tickets - available to Technicians, Sales, Admin
    if (authProvider.canAccessFeature('tickets')) {
      destinations.add(
        const NavigationRailDestination(
          icon: Icon(Icons.assignment_outlined),
          selectedIcon: Icon(Icons.assignment),
          label: Text('Tickets'),
        ),
      );
    }

    // Parts - available to Technicians, Accountants, Admin
    if (authProvider.canAccessFeature('parts')) {
      destinations.add(
        const NavigationRailDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2),
          label: Text('Parts'),
        ),
      );
    }

    // Users - Admin only
    if (authProvider.canAccessFeature('users')) {
      destinations.add(
        const NavigationRailDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: Icon(Icons.admin_panel_settings),
          label: Text('Users'),
        ),
      );
    }

    // Sales - Admin and Accountant only
    if (authProvider.canViewSales()) {
      destinations.add(
        const NavigationRailDestination(
          icon: Icon(Icons.point_of_sale_outlined),
          selectedIcon: Icon(Icons.point_of_sale),
          label: Text('Sales'),
        ),
      );
    }

    // Reports - available to all except basic technicians
    if (authProvider.canAccessFeature('reports')) {
      destinations.add(
        const NavigationRailDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics),
          label: Text('Reports'),
        ),
      );
    }

    return destinations;
  }

  int _getSelectedIndex(BuildContext context, AuthProvider authProvider) {
    final String location = GoRouterState.of(context).uri.path;

    // Map route to destination index
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/performance')) return 1;

    int index = 2;
    if (authProvider.canAccessFeature('customers') &&
        location.startsWith('/customers')) {
      return index;
    }
    if (authProvider.canAccessFeature('customers')) {
      index++;
    }

    if (authProvider.canAccessFeature('devices') &&
        location.startsWith('/devices')) {
      return index;
    }
    if (authProvider.canAccessFeature('devices')) {
      index++;
    }

    if (authProvider.canAccessFeature('tickets') &&
        location.startsWith('/tickets')) {
      return index;
    }
    if (authProvider.canAccessFeature('tickets')) {
      index++;
    }

    if (authProvider.canAccessFeature('parts') && location.startsWith('/parts')) {
      return index;
    }
    if (authProvider.canAccessFeature('parts')) {
      index++;
    }

    if (authProvider.canAccessFeature('users') && location.startsWith('/users')) {
      return index;
    }
    if (authProvider.canAccessFeature('users')) {
      index++;
    }

    if (authProvider.canViewSales() && location.startsWith('/sales')) {
      return index;
    }
    if (authProvider.canViewSales()) {
      index++;
    }

    if (authProvider.canAccessFeature('reports') &&
        location.startsWith('/reports')) {
      return index;
    }

    return 0;
  }

  void _onDestinationSelected(
    BuildContext context,
    int index,
    AuthProvider authProvider,
  ) {
    final routes = <String>[];

    // Build route list based on available features
    routes.add('/dashboard');
    routes.add('/performance');
    if (authProvider.canAccessFeature('customers')) routes.add('/customers');
    if (authProvider.canAccessFeature('devices')) routes.add('/devices');
    if (authProvider.canAccessFeature('tickets')) routes.add('/tickets');
    if (authProvider.canAccessFeature('parts')) routes.add('/parts');
    if (authProvider.canAccessFeature('users')) routes.add('/users');
    if (authProvider.canViewSales()) routes.add('/sales');
    if (authProvider.canAccessFeature('reports')) routes.add('/reports');

    if (index < routes.length) {
      context.go(routes[index]);
    }
  }
}
