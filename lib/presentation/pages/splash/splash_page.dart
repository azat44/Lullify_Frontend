import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lullify_mobile/core/router/app_router.dart';
import 'package:lullify_mobile/core/theme/app_colors.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
      ),
    );

    _logoScale = Tween<double>(begin: 0.85, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );

    _textFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.6, curve: Curves.easeIn),
      ),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
      ),
    );

    _glowAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );

    _controller.forward().then((_) {
      if (mounted) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        context.go(AppRoutes.login);
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
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Logo animé (spritesheet) ────────────────
                Transform.scale(
                  scale: _logoScale.value,
                  child: Opacity(
                    opacity: _logoFade.value,
                    child: _SpriteAnimation(glowValue: _glowAnim.value),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Texte PNG ───────────────────────────────
                SlideTransition(
                  position: _textSlide,
                  child: Opacity(
                    opacity: _textFade.value,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.violet.withValues(
                              alpha: _glowAnim.value * 0.5,
                            ),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      // Pas de height fixe — Flutter calcule le ratio tout seul
                      child: Image.asset(
                        'assets/images/Lullify_Text.png',
                        width: 200,
                        filterQuality: FilterQuality.none,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Sprite animation ──────────────────────────────────────────────────────────

class _SpriteAnimation extends StatefulWidget {
  const _SpriteAnimation({required this.glowValue});

  final double glowValue;

  @override
  State<_SpriteAnimation> createState() => _SpriteAnimationState();
}

class _SpriteAnimationState extends State<_SpriteAnimation> {
  // Dimensions réelles de la spritesheet
  static const int _frameCount = 9;
  static const double _sheetWidth = 2052;
  static const double _sheetHeight = 156;
  static const double _frameWidth = _sheetWidth / _frameCount; // = 228
  static const Duration _frameDuration = Duration(milliseconds: 150);

  // Taille d'affichage souhaitée
  static const double _displayWidth = 200;
  static const double _displayHeight = _displayWidth * (_sheetHeight / _frameWidth);

  // Ratio de mise à l'échelle
  static const double _scale = _displayWidth / _frameWidth;

  int _currentFrame = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_frameDuration, (_) {
      if (mounted) {
        setState(() {
          _currentFrame = (_currentFrame + 1) % _frameCount;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _displayWidth,
      height: _displayHeight,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.violet.withValues(alpha: widget.glowValue * 0.7),
            blurRadius: 50,
            spreadRadius: 8,
          ),
          BoxShadow(
            color: AppColors.neonCyan.withValues(alpha: widget.glowValue * 0.3),
            blurRadius: 80,
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.centerLeft,
          maxWidth: _sheetWidth * _scale,
          maxHeight: _displayHeight,
          child: Transform.translate(
            offset: Offset(-_currentFrame * _displayWidth, 0),
            child: Image.asset(
              'assets/images/Lullify_Moon_Sheet.png',
              width: _sheetWidth * _scale,
              height: _displayHeight,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.none,
            ),
          ),
        ),
      ),
    );
  }
}