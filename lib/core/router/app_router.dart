import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lullify_mobile/presentation/pages/home/home_page.dart';
import 'package:lullify_mobile/presentation/pages/explore/explore_page.dart';
import 'package:lullify_mobile/presentation/pages/library/library_page.dart';
import 'package:lullify_mobile/presentation/pages/profile/profile_page.dart';
import 'package:lullify_mobile/presentation/widgets/main_shell.dart';

class AppRoutes {
  AppRoutes._();
  static const String home = '/';
  static const String explore = '/explore';
  static const String library = '/library';
  static const String profile = '/profile';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) => const NoTransitionPage(child: HomePage()),
          ),
          GoRoute(
            path: AppRoutes.explore,
            pageBuilder: (context, state) => const NoTransitionPage(child: ExplorePage()),
          ),
          GoRoute(
            path: AppRoutes.library,
            pageBuilder: (context, state) => const NoTransitionPage(child: LibraryPage()),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) => const NoTransitionPage(child: ProfilePage()),
          ),
        ],
      ),
    ],
  );
});
