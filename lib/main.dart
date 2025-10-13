import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'screens/screens.dart';
import 'providers/providers.dart';

void main() {
  runApp(const DrivenRepairsApp());
}

class DrivenRepairsApp extends StatelessWidget {
  const DrivenRepairsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProxyProvider<AuthProvider, CustomerProvider>(
          create: (_) => CustomerProvider(),
          update: (_, authProvider, customerProvider) {
            customerProvider?.setAuthProvider(authProvider);
            return customerProvider ?? CustomerProvider();
          },
        ),
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
        ChangeNotifierProxyProvider<AuthProvider, RepairTicketProvider>(
          create: (_) => RepairTicketProvider(),
          update: (_, authProvider, repairTicketProvider) {
            repairTicketProvider?.setAuthProvider(authProvider);
            return repairTicketProvider ?? RepairTicketProvider();
          },
        ),
        ChangeNotifierProvider(create: (_) => TechnicianProvider()),
        ChangeNotifierProvider(create: (_) => PartProvider()),
        ChangeNotifierProvider(create: (_) => ServiceRatingProvider()),
        ChangeNotifierProvider(create: (_) => TicketResolutionMetricProvider()),
        ChangeNotifierProvider(create: (_) => ShortUrlProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp.router(
            title: 'Driven Repairs',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.light(
                primary: const Color(0xFF4A90E2), // Professional blue
                secondary: const Color(0xFF5A9FD4), // Lighter blue
                surface: const Color(0xFFFAFAFA), // Off-white
                surfaceContainerHighest: const Color(0xFFE8E8E8), // Light grey
                onSurface: const Color(0xFF424242), // Dark grey text
                onSurfaceVariant: const Color(0xFF757575), // Medium grey text
                error: const Color(0xFF6B7280), // Neutral grey for errors
                outline: const Color(0xFFD1D5DB), // Light grey borders
              ),
              scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Off-white background
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Color(0xFF424242)),
                bodyMedium: TextStyle(color: Color(0xFF424242)),
                bodySmall: TextStyle(color: Color(0xFF757575)),
                headlineLarge: TextStyle(color: Color(0xFF424242)),
                headlineMedium: TextStyle(color: Color(0xFF424242)),
                headlineSmall: TextStyle(color: Color(0xFF424242)),
                titleLarge: TextStyle(color: Color(0xFF424242)),
                titleMedium: TextStyle(color: Color(0xFF424242)),
                titleSmall: TextStyle(color: Color(0xFF757575)),
              ),
              appBarTheme: const AppBarTheme(
                centerTitle: false,
                elevation: 0,
                backgroundColor: Color(0xFFFAFAFA),
                foregroundColor: Color(0xFF424242),
              ),
              cardTheme: CardThemeData(
                elevation: 1,
                color: const Color(0xFFFFFFFF),
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFFE8E8E8), width: 1),
                ),
              ),
              navigationDrawerTheme: const NavigationDrawerThemeData(
                backgroundColor: Color(0xFFFAFAFA),
              ),
              dividerColor: const Color(0xFFE8E8E8),
              iconTheme: const IconThemeData(color: Color(0xFF757575)),
            ),
            routerConfig: _createRouter(authProvider),
          );
        },
      ),
    );
  }
}

GoRouter _createRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: authProvider.isAuthenticated ? '/dashboard' : '/login',
    redirect: (context, state) {
      final isAuthenticated = authProvider.isAuthenticated;
      final isLoginRoute = state.matchedLocation == '/login';

      // If not authenticated and not on login page, redirect to login
      if (!isAuthenticated && !isLoginRoute) {
        return '/login';
      }

      // If authenticated and on login page, redirect to dashboard
      if (isAuthenticated && isLoginRoute) {
        return '/dashboard';
      }

      // Check role-based access for specific routes
      if (isAuthenticated) {
        return _checkRoutePermissions(state.matchedLocation, authProvider);
      }

      return null; // No redirect needed
    },
    routes: [
      // Login route (not in shell)
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

      // Protected routes with shell
      ShellRoute(
        builder: (context, state, child) {
          return MainLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/customers',
            builder: (context, state) => const CustomersScreen(),
          ),
          GoRoute(
            path: '/customers/:id',
            builder: (context, state) =>
                CustomerDetailScreen(customerId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/devices',
            builder: (context, state) => const DevicesScreen(),
          ),
          GoRoute(
            path: '/devices/:id',
            builder: (context, state) =>
                DeviceDetailScreen(deviceId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/tickets',
            builder: (context, state) => const RepairTicketsScreen(),
          ),
          GoRoute(
            path: '/tickets/:id',
            builder: (context, state) =>
                RepairTicketDetailScreen(ticketId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/technicians',
            builder: (context, state) => const TechniciansScreen(),
          ),
          GoRoute(
            path: '/technicians/:id',
            builder: (context, state) => TechnicianDetailScreen(
              technicianId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/parts',
            builder: (context, state) => const PartsScreen(),
          ),
          GoRoute(
            path: '/users',
            builder: (context, state) => const UsersScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/performance',
            builder: (context, state) => const PerformanceOverviewScreen(),
          ),
          GoRoute(
            path: '/sales',
            builder: (context, state) => const SalesScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/activities',
            builder: (context, state) => const UserActivityScreen(),
          ),
        ],
      ),
    ],
  );
}

String? _checkRoutePermissions(String route, AuthProvider authProvider) {
  // Role-based route access control
  switch (route) {
    case '/users':
      if (!authProvider.canViewUsers()) {
        return '/dashboard'; // Redirect to dashboard if no permission
      }
      break;
    case '/reports':
      if (!authProvider.canViewReports()) {
        return '/dashboard';
      }
      break;
    case '/settings':
      if (!authProvider.canViewSettings()) {
        return '/dashboard';
      }
      break;
    // Add more route restrictions as needed
  }
  return null; // Access allowed
}
