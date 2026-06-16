import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lullify_mobile/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:lullify_mobile/core/router/app_router.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnim = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _glowAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1, curve: Curves.easeOut),
      ),
    );

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _controller.forward().then((_) {
      if (mounted) {
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.edgeToEdge,
        );
        context.go(AppRoutes.home);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo pixel art placeholder — à remplacer par ton asset
                  Transform.scale(
                    scale: _scaleAnim.value,
                    child: Opacity(
                      opacity: _fadeAnim.value,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: const LinearGradient(
                            colors: [AppColors.violet, AppColors.neonCyan],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.violet.withValues(
                                alpha: _glowAnim.value * 0.8,
                              ),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                            BoxShadow(
                              color: AppColors.neonCyan.withValues(
                                alpha: _glowAnim.value * 0.4,
                              ),
                              blurRadius: 60,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.headphones_rounded,
                          size: 52,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Titre
                  Opacity(
                    opacity: _fadeAnim.value,
                    child: Text(
                      'LULLIFY',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppColors.textPrimary,
                        letterSpacing: 8,
                        shadows: [
                          Shadow(
                            color: AppColors.violet.withValues(
                              alpha: _glowAnim.value,
                            ),
                            blurRadius: 20,
                          ),
                          Shadow(
                            color: AppColors.neonCyan.withValues(
                              alpha: _glowAnim.value * 0.5,
                            ),
                            blurRadius: 40,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Opacity(
                    opacity: _fadeAnim.value,
                    child: Text(
                      'lo-fi radio • live streams',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
