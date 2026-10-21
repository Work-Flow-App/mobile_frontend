import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_frontend/models/auth/auth_state.dart';
import 'package:mobile_frontend/models/job/job_model.dart';
import 'package:mobile_frontend/providers/auth/auth_notifier.dart';
import 'package:mobile_frontend/screens/auth/login_screen.dart';
import 'package:mobile_frontend/screens/auth/signup_screen.dart';
import 'package:mobile_frontend/screens/dashboard/home_dashboard.dart';
import 'package:mobile_frontend/screens/step_detail/step_detail_screen.dart';
import 'package:mobile_frontend/screens/dashboard/task_stats_screen.dart';
import 'package:mobile_frontend/screens/asset/assigned_assets_screen.dart';
import 'package:mobile_frontend/screens/form/assigned_forms_screen.dart';
import 'package:mobile_frontend/screens/form/form_detail_screen.dart';
import 'package:mobile_frontend/models/form/form_model.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // 1. Watch Auth State for changes (Login, Logout, Role change)
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    // This listener triggers a refresh whenever AuthState changes
    refreshListenable: AuthStateListenable(
      ref.read(authNotifierProvider.notifier),
    ),
    debugLogDiagnostics: true, // Helps debug redirects in console

    redirect: (context, state) {
      final isLoggedIn = authState.status == AuthStatus.authenticated;
      final isLoggingIn =
          state.uri.path == '/login' || state.uri.path == '/signup';
      final userRole = authState.role; // 'ADMIN', 'WORKER', etc.

      // --- 1. AUTH GUARD: Unauthenticated users go to Login ---
      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      // --- 2. LOGIN GUARD: Authenticated users go to Dashboard ---
      if (isLoggedIn && isLoggingIn) {
        return '/dashboard';
      }

      // --- 3. ROLE GUARD (RBAC): Block Workers from Admin Routes ---
      // If the path starts with '/admin' AND the user is NOT an Admin...
      if (isLoggedIn && state.uri.path.startsWith('/admin')) {
        if (userRole != 'ADMIN') {
          // Redirect unauthorized workers back to dashboard
          debugPrint(
            "RBAC Blocked: $userRole tried to access ${state.uri.path}",
          );
          return '/dashboard';
        }
      }

      return null; // Allow navigation
    },

    routes: [
      // --- Public Routes ---
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),

      // --- Protected Routes ---
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const HomeDashboard(),
      ),

      GoRoute(
        path: '/task-stats',
        name: 'task-stats',
        builder: (context, state) => const TaskStatsScreen(),
      ),

      GoRoute(
        path: '/step-detail',
        name: 'step-detail',
        builder: (context, state) {
          final jobData = state.extra as JobData;
          return StepDetailScreen(jobData: jobData);
        },
      ),

      GoRoute(
        path: '/my-assets',
        name: 'my-assets',
        builder: (context, state) => const AssignedAssetsScreen(),
      ),

      GoRoute(
        path: '/my-forms',
        name: 'my-forms',
        builder: (context, state) => const AssignedFormsScreen(),
      ),
      GoRoute(
        path: '/form-detail',
        name: 'form-detail',
        builder: (context, state) {
          final form = state.extra as FormSubmissionResponse;
          return FormDetailScreen(initialForm: form);
        },
      ),

      // --- Admin Only Routes (Example) ---
      // If a Worker tries to type /admin/assets manually, the redirect above blocks them.
      GoRoute(
        path: '/admin/assets',
        name: 'admin-assets',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text("Admin Asset Management"))),
      ),
      GoRoute(
        path: '/admin/settings',
        name: 'admin-settings',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text("Admin Settings"))),
      ),
    ],
  );
});

// Helper class to convert Riverpod StateNotifier into a Listenable for GoRouter
class AuthStateListenable extends ChangeNotifier {
  final AuthNotifier _notifier;

  AuthStateListenable(this._notifier) {
    _notifier.addListener((state) {
      notifyListeners();
    });
  }
}
