import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/admin/presentation/admin_main_layout.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_login_screen.dart';
import '../../features/admin/presentation/screens/admin_qr_scanner_screen.dart';
import '../../features/admin/presentation/screens/admin_slot_manager_screen.dart';
import '../../features/admin/presentation/screens/turf_owner_profile_screen.dart';
import '../../features/admin/presentation/screens/turf_owner_registration_screen.dart';
import '../../features/admin/presentation/screens/turf_owner_settings_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';

import '../../features/admin/presentation/screens/web_partner_portal_screen.dart';
import '../../features/admin/presentation/screens/admin_tournament_manager_screen.dart';

Page<dynamic> _buildSmoothPage(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 200),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ),
        child: child,
      );
    },
  );
}

class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/web-portal',
        builder: (context, state) => const WebPartnerPortalScreen(),
      ),
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: AdminLoginScreen(),
        ),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => _buildSmoothPage(
          const TurfOwnerRegistrationScreen(),
          state,
        ),
      ),
      // Standalone Full-Screen QR Scanner (Accessible via Top Header Bar & Booking Details)
      GoRoute(
        path: '/admin/qr-scanner',
        pageBuilder: (context, state) => _buildSmoothPage(
          const AdminQrScannerScreen(),
          state,
        ),
      ),
      // Standalone Full-Screen Turf Owner Settings & Operations Page
      GoRoute(
        path: '/admin/settings',
        pageBuilder: (context, state) => _buildSmoothPage(
          const TurfOwnerSettingsScreen(),
          state,
        ),
      ),

      // Shell Route for Turf Owner Dedicated Navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AdminMainLayout(
            currentIndex: navigationShell.currentIndex,
            onTabSelected: (index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
            child: navigationShell,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/dashboard',
                builder: (context, state) => const AdminDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/slots',
                builder: (context, state) => const AdminSlotManagerScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/tournaments',
                builder: (context, state) => const AdminTournamentManagerScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/profile',
                builder: (context, state) => const TurfOwnerProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
