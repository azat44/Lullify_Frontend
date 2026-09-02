    import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lullify_mobile/core/theme/app_colors.dart';
import 'package:lullify_mobile/domain/entities/history_entry.dart';
import 'package:lullify_mobile/presentation/providers/history_provider.dart';
import 'package:lullify_mobile/presentation/widgets/history_tile.dart';
import 'package:lullify_mobile/presentation/widgets/lullify_app_bar.dart';

class ListeningHistoryPage extends ConsumerWidget {
  const ListeningHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(historyProvider);

    return Scaffold(
      appBar: const LullifyAppBar(
        title: 'Listening history',
        showBackButton: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(historyProvider.notifier).refresh(),
        color: AppColors.violet,
        backgroundColor: AppColors.surface,
        child: switch (state) {
          HistoryInitial() || HistoryLoading() => _buildSkeleton(),
          HistoryLoaded(:final entries) => entries.isEmpty
              ? _buildEmpty(context)
              : _buildList(context, entries),
          HistoryError(:final message) => _buildError(context, message, ref),
        },
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      itemCount: 6,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (_, __) => const HistoryTileSkeleton(),
    );
  }

  Widget _buildList(BuildContext context, List<HistoryEntry> entries) {
    // Le back renvoie déjà trié par played_at DESC (idx_listening_history).
    final items = _flatten(_groupByDay(entries));

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return switch (item) {
          _HeaderItem(:final label) => _SectionHeader(label: label),
          _EntryItem(:final entry) => HistoryTile(entry: entry),
        };
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    // ListView (et pas Center) pour garder le pull-to-refresh actif à vide.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.28),
        Icon(
          Icons.history_rounded,
          size: 64,
          color: AppColors.neonCyan.withValues(alpha: 0.4),
        ),
        const SizedBox(height: 16),
        Text(
          'No listening history yet',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Tracks you play will show up here',
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
            onPressed: () => ref.read(historyProvider.notifier).refresh(),
            child: const Text('Retry'),
          ),
        ),
      ],
    );
  }

  // ── Regroupement par jour ──────────────────────────────
  List<_DayGroup> _groupByDay(List<HistoryEntry> entries) {
    final Map<String, List<HistoryEntry>> byKey = {};
    final List<String> order = [];

    for (final e in entries) {
      final local = e.playedAt.toLocal();
      final key = DateFormat('yyyy-MM-dd').format(local);
      if (!byKey.containsKey(key)) {
        byKey[key] = [];
        order.add(key);
      }
      byKey[key]!.add(e);
    }

    return order
        .map((k) => _DayGroup(
              label: _dayLabel(byKey[k]!.first.playedAt.toLocal()),
              entries: byKey[k]!,
            ))
        .toList();
  }

  List<_ListItem> _flatten(List<_DayGroup> groups) {
    final items = <_ListItem>[];
    for (final g in groups) {
      items.add(_HeaderItem(g.label));
      items.addAll(g.entries.map(_EntryItem.new));
    }
    return items;
  }

  String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(day.year, day.month, day.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('EEEE, MMM d').format(day);
  }
}

// ── En-tête de section ───────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
      ),
    );
  }
}

// ── Items de liste (header | entrée) ─────────────────────
sealed class _ListItem {
  const _ListItem();
}
class _HeaderItem extends _ListItem {
  const _HeaderItem(this.label);
  final String label;
}
class _EntryItem extends _ListItem {
  const _EntryItem(this.entry);
  final HistoryEntry entry;
}

class _DayGroup {
  const _DayGroup({required this.label, required this.entries});
  final String label;
  final List<HistoryEntry> entries;
}