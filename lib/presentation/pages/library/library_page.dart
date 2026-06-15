import 'package:flutter/material.dart';
import 'package:lullify_mobile/core/theme/app_colors.dart';
import 'package:lullify_mobile/presentation/widgets/lullify_app_bar.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LullifyAppBar(title: 'Library'),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.library_music_rounded, size: 64, color: AppColors.neonPink.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('Your library', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Playlists and favourites will appear here',
                style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
