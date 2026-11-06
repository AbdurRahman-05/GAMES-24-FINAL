import 'package:go_router/go_router.dart';
import '../../features/admin/presentation/admin_main_layout.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_login_screen.dart';
import '../../features/admin/presentation/screens/admin_qr_scanner_screen.dart';
import '../../features/admin/presentation/screens/admin_slot_manager_screen.dart';
import '../../features/admin/presentation/screens/turf_owner_profile_screen.dart';
import '../../features/admin/presentation/screens/turf_owner_registration_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';

import '../../features/admin/presentation/screens/web_partner_portal_screen.dart';
import '../../features/admin/presentation/screens/admin_tournament_manager_screen.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
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
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const TurfOwnerRegistrationScreen(),
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
                path: '/admin/qr-scanner',
                builder: (context, state) => const AdminQrScannerScreen(),
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
