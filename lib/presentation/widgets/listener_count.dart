import 'package:flutter/material.dart';
import 'package:lullify_mobile/core/theme/app_colors.dart';

class ListenerCount extends StatelessWidget {
  const ListenerCount({required this.count, super.key});

  final int count;

  String _formatted() {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.headphones_rounded,
          size: 14,
          color: AppColors.neonCyan.withValues(alpha: 0.9),
          shadows: [
            Shadow(
              color: AppColors.neonCyan.withValues(alpha: 0.6),
              blurRadius: 6,
            ),
          ],
        ),
        const SizedBox(width: 6),
        Text(
          _formatted(),
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                color: AppColors.neonCyan.withValues(alpha: 0.4),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }
}