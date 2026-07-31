import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lullify_mobile/core/theme/app_colors.dart';
import 'package:lullify_mobile/domain/entities/stream.dart';
import 'package:lullify_mobile/presentation/providers/stream_provider.dart';
import 'package:lullify_mobile/presentation/widgets/listener_count.dart';
import 'package:lullify_mobile/presentation/widgets/live_badge.dart';
import 'package:lullify_mobile/presentation/widgets/lullify_app_bar.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(streamListProvider);

    return Scaffold(
      appBar: const LullifyAppBar(title: 'Lullify'),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(streamListProvider.notifier).refresh(),
          color: AppColors.neonCyan,
          backgroundColor: AppColors.surface,
          child: switch (state) {
            StreamListInitial() || StreamListLoading() => const _LoadingList(),
            StreamListLoaded(:final streams) => _StreamList(streams: streams),
            StreamListError(:final message) => _ErrorView(
                message: message,
                onRetry: () => ref.read(streamListProvider.notifier).refresh(),
              ),
          },
        ),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, __) => Container(
        height: 92,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.violet.withValues(alpha: 0.15)),
        ),
      ),
    );
  }
}

class _StreamList extends StatelessWidget {
  const _StreamList({required this.streams});

  final List<AudioStream> streams;

  @override
  Widget build(BuildContext context) {
    if (streams.isEmpty) {
      return const _EmptyView();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: streams.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _StreamCard(stream: streams[index]),
    );
  }
}

class _StreamCard extends StatelessWidget {
  const _StreamCard({required this.stream});

  final AudioStream stream;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: stream.isLive
              ? AppColors.hotPink.withValues(alpha: 0.4)
              : AppColors.violet.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LiveBadge(isLive: stream.isLive),
              const Spacer(),
              if (stream.isLive) ListenerCount(count: stream.listenerCount),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            stream.title,
            style: Theme.of(context).textTheme.titleLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (stream.description != null) ...[
            const SizedBox(height: 4),
            Text(
              stream.description!,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(40),
      children: [
        const SizedBox(height: 80),
        Icon(
          Icons.radio_rounded,
          size: 64,
          color: AppColors.violet.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 16),
        Text(
          'No live streams yet',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Pull down to refresh',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(40),
      children: [
        const SizedBox(height: 80),
        Icon(
          Icons.error_outline_rounded,
          size: 64,
          color: AppColors.hotPink.withValues(alpha: 0.7),
        ),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 24),
        Center(
          child: OutlinedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}