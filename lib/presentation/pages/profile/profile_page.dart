import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lullify_mobile/core/router/app_router.dart';
import 'package:lullify_mobile/core/theme/app_colors.dart';
import 'package:lullify_mobile/presentation/widgets/lullify_app_bar.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LullifyAppBar(title: 'Profile'),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_rounded, size: 64, color: AppColors.neonCyan.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('Not logged in', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Sign in to access your profile and settings',
                style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            // Bouton temporaire pour tester l'espace diffuseur.
            ElevatedButton.icon(
              onPressed: () => context.go(AppRoutes.broadcaster),
              icon: const Icon(Icons.podcasts_rounded),
              label: const Text('Espace diffuseur'),
            ),
          ],
        ),
      ),
    );
  }
}