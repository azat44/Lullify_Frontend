import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lullify_mobile/core/constants.dart';
import 'package:lullify_mobile/core/theme/app_colors.dart';
import 'package:lullify_mobile/domain/entities/stream.dart';
import 'package:lullify_mobile/presentation/providers/favorite_provider.dart';
import 'package:lullify_mobile/presentation/providers/history_provider.dart';
import 'package:lullify_mobile/presentation/providers/player_provider.dart';
import 'package:lullify_mobile/presentation/providers/stream_provider.dart';
import 'package:lullify_mobile/presentation/widgets/listener_count.dart';
import 'package:lullify_mobile/presentation/widgets/live_badge.dart';

class PlayerPage extends ConsumerStatefulWidget {
  const PlayerPage({required this.stream, super.key});

  final AudioStream stream;

  @override
  ConsumerState<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends ConsumerState<PlayerPage> {
  // Passe à true dès que le lecteur signale une erreur (ex: le diffuseur a
  // coupé le stream et le flux HLS n'est plus disponible). Le badge et les
  // contrôles s'appuient là-dessus plutôt que sur le statut figé passé à la
  // création de la page, qui ne bouge jamais tout seul.
  bool _streamEnded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final hlsUrl =
          '${AppConstants.apiBaseUrl.replaceAll('/api/v1', '')}/streams/${widget.stream.id}/playlist.m3u8';
          ref.read(playerProvider.notifier).play(
        streamId: widget.stream.id,
        streamTitle: widget.stream.title,
        hlsUrl: hlsUrl,
      );

      // Enregistre le début d'écoute dans l'historique. Ne bloque jamais la
      // lecture : si ça échoue (réseau, etc.), on l'ignore silencieusement.
      ref.read(historyRepositoryProvider).recordListen(
        trackTitle: widget.stream.title,
        artist: 'Lullify Radio',
        streamId: widget.stream.id,
      ).catchError((_) {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    // compteur d'auditeurs en temps réel
    final liveListeners = ref.watch(listenerCountProvider(widget.stream.id));
    final isFavorite = ref.watch(
      favoriteProvider.select((state) =>
          state is FavoriteLoaded &&
          state.favorites.any((f) => f.streamId == widget.stream.id)),
    );

    if (playerState is PlayerError && !_streamEnded) {
      // On évite de setState pendant le build : on le programme juste après.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _streamEnded = true);
      });
    }
    final isLiveNow = widget.stream.isLive && !_streamEnded;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── App bar ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded),
                      color: AppColors.textPrimary,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    LiveBadge(isLive: isLiveNow),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                      ),
                      color: isFavorite
                          ? AppColors.neonPink
                          : AppColors.textPrimary,
                      onPressed: () => ref
                          .read(favoriteProvider.notifier)
                          .toggle(widget.stream.id),
                    ),
                  ],
                ),
              ),

              if (_streamEnded)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 16, color: AppColors.textMuted),
                        const SizedBox(width: 8),
                        Text(
                          'Ce stream est terminé',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const Spacer(),

              // ── Logo / artwork ──────────────────────────
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: AppColors.pinkPurpleGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.violet.withValues(alpha: 0.5),
                      blurRadius: 60,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.radio_rounded,
                  size: 80,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 40),

              // ── Infos stream ────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Text(
                      widget.stream.title,
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.stream.description != null &&
                        widget.stream.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.stream.description!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 12),
                    ListenerCount(count: liveListeners),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // ── Contrôles ───────────────────────────────
              _buildControls(context, playerState),

              const SizedBox(height: 32),

              // ── Volume ──────────────────────────────────
              _buildVolume(context, playerState),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context, PlayerState playerState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Bouton stop
        IconButton(
          onPressed: () {
            ref.read(playerProvider.notifier).stop();
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.stop_rounded),
          color: AppColors.textSecondary,
          iconSize: 36,
        ),
        const SizedBox(width: 24),

        // Bouton play/pause principal
        GestureDetector(
          onTap: () {
            switch (playerState) {
              case PlayerPlaying():
                ref.read(playerProvider.notifier).pause();
              case PlayerPaused():
                ref.read(playerProvider.notifier).resume();
              default:
                break;
            }
          },
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.violet.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(
              switch (playerState) {
                PlayerLoading() => Icons.hourglass_empty_rounded,
                PlayerPlaying() => Icons.pause_rounded,
                _ => Icons.play_arrow_rounded,
              },
              color: Colors.white,
              size: 40,
            ),
          ),
        ),

        const SizedBox(width: 24),

        // Placeholder bouton droit
        const SizedBox(width: 36),
      ],
    );
  }

  Widget _buildVolume(BuildContext context, PlayerState playerState) {
    final volume = switch (playerState) {
      PlayerPlaying(:final volume) => volume,
      _ => 1.0,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          Icon(Icons.volume_down_rounded,
              color: AppColors.textMuted, size: 20),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppColors.violet,
                inactiveTrackColor: AppColors.surfaceLight,
                thumbColor: AppColors.violet,
                overlayColor: AppColors.violet.withValues(alpha: 0.2),
                thumbShape:
                const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                value: volume,
                onChanged: (v) =>
                    ref.read(playerProvider.notifier).setVolume(v),
              ),
            ),
          ),
          Icon(Icons.volume_up_rounded,
              color: AppColors.textMuted, size: 20),
        ],
      ),
    );
  }
}