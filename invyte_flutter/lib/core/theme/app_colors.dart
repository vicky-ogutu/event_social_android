import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand
  static const primary = Color(0xFFE91E63);
  static const primaryDeep = Color(0xFFC2185B);
  static const violet = Color(0xFF7C3AED);
  static const indigo = Color(0xFF4F46E5);

  // Semantic
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFDC2626);
  static const info = Color(0xFF2563EB);
  static const star = Color(0xFFFFB020);
  static const live = Color(0xFFFF3B30);

  // Neutrals
  static const ink = Color(0xFF14121F);
  static const inkMuted = Color(0xFF6B6880);
  static const canvasLight = Color(0xFFF6F5FA);
  static const lineLight = Color(0xFFE8E6F0);
  static const canvasDark = Color(0xFF0E0D15);
  static const surfaceDark = Color(0xFF181624);
  static const lineDark = Color(0xFF2A2738);

  static const brandGradient = LinearGradient(
    colors: [Color(0xFFFF3D7F), primary, violet],
    stops: [0, 0.45, 1],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const nightGradient = LinearGradient(
    colors: [Color(0xFF1F1147), Color(0xFF3B0F3A), Color(0xFF14121F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const scrim = LinearGradient(
    colors: [Colors.transparent, Color(0xCC000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Stable accent per category / name, for avatars and placeholders.
  static const _accents = [
    Color(0xFFE91E63),
    Color(0xFF7C3AED),
    Color(0xFF0EA5E9),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF6366F1),
    Color(0xFF14B8A6),
  ];

  static Color accentFor(String seed) =>
      _accents[seed.codeUnits.fold<int>(0, (a, b) => a + b) % _accents.length];
}
