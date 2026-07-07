import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Fonds ──────────────────────────────────────────────
  static const Color background   = Color(0xFF040325);
  static const Color deepNight    = Color(0xFF0A0820);
  static const Color surface      = Color(0xFF120F30);
  static const Color surfaceLight = Color(0xFF1C1840);

  // ── Palette vaporwave ──────────────────────────────────
  static const Color neonPink     = Color(0xFFFF8AC8);
  static const Color hotPink      = Color(0xFFFF5FB8);
  static const Color pink         = Color(0xFFFF3AA8);
  static const Color magentaPink  = Color(0xFFE85AB0);
  static const Color magenta      = Color(0xFFD44AE0);
  static const Color violet       = Color(0xFFB455F0);
  static const Color purple       = Color(0xFF9744EE);
  static const Color deepViolet   = Color(0xFF8A36F0);
  static const Color grape        = Color(0xFF8205DB);
  static const Color deepGrape    = Color(0xFF6E0AD4);
  static const Color deepPurple   = Color(0xFF4605EC);
  static const Color electricBlue = Color(0xFF2045E2);
  static const Color skyBlue      = Color(0xFF3B82F6);
  static const Color neonCyan     = Color(0xFF55EFD5);
  static const Color cyan         = Color(0xFF73EFF0);
  static const Color lightCyan    = Color(0xFF9CF7F3);

  // ── Raccourcis sémantiques ─────────────────────────────
  static const Color primary    = violet;
  static const Color secondary  = neonCyan;
  static const Color accent     = neonPink;

  // ── Texte ──────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFEEECFF);
  static const Color textSecondary = Color(0xFF9896C8);
  static const Color textMuted     = Color(0xFF5A587A);

  // ── États ──────────────────────────────────────────────
  static const Color error   = hotPink;
  static const Color success = neonCyan;
  static const Color warning = Color(0xFFE8C870);
  static const Color live    = neonPink;

  // ── Gradients vaporwave ────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [violet, neonCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pinkPurpleGradient = LinearGradient(
    colors: [hotPink, deepViolet],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [deepNight, surface],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}