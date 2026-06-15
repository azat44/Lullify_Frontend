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
      bottomNavigationBar: _VaporwaveNavBar(
        currentIndex: index,
        onTap: (i) => _onTap(context, i),
      ),
    );
  }
}

class _VaporwaveNavBar extends StatelessWidget {
  const _VaporwaveNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final void Function(int) onTap;

  static const _items = [
    _NavItem(icon: Icons.home_rounded, outlinedIcon: Icons.home_outlined, label: 'Home'),
    _NavItem(icon: Icons.explore_rounded, outlinedIcon: Icons.explore_outlined, label: 'Explore'),
    _NavItem(icon: Icons.library_music_rounded, outlinedIcon: Icons.library_music_outlined, label: 'Library'),
    _NavItem(icon: Icons.person_rounded, outlinedIcon: Icons.person_outline_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.violet.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        // Glow subtil sur le bord supérieur
        boxShadow: [
          BoxShadow(
            color: AppColors.violet.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final selected = i == currentIndex;
              return Expanded(
                child: _NavBarItem(
                  item: item,
                  selected: selected,
                  onTap: () => onTap(i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.outlinedIcon,
    required this.label,
  });
  final IconData icon;
  final IconData outlinedIcon;
  final String label;
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: selected
                ? BoxDecoration(
              color: AppColors.violet.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.violet.withValues(alpha: 0.4),
                width: 1,
              ),
            )
                : null,
            child: Icon(
              selected ? item.icon : item.outlinedIcon,
              color: selected ? AppColors.violet : AppColors.textMuted,
              size: 22,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? AppColors.violet : AppColors.textMuted,
            ),
            child: Text(item.label),
          ),
        ],
      ),
    );
  }
}