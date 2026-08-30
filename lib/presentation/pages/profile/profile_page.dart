import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lullify_mobile/core/router/app_router.dart';
import 'package:lullify_mobile/core/theme/app_colors.dart';
import 'package:lullify_mobile/domain/entities/user.dart';
import 'package:lullify_mobile/presentation/providers/auth_provider.dart';
import 'package:lullify_mobile/presentation/widgets/lullify_app_bar.dart';
import 'package:lullify_mobile/presentation/widgets/vaporwave_text_field.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: const LullifyAppBar(title: 'Profile'),
      body: switch (authState) {
        AuthSuccess(:final user) => _ProfileContent(user: user),
        _ => const _NotLoggedIn(),
      },
    );
  }
}

class _ProfileContent extends ConsumerStatefulWidget {
  const _ProfileContent({required this.user});
  final User user;

  @override
  ConsumerState<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends ConsumerState<_ProfileContent> {
  bool _showEditUsername = false;
  bool _showEditPassword = false;

  final _usernameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _usernameFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.user.username;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── Avatar ──────────────────────────────────
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.violet.withValues(alpha: 0.4),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.user.username.isNotEmpty
                      ? widget.user.username[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Nom + rôle ───────────────────────────────
          Text(
            widget.user.username,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Center(child: _RoleBadge(role: widget.user.role)),
          const SizedBox(height: 8),
          Text(
            widget.user.email,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 32),

          // ── Section édition ──────────────────────────
          const _SectionTitle(title: 'Account'),
          const SizedBox(height: 12),

          _SettingsTile(
            icon: Icons.person_outline_rounded,
            label: 'Username',
            value: widget.user.username,
            onTap: () => setState(() => _showEditUsername = !_showEditUsername),
          ),
          if (_showEditUsername) ...[
            const SizedBox(height: 12),
            Form(
              key: _usernameFormKey,
              child: Column(
                children: [
                  VaporwaveTextField(
                    label: 'NEW USERNAME',
                    hint: 'chill_vibes',
                    controller: _usernameController,
                    prefixIcon: Icons.person_outline_rounded,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v.length < 3) return 'At least 3 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_usernameFormKey.currentState!.validate()) {
                          // TODO : appel API PATCH /users/me quand endpoint dispo
                          setState(() => _showEditUsername = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Username updated')),
                          );
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.lock_outline_rounded,
            label: 'Password',
            value: '••••••••',
            onTap: () => setState(() => _showEditPassword = !_showEditPassword),
          ),
          if (_showEditPassword) ...[
            const SizedBox(height: 12),
            Form(
              key: _passwordFormKey,
              child: Column(
                children: [
                  VaporwaveTextField(
                    label: 'CURRENT PASSWORD',
                    hint: '••••••••',
                    controller: _currentPasswordController,
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: true,
                    validator: (v) =>
                    (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  VaporwaveTextField(
                    label: 'NEW PASSWORD',
                    hint: '••••••••',
                    controller: _newPasswordController,
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: true,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v.length < 8) return 'At least 8 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_passwordFormKey.currentState!.validate()) {
                          // TODO : appel API PATCH /users/me/password quand endpoint dispo
                          setState(() => _showEditPassword = false);
                          _currentPasswordController.clear();
                          _newPasswordController.clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password updated')),
                          );
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          const SizedBox(height: 24),

          // ── Session ──────────────────────────────────
          const _SectionTitle(title: 'Session'),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.hotPink,
                side: BorderSide(
                  color: AppColors.hotPink.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          // ── Admin (visible admin uniquement) ─────────
          if (widget.user.isAdmin) ...[
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Administration'),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.admin_panel_settings_rounded,
              label: 'Admin Panel',
              value: 'Manage users and stats',
              onTap: () => context.push(AppRoutes.admin),
            ),
          ],
        ],
      ),
    );
  }
}

class _NotLoggedIn extends StatelessWidget {
  const _NotLoggedIn();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_rounded,
            size: 64,
            color: AppColors.neonCyan.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text('Not logged in',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Sign in to access your profile and settings',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.violet.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 2),
                  Text(value, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.edit_rounded, color: AppColors.textMuted, size: 16),
          ],
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (role) {
      UserRole.admin       => ('Admin', AppColors.hotPink),
      UserRole.broadcaster => ('Broadcaster', AppColors.violet),
      UserRole.user        => ('Listener', AppColors.neonCyan),
      UserRole.anonymous   => ('Guest', AppColors.textMuted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}