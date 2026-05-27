import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lullify_mobile/core/router/app_router.dart';
import 'package:lullify_mobile/core/theme/app_colors.dart';

class MainShell extends StatelessWidget {
  const MainShell({required this.child, super.key});

  final Widget child;

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith(AppRoutes.explore)) return 1;
    if (location.startsWith(AppRoutes.library)) return 2;
    if (location.startsWith(AppRoutes.profile)) return 3;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0: context.go(AppRoutes.home);
      case 1: context.go(AppRoutes.explore);
      case 2: context.go(AppRoutes.library);
      case 3: context.go(AppRoutes.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.surfaceLight, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: index,
          onTap: (i) => _onTap(context, i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), label: 'Explore'),
            BottomNavigationBarItem(icon: Icon(Icons.library_music_outlined), label: 'Library'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
