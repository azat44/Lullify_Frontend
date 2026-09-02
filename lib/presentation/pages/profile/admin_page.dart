import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lullify_mobile/core/network/dio_client.dart';
import 'package:lullify_mobile/core/theme/app_colors.dart';
import 'package:lullify_mobile/domain/entities/user.dart';
import 'package:lullify_mobile/presentation/widgets/lullify_app_bar.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class _AdminUser {
  const _AdminUser({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  final String id;
  final String username;
  final String email;
  final String role;
  final DateTime createdAt;

  factory _AdminUser.fromJson(Map<String, dynamic> json) => _AdminUser(
    id: json['id'] as String,
    username: json['username'] as String,
    email: json['email'] as String,
    role: json['role'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

class _AdminStats {
  const _AdminStats({
    required this.totalUsers,
    required this.admins,
    required this.broadcasters,
    required this.listeners,
  });

  final int totalUsers;
  final int admins;
  final int broadcasters;
  final int listeners;

  factory _AdminStats.fromJson(Map<String, dynamic> json) => _AdminStats(
    totalUsers: json['total_users'] as int? ?? 0,
    admins: json['admins'] as int? ?? 0,
    broadcasters: json['broadcasters'] as int? ?? 0,
    listeners: json['listeners'] as int? ?? 0,
  );
}

// ── State ─────────────────────────────────────────────────────────────────────

sealed class _AdminState {
  const _AdminState();
}
class _AdminLoading extends _AdminState { const _AdminLoading(); }
class _AdminLoaded  extends _AdminState {
  const _AdminLoaded({required this.users, required this.stats});
  final List<_AdminUser> users;
  final _AdminStats stats;
}
class _AdminError   extends _AdminState {
  const _AdminError(this.message);
  final String message;
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class _AdminNotifier extends StateNotifier<_AdminState> {
  _AdminNotifier(this._dio) : super(const _AdminLoading()) {
    load();
  }

  final Dio _dio;

  Future<void> load() async {
    state = const _AdminLoading();
    try {
      final usersRes = await _dio.get('/admin/users');
      final statsRes = await _dio.get('/admin/stats');

      final users = (usersRes.data['users'] as List<dynamic>)
          .map((e) => _AdminUser.fromJson(e as Map<String, dynamic>))
          .toList();

      final stats = _AdminStats.fromJson(
          statsRes.data as Map<String, dynamic>);

      state = _AdminLoaded(users: users, stats: stats);
    } catch (e) {
      state = const _AdminError('Failed to load admin data');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _dio.delete('/admin/users/$userId');
      await load();
    } catch (e) {
      state = const _AdminError('Failed to delete user');
    }
  }
}

final _adminProvider =
StateNotifierProvider.autoDispose<_AdminNotifier, _AdminState>(
      (ref) => _AdminNotifier(ref.read(dioProvider)),
);

// ── Page ──────────────────────────────────────────────────────────────────────

class AdminPage extends ConsumerWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_adminProvider);

    return Scaffold(
      appBar: const LullifyAppBar(title: 'Admin', showBackButton: true),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: switch (state) {
          _AdminLoading() => const Center(
            child: CircularProgressIndicator(color: AppColors.violet),
          ),
          _AdminError(:final message) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 48, color: AppColors.hotPink.withValues(alpha: 0.7)),
                const SizedBox(height: 16),
                Text(message,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.read(_adminProvider.notifier).load(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          _AdminLoaded(:final users, :final stats) =>
              _AdminContent(users: users, stats: stats),
        },
      ),
    );
  }
}

class _AdminContent extends ConsumerWidget {
  const _AdminContent({required this.users, required this.stats});

  final List<_AdminUser> users;
  final _AdminStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Stats ────────────────────────────────────
        Text(
          'OVERVIEW',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatCard(label: 'Total', value: stats.totalUsers, color: AppColors.violet)),
            const SizedBox(width: 10),
            Expanded(child: _StatCard(label: 'Listeners', value: stats.listeners, color: AppColors.neonCyan)),
            const SizedBox(width: 10),
            Expanded(child: _StatCard(label: 'Broadcasters', value: stats.broadcasters, color: AppColors.neonPink)),
            const SizedBox(width: 10),
            Expanded(child: _StatCard(label: 'Admins', value: stats.admins, color: AppColors.hotPink)),
          ],
        ),
        const SizedBox(height: 28),

        // ── Users ────────────────────────────────────
        Text(
          'USERS (${users.length})',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        ...users.map((u) => _UserTile(
          user: u,
          onDelete: () => _confirmDelete(context, ref, u),
        )),
      ],
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, _AdminUser u) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete user',
            style: Theme.of(context).textTheme.titleMedium),
        content: Text(
          'Delete @${u.username}? This action cannot be undone.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(_adminProvider.notifier).deleteUser(u.id);
            },
            child: Text('Delete',
                style: TextStyle(color: AppColors.hotPink)),
          ),
        ],
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user, required this.onDelete});

  final _AdminUser user;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final roleColor = switch (user.role) {
      'admin'       => AppColors.hotPink,
      'broadcaster' => AppColors.violet,
      _             => AppColors.neonCyan,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(
        children: [
          // Avatar initiale
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: roleColor.withValues(alpha: 0.15),
              border: Border.all(color: roleColor.withValues(alpha: 0.4)),
            ),
            child: Center(
              child: Text(
                user.username.isNotEmpty
                    ? user.username[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: roleColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@${user.username}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  user.email,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Badge rôle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              user.role,
              style: TextStyle(
                color: roleColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Bouton supprimer
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            color: AppColors.textMuted,
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}