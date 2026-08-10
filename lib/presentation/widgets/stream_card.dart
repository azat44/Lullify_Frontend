import 'package:flutter/material.dart';
import 'package:lullify_mobile/core/theme/app_colors.dart';
import 'package:lullify_mobile/domain/entities/stream.dart';
import 'package:lullify_mobile/presentation/widgets/listener_count.dart';
import 'package:lullify_mobile/presentation/widgets/live_badge.dart';

class StreamCard extends StatelessWidget {
  const StreamCard({
    required this.stream,
    this.onTap,
    super.key,
  });

  final AudioStream stream;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: stream.isLive
                ? AppColors.violet.withValues(alpha: 0.4)
                : AppColors.surfaceLight,
            width: 1,
          ),
          boxShadow: stream.isLive
              ? [
            BoxShadow(
              color: AppColors.violet.withValues(alpha: 0.15),
              blurRadius: 16,
              spreadRadius: 0,
            ),
          ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // ── Avatar / icône ──────────────────────────
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: stream.isLive
                      ? AppColors.pinkPurpleGradient
                      : LinearGradient(
                    colors: [
                      AppColors.surfaceLight,
                      AppColors.surfaceLight,
                    ],
                  ),
                ),
                child: Icon(
                  Icons.radio_rounded,
                  color: stream.isLive
                      ? Colors.white
                      : AppColors.textMuted,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),

              // ── Infos ───────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre + badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            stream.title,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        LiveBadge(isLive: stream.isLive),
                      ],
                    ),
                    if (stream.description != null &&
                        stream.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        stream.description!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Listener count
                    if (stream.isLive)
                      ListenerCount(count: stream.listenerCount),
                  ],
                ),
              ),

              // ── Chevron ─────────────────────────────────
              if (stream.isLive)
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.violet.withValues(alpha: 0.6),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Skeleton loading ─────────────────────────────────────────────────────────

class StreamCardSkeleton extends StatefulWidget {
  const StreamCardSkeleton({super.key});

  @override
  State<StreamCardSkeleton> createState() => _StreamCardSkeletonState();
}

class _StreamCardSkeletonState extends State<StreamCardSkeleton>
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
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceLight),
          ),
          child: Row(
            children: [
              // Avatar skeleton
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight
                      .withValues(alpha: _shimmer.value),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre skeleton
                    Container(
                      height: 14,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight
                            .withValues(alpha: _shimmer.value),
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Description skeleton
                    Container(
                      height: 11,
                      width: 140,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight
                            .withValues(alpha: _shimmer.value * 0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}