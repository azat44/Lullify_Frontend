import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lullify_mobile/core/theme/app_colors.dart';
import 'package:lullify_mobile/presentation/providers/stream_provider.dart';
import 'package:lullify_mobile/presentation/widgets/lullify_app_bar.dart';
import 'package:lullify_mobile/presentation/widgets/stream_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streamState = ref.watch(streamListProvider);

    return Scaffold(
      appBar: const LullifyAppBar(title: 'Lullify'),
      body: RefreshIndicator(
        onRefresh: () => ref.read(streamListProvider.notifier).refresh(),
        color: AppColors.violet,
        backgroundColor: AppColors.surface,
        child: switch (streamState) {
          StreamListInitial() || StreamListLoading() => _buildSkeleton(),
          StreamListLoaded(:final streams) => streams.isEmpty
              ? _buildEmpty(context)
              : _buildList(streams),
          StreamListError(:final message) => _buildError(context, message, ref),
        },
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      itemCount: 4,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (_, __) => const StreamCardSkeleton(),
    );
  }

  Widget _buildList(streams) {
    return ListView.builder(
      itemCount: streams.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final stream = streams[index];
        return StreamCard(
          stream: stream,
          onTap: stream.isLive ? () {} : null,
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.radio_rounded, size: 64,
              color: AppColors.violet.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('No live streams', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Pull to refresh', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String message, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 48,
              color: AppColors.hotPink.withValues(alpha: 0.7)),
          const SizedBox(height: 16),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.read(streamListProvider.notifier).refresh(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}