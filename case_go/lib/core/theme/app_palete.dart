import 'package:flutter/material.dart';

class AppPalette extends ThemeExtension<AppPalette> {
  final Color primaryBtn;
  final Color contrastBg;
  final Color altBtn;
  final Color background;
  final Color accent;
  final Color surface;

  const AppPalette({
    required this.primaryBtn,
    required this.contrastBg,
    required this.altBtn,
    required this.background,
    required this.accent,
    required this.surface,
  });

  // ── Новая яркая Playful-тема ──────────────────────────────────────────────
  static const defaultPalette = AppPalette(
    primaryBtn: Color(0xFF6366F1),  // Индиго
    contrastBg: Color(0xFF1E1B4B),  // Тёмно-синий
    altBtn:     Color(0xFFF97316),  // Оранжевый
    background: Color(0xFFF8F7FF),  // Светлый лавандовый
    accent:     Color(0xFFEC4899),  // Розовый
    surface:    Color(0xFFEDE9FE),  // Светло-фиолетовый
  );

  // ── Статические градиенты ─────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFF97316), Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA855F7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  ThemeExtension<AppPalette> copyWith({
    Color? primaryBtn,
    Color? contrastBg,
    Color? altBtn,
    Color? background,
    Color? accent,
    Color? surface,
  }) {
    return AppPalette(
      primaryBtn: primaryBtn ?? this.primaryBtn,
      contrastBg: contrastBg ?? this.contrastBg,
      altBtn:     altBtn     ?? this.altBtn,
      background: background ?? this.background,
      accent:     accent     ?? this.accent,
      surface:    surface    ?? this.surface,
    );
  }

  @override
  ThemeExtension<AppPalette> lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      primaryBtn: Color.lerp(primaryBtn, other.primaryBtn, t)!,
      contrastBg: Color.lerp(contrastBg, other.contrastBg, t)!,
      altBtn:     Color.lerp(altBtn,     other.altBtn,     t)!,
      background: Color.lerp(background, other.background, t)!,
      accent:     Color.lerp(accent,     other.accent,     t)!,
      surface:    Color.lerp(surface,    other.surface,    t)!,
    );
  }
}