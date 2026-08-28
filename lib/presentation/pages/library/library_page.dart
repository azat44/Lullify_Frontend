import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lullify_mobile/core/router/app_router.dart';
import 'package:lullify_mobile/core/theme/app_colors.dart';
import 'package:lullify_mobile/presentation/widgets/lullify_app_bar.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LullifyAppBar(title: 'Library'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _LibraryTile(
            icon: Icons.favorite_rounded,
            color: AppColors.neonPink,
            title: 'Favorites',
            subtitle: 'Streams you saved',
            onTap: () => context.push(AppRoutes.favorites),
          ),
          const SizedBox(height: 12),
          _LibraryTile(
            icon: Icons.history_rounded,
            color: AppColors.neonCyan,
            title: 'Listening history',
            subtitle: 'Tracks you played',
            onTap: () => context.push(AppRoutes.history),
          ),
        ],
      ),
    );
  }
}

class _LibraryTile extends StatelessWidget {
  const _LibraryTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}