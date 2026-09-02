import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lullify_mobile/core/theme/app_colors.dart';
import 'package:lullify_mobile/domain/entities/favorite.dart';
import 'package:lullify_mobile/presentation/providers/favorite_provider.dart';
import 'package:lullify_mobile/presentation/widgets/lullify_app_bar.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(favoriteProvider);

    return Scaffold(
      appBar: const LullifyAppBar(
        title: 'Favorites',
        showBackButton: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(favoriteProvider.notifier).refresh(),
        color: AppColors.violet,
        backgroundColor: AppColors.surface,
        child: switch (state) {
          FavoriteInitial() || FavoriteLoading() => _buildSkeleton(),
          FavoriteLoaded(:final favorites) => favorites.isEmpty
              ? _buildEmpty(context)
              : _buildList(context, favorites, ref),
          FavoriteError(:final message) => _buildError(context, message, ref),
        },
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      itemCount: 5,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (_, __) => const _FavoriteTileSkeleton(),
    );
  }

  Widget _buildList(BuildContext context, List<Favorite> favorites, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: favorites.length,
      itemBuilder: (context, index) => _FavoriteTile(
        favorite: favorites[index],
        onRemove: () => ref
            .read(favoriteProvider.notifier)
            .toggle(favorites[index].streamId),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.28),
        Icon(
          Icons.favorite_border_rounded,
          size: 64,
          color: AppColors.neonPink.withValues(alpha: 0.4),
        ),
        const SizedBox(height: 16),
        Text(
          'No favorites yet',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Streams you favorite will appear here',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, String message, WidgetRef ref) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.28),
        Icon(
          Icons.error_outline_rounded,
          size: 48,
          color: AppColors.hotPink.withValues(alpha: 0.7),
        ),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton(
            onPressed: () => ref.read(favoriteProvider.notifier).refresh(),
            child: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}

class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({required this.favorite, required this.onRemove});

  final Favorite favorite;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.violet.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              gradient: AppColors.pinkPurpleGradient,
            ),
            child: const Icon(
              Icons.radio_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              favorite.streamId,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.favorite_rounded),
            color: AppColors.neonPink,
            iconSize: 22,
          ),
        ],
      ),
    );
  }
}

class _FavoriteTileSkeleton extends StatefulWidget {
  const _FavoriteTileSkeleton();

  @override
  State<_FavoriteTileSkeleton> createState() => _FavoriteTileSkeletonState();
}

class _FavoriteTileSkeletonState extends State<_FavoriteTileSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _shimmer = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.surfaceLight),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight.withValues(alpha: _shimmer.value),
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Container(
                  height: 13,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight.withValues(alpha: _shimmer.value),
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}