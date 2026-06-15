import 'package:flutter/material.dart';
import 'package:lullify_mobile/core/theme/app_colors.dart';
import 'package:lullify_mobile/presentation/widgets/lullify_app_bar.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LullifyAppBar(title: 'Explore'),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.explore_rounded, size: 64, color: AppColors.skyBlue.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('Explore streams', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Browse active streams and discover new music',
                style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
