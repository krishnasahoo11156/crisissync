import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:crisissync/providers/auth_provider.dart';
import 'package:crisissync/screens/landing_screen.dart';
import 'package:crisissync/screens/auth_screen.dart';
import 'package:crisissync/screens/guest/guest_home_screen.dart';
import 'package:crisissync/screens/guest/guest_status_screen.dart';
import 'package:crisissync/screens/guest/guest_resolved_screen.dart';
import 'package:crisissync/screens/guest/guest_history_screen.dart';
import 'package:crisissync/screens/guest/guest_concern_screen.dart';
import 'package:crisissync/screens/staff/staff_layout.dart';
import 'package:crisissync/screens/staff/staff_dashboard_screen.dart';
import 'package:crisissync/screens/staff/staff_incident_detail_screen.dart';
import 'package:crisissync/screens/staff/staff_map_screen.dart';
import 'package:crisissync/screens/staff/staff_history_screen.dart';
import 'package:crisissync/screens/admin/admin_layout.dart';
import 'package:crisissync/screens/admin/admin_overview_screen.dart';
import 'package:crisissync/screens/admin/admin_incidents_screen.dart';
import 'package:crisissync/screens/admin/admin_staff_screen.dart';
import 'package:crisissync/screens/admin/admin_analytics_screen.dart';
import 'package:crisissync/screens/admin/admin_venue_screen.dart';

/// App router with role-based redirect guards.
class AppRouter {
  static GoRouter router(AuthProvider authProvider) {
    return GoRouter(
      refreshListenable: authProvider,
      initialLocation: '/',
      redirect: (context, state) {
        final isLoggedIn = authProvider.isLoggedIn;
        final userRole = authProvider.userRole;
        final path = state.uri.path;

        // Allow landing page always
        if (path == '/') return null;

        // Auth screen accessible when not logged in
        if (path == '/auth') {
          if (isLoggedIn) {
            return _homeForRole(userRole);
          }
          return null;
        }

        // Not logged in → redirect to auth
        if (!isLoggedIn) return '/auth';

        // Role-based route protection
        if (path.startsWith('/guest') && userRole != 'guest' && userRole != 'admin') {
          return _homeForRole(userRole);
        }
        if (path.startsWith('/staff') && userRole != 'staff' && userRole != 'admin') {
          return _homeForRole(userRole);
        }
        if (path.startsWith('/admin') && userRole != 'admin') {
          return _homeForRole(userRole);
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const LandingScreen(),
        ),
        GoRoute(
          path: '/auth',
          builder: (context, state) {
            final portal = state.uri.queryParameters['portal'] ?? '';
            return AuthScreen(portalHint: portal);
          },
        ),

        // ─── Guest Routes ───
        GoRoute(
          path: '/guest',
          builder: (context, state) => const GuestHomeScreen(),
        ),
        GoRoute(
          path: '/guest/status/:id',
          builder: (context, state) =>
              GuestStatusScreen(incidentId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/guest/resolved/:id',
          builder: (context, state) =>
              GuestResolvedScreen(incidentId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/guest/history',
          builder: (context, state) => const GuestHistoryScreen(),
        ),
        GoRoute(
          path: '/guest/concern',
          builder: (context, state) => const GuestConcernScreen(),
        ),

        // ─── Staff Routes ───
        ShellRoute(
          builder: (context, state, child) => StaffLayout(child: child),
          routes: [
            GoRoute(
              path: '/staff/dashboard',
              builder: (context, state) => const StaffDashboardScreen(),
            ),
            GoRoute(
              path: '/staff/incident/:id',
              builder: (context, state) =>
                  StaffIncidentDetailScreen(incidentId: state.pathParameters['id']!),
            ),
            GoRoute(
              path: '/staff/map',
              builder: (context, state) => const StaffMapScreen(),
            ),
            GoRoute(
              path: '/staff/history',
              builder: (context, state) => const StaffHistoryScreen(),
            ),
          ],
        ),

        // ─── Admin Routes ───
        ShellRoute(
          builder: (context, state, child) => AdminLayout(child: child),
          routes: [
            GoRoute(
              path: '/admin',
              builder: (context, state) => const AdminOverviewScreen(),
            ),
            GoRoute(
              path: '/admin/incidents',
              builder: (context, state) => const AdminIncidentsScreen(),
            ),
            GoRoute(
              path: '/admin/staff',
              builder: (context, state) => const AdminStaffScreen(),
            ),
            GoRoute(
              path: '/admin/analytics',
              builder: (context, state) => const AdminAnalyticsScreen(),
            ),
            GoRoute(
              path: '/admin/venue',
              builder: (context, state) => const AdminVenueScreen(),
            ),
          ],
        ),
      ],
    );
  }

  static String _homeForRole(String? role) {
    switch (role) {
      case 'admin':
        return '/admin';
      case 'staff':
        return '/staff/dashboard';
      case 'guest':
        return '/guest';
      default:
        return '/';
    }
  }
}
