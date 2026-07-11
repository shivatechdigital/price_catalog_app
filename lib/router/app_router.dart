import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:price_catalog_app/features/admin/dashboard/screens/admin_dashboard_screen.dart';
import 'package:price_catalog_app/features/auth/screens/login_screen.dart';
import 'package:price_catalog_app/features/auth/screens/register_admin_screen.dart';
import 'package:price_catalog_app/features/auth/screens/register_screen.dart';
import 'package:price_catalog_app/features/auth/screens/complete_profile_screen.dart';
import 'package:price_catalog_app/features/auth/screens/pending_approval_screen.dart';
import 'package:price_catalog_app/features/splash/splash_screen.dart';
import 'package:price_catalog_app/features/trader/dashboard/screens/trader_dashboard_screen.dart';
import 'package:price_catalog_app/providers/auth_provider.dart';

// ═══════════════════════════════════════
// ROUTE NAMES - All routes in one place
// ═══════════════════════════════════════
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String registerAdmin = '/register-admin';
  static const String completeProfile = '/complete-profile';
  static const String pendingApproval = '/pending-approval';

  // Admin Routes
  static const String adminDashboard = '/admin/dashboard';
  static const String adminCategories = '/admin/categories';
  static const String adminAddCategory = '/admin/categories/add';
  static const String adminProducts = '/admin/products';
  static const String adminAddProduct = '/admin/products/add';
  static const String adminProductDetail = '/admin/products/detail';
  static const String adminEditProduct = '/admin/products/edit';
  static const String adminPriceUpdate = '/admin/price-update';
  static const String adminPriceHistory = '/admin/price-history';
  static const String adminTraders = '/admin/traders';
  static const String adminTraderDetail = '/admin/traders/detail';
  static const String adminRequirements = '/admin/requirements';
  static const String adminRequirementDetail = '/admin/requirements/detail';
  static const String adminReports = '/admin/reports';
  static const String adminSettings = '/admin/settings';
  static const String adminProfile = '/admin/profile';

  // Trader Routes
  static const String traderDashboard = '/trader/dashboard';
  static const String traderCatalog = '/trader/catalog';
  static const String traderProductDetail = '/trader/products/detail';
  static const String traderRequirements = '/trader/requirements';
  static const String traderSubmitRequirement = '/trader/requirements/submit';
  static const String traderRequirementDetail = '/trader/requirements/detail';
  static const String traderNotifications = '/trader/notifications';
  static const String traderProfile = '/trader/profile';
  static const String traderShareCatalog = '/trader/share-catalog';
}

// ═══════════════════════════════════════
// ROUTER PROVIDER
// ═══════════════════════════════════════
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authStateProvider.notifier).stream,
    ),

    // ═══════════════════════════════════════
    // REDIRECT LOGIC
    // ═══════════════════════════════════════
    redirect: (context, state) {
      final currentPath = state.matchedLocation;

      return authState.when(
        initial: () => null,
        loading: () => null,
        unauthenticated: () {
          // Public routes - allow access
          final publicRoutes = [
            AppRoutes.splash,
            AppRoutes.login,
            AppRoutes.register,
            AppRoutes.registerAdmin,
            AppRoutes.pendingApproval,
          ];

          if (publicRoutes.contains(currentPath)) return null;
          return AppRoutes.login;
        },
        profileIncomplete: () {
          if (currentPath == AppRoutes.completeProfile) return null;
          return AppRoutes.completeProfile;
        },
        pendingApproval: () {
          if (currentPath == AppRoutes.pendingApproval) return null;
          return AppRoutes.pendingApproval;
        },
        authenticatedAdmin: (_) {
          // If admin on auth pages → redirect to dashboard
          final authPages = [
            AppRoutes.login,
            AppRoutes.register,
            AppRoutes.registerAdmin,
            AppRoutes.completeProfile,
            AppRoutes.splash,
          ];
          if (authPages.contains(currentPath)) {
            return AppRoutes.adminDashboard;
          }
          // Block trader routes for admin
          if (currentPath.startsWith('/trader')) {
            return AppRoutes.adminDashboard;
          }
          return null;
        },
        authenticatedTrader: (_) {
          // If trader on auth pages → redirect to dashboard
          final authPages = [
            AppRoutes.login,
            AppRoutes.register,
            AppRoutes.registerAdmin,
            AppRoutes.completeProfile,
            AppRoutes.splash,
          ];
          if (authPages.contains(currentPath)) {
            return AppRoutes.traderDashboard;
          }
          // Block admin routes for trader
          if (currentPath.startsWith('/admin')) {
            return AppRoutes.traderDashboard;
          }
          return null;
        },
      );
    },

    // ═══════════════════════════════════════
    // ROUTES
    // ═══════════════════════════════════════
    routes: [
      // Splash
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RegisterScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.registerAdmin,
        name: 'registerAdmin',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RegisterAdminScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.completeProfile,
        name: 'completeProfile',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CompleteProfileScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.pendingApproval,
        name: 'pendingApproval',
        builder: (context, state) => const PendingApprovalScreen(),
      ),

      // ═══════════════════════════════════════
      // ADMIN ROUTES
      // ═══════════════════════════════════════
      GoRoute(
        path: AppRoutes.adminDashboard,
        name: 'adminDashboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AdminDashboardScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // More admin routes will be added as we build them
      // GoRoute(path: AppRoutes.adminCategories, ...),
      // GoRoute(path: AppRoutes.adminProducts, ...),
      // etc.

      // ═══════════════════════════════════════
      // TRADER ROUTES
      // ═══════════════════════════════════════
      GoRoute(
        path: AppRoutes.traderDashboard,
        name: 'traderDashboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const TraderDashboardScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // More trader routes will be added as we build them
    ],

    // Error page
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});

// ═══════════════════════════════════════
// PAGE TRANSITIONS
// ═══════════════════════════════════════
Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(opacity: animation, child: child);
}

Widget _slideTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOut,
    )),
    child: child,
  );
}

// ═══════════════════════════════════════
// REFRESH STREAM HELPER
// ═══════════════════════════════════════
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}