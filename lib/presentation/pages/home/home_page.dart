import 'package:flutter/material.dart';
import 'package:lullify_mobile/core/theme/app_colors.dart';
import 'package:lullify_mobile/presentation/widgets/lullify_app_bar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LullifyAppBar(title: 'Lullify'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text('Good evening', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text('Relax and listen to live streams', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 32),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.radio_rounded, size: 64, color: AppColors.violet.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text('No live streams yet', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('Streams will appear here once broadcasters go live',
                          style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
