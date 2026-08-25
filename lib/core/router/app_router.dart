import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lullify_mobile/presentation/pages/auth/login_page.dart';
import 'package:lullify_mobile/presentation/pages/auth/register_page.dart';
import 'package:lullify_mobile/presentation/pages/home/home_page.dart';
import 'package:lullify_mobile/presentation/pages/explore/explore_page.dart';
import 'package:lullify_mobile/presentation/pages/library/library_page.dart';
import 'package:lullify_mobile/presentation/pages/profile/profile_page.dart';
import 'package:lullify_mobile/presentation/pages/splash/splash_page.dart';
import 'package:lullify_mobile/presentation/providers/auth_provider.dart';
import 'package:lullify_mobile/presentation/widgets/main_shell.dart';
import 'package:lullify_mobile/presentation/pages/broadcaster/broadcaster_dashboard_page.dart';
import 'package:lullify_mobile/presentation/pages/history/listening_history_page.dart';


class AppRoutes {
  AppRoutes._();
  static const String splash   = '/splash';
  static const String login    = '/login';
  static const String register = '/register';
  static const String home     = '/';
  static const String explore  = '/explore';
  static const String library  = '/library';
  static const String profile  = '/profile';
  static const String broadcaster = '/broadcaster';
  static const String history  = '/history';

}

const _publicRoutes = [AppRoutes.splash, AppRoutes.login, AppRoutes.register];

class _AuthRouterNotifier extends ChangeNotifier {
  _AuthRouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;

  AuthState get authState => _ref.read(authProvider);
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthRouterNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (context, state) {
      final location = state.uri.path;
      final isPublic = _publicRoutes.contains(location);
      final authState = notifier.authState;
      final isLoggedIn = authState is AuthSuccess;

      if (location == AppRoutes.splash) return null;
      if (isLoggedIn && isPublic) return AppRoutes.home;
      if (!isLoggedIn && !isPublic) return AppRoutes.login;

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) =>
        const NoTransitionPage(child: SplashPage()),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) =>
        const NoTransitionPage(child: LoginPage()),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (context, state) =>
        const NoTransitionPage(child: RegisterPage()),
      ),
      GoRoute(
        path: AppRoutes.history,
        pageBuilder: (context, state) =>
        const MaterialPage(child: ListeningHistoryPage()),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) =>
            const NoTransitionPage(child: HomePage()),
          ),
          GoRoute(
            path: AppRoutes.explore,
            pageBuilder: (context, state) =>
            const NoTransitionPage(child: ExplorePage()),
          ),
          GoRoute(
            path: AppRoutes.library,
            pageBuilder: (context, state) =>
            const NoTransitionPage(child: LibraryPage()),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) =>
            const NoTransitionPage(child: ProfilePage()),
          ),
          GoRoute(
            path: AppRoutes.broadcaster,
            pageBuilder: (context, state) =>
            const NoTransitionPage(child: BroadcasterDashboardPage()),
          ),
        ],
      ),
    ],
  );
});