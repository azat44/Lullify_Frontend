import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lullify_mobile/core/network/dio_client.dart';
import 'package:lullify_mobile/core/theme/app_colors.dart';
import 'package:lullify_mobile/presentation/providers/stream_provider.dart';
import 'package:lullify_mobile/presentation/widgets/live_badge.dart';
import 'package:lullify_mobile/presentation/widgets/lullify_app_bar.dart';

// ── State ─────────────────────────────────────────────────────────────────────

sealed class BroadcasterState {
  const BroadcasterState();
}
class BroadcasterIdle    extends BroadcasterState { const BroadcasterIdle(); }
class BroadcasterLoading extends BroadcasterState { const BroadcasterLoading(); }
class BroadcasterLive    extends BroadcasterState {
  const BroadcasterLive({required this.streamId, required this.streamTitle});
  final String streamId;
  final String streamTitle;
}
class BroadcasterError   extends BroadcasterState {
  const BroadcasterError(this.message);
  final String message;
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class BroadcasterNotifier extends StateNotifier<BroadcasterState> {
  BroadcasterNotifier(this._dio, this._ref) : super(const BroadcasterIdle()) {
    // TODO Sprint 6 : restaurer l'état live si l'utilisateur a déjà un stream actif
    // Nécessite GET /api/v1/streams/mine (à implémenter côté Go)
  }

  final Dio _dio;
  final Ref _ref;

  Future<void> createAndStart({
    required String title,
    required String description,
    required String mountPoint,
  }) async {
    state = const BroadcasterLoading();
    try {
      final createRes = await _dio.post('/streams', data: {
        'title': title,
        'description': description,
        'mount_point': mountPoint,
      });
      final streamId = createRes.data['stream']['id'] as String;

      await _dio.post('/streams/$streamId/start');

      // Invalide la liste des streams pour forcer un refresh du home
      _ref.invalidate(streamListProvider);

      state = BroadcasterLive(streamId: streamId, streamTitle: title);
    } on DioException catch (e) {
      final msg = e.response?.data['error'] as String? ?? 'Failed to start stream';
      state = BroadcasterError(msg);
    } catch (e) {
      state = BroadcasterError('Unexpected error: $e');
    }
  }

  Future<void> stop() async {
    final current = state;
    if (current is! BroadcasterLive) return;

    state = const BroadcasterLoading();
    try {
      await _dio.post('/streams/${current.streamId}/stop');

      // Invalide aussi au stop
      _ref.invalidate(streamListProvider);

      state = const BroadcasterIdle();
    } on DioException catch (e) {
      final msg = e.response?.data['error'] as String? ?? 'Failed to stop stream';
      state = BroadcasterError(msg);
    }
  }
}

final broadcasterProvider =
StateNotifierProvider<BroadcasterNotifier, BroadcasterState>(
      (ref) => BroadcasterNotifier(ref.read(dioProvider), ref),
);

// ── Page ──────────────────────────────────────────────────────────────────────

class BroadcasterPage extends ConsumerStatefulWidget {
  const BroadcasterPage({super.key});

  @override
  ConsumerState<BroadcasterPage> createState() => _BroadcasterPageState();
}

class _BroadcasterPageState extends ConsumerState<BroadcasterPage> {
  final _titleController       = TextEditingController();
  final _descriptionController = TextEditingController();
  final _mountPointController  = TextEditingController();
  final _formKey               = GlobalKey<FormState>();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _mountPointController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(broadcasterProvider);
    final isLive = state is BroadcasterLive;
    final isLoading = state is BroadcasterLoading;

    ref.listen(broadcasterProvider, (_, next) {
      if (next is BroadcasterError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppColors.hotPink,
          ),
        );
      }
    });

    return Scaffold(
      appBar: const LullifyAppBar(title: 'Broadcast'),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: isLive
                ? _buildLiveView(context, state)
                : _buildSetupForm(context, isLoading),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveView(BuildContext context, BroadcasterLive state) {
    return Column(
      children: [
        const SizedBox(height: 40),
        const LiveBadge(isLive: true),
        const SizedBox(height: 24),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.pinkPurpleGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.hotPink.withValues(alpha: 0.5),
                blurRadius: 40,
                spreadRadius: 8,
              ),
            ],
          ),
          child: const Icon(Icons.radio_rounded, size: 56, color: Colors.white),
        ),
        const SizedBox(height: 24),
        Text(
          state.streamTitle,
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Your stream is live',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.neonCyan,
          ),
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () => ref.read(broadcasterProvider.notifier).stop(),
            icon: const Icon(Icons.stop_rounded),
            label: const Text('Stop Stream'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.hotPink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSetupForm(BuildContext context, bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Start a stream', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          Text('Fill in the details and go live', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 32),
          _field(
            label: 'TITLE',
            hint: 'My lo-fi radio',
            controller: _titleController,
            action: TextInputAction.next,
            validator: (v) => (v == null || v.isEmpty) ? 'Title is required' : null,
          ),
          const SizedBox(height: 20),
          _field(
            label: 'DESCRIPTION',
            hint: 'Chill beats to study to',
            controller: _descriptionController,
            action: TextInputAction.next,
          ),
          const SizedBox(height: 20),
          _field(
            label: 'STREAM URL',
            hint: 'my-stream',
            controller: _mountPointController,
            action: TextInputAction.done,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Mount point is required';
              if (v.contains(' ')) return 'No spaces allowed';
              return null;
            },
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : _submit,
              icon: isLoading
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Icon(Icons.radio_rounded),
              label: Text(isLoading ? 'Starting...' : 'Go Live'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.violet,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputAction action = TextInputAction.next,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          textInputAction: action,
          validator: validator,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(broadcasterProvider.notifier).createAndStart(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      mountPoint: _mountPointController.text.trim(),
    );
  }
}