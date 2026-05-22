import 'package:flutter/material.dart';

class AppPalette extends ThemeExtension<AppPalette> {
  // ── Обязательные поля (используются по всему приложению) ──────────────────
  final Color primaryBtn;   // главная CTA (зелёный)
  final Color contrastBg;   // основной тёмный текст/фон (ink)
  final Color altBtn;       // акцент-кнопка (оранжевый)
  final Color background;   // фон экрана
  final Color accent;       // жёлтый XP-акцент
  final Color surface;      // поверхность карточек (кремовый)

  const AppPalette({
    required this.primaryBtn,
    required this.contrastBg,
    required this.altBtn,
    required this.background,
    required this.accent,
    required this.surface,
  });

  // ── Sage palette (основная) ───────────────────────────────────────────────
  static const defaultPalette = AppPalette(
    primaryBtn:  Color(0xFF2D5F3F),  // --primary
    contrastBg:  Color(0xFF1A2E22),  // --ink
    altBtn:      Color(0xFFFF7A4A),  // --accent-warm
    background:  Color(0xFFEDE9E0),  // --bg
    accent:      Color(0xFFFFC857),  // --accent-yellow (XP)
    surface:     Color(0xFFFAF6EC),  // --surface (cards)
  );

  // ── Дополнительные статические токены ────────────────────────────────────

  // Цвета
  static const Color bg2          = Color(0xFFE2DCCB);  // inset-инпуты
  static const Color surface2     = Color(0xFFF4EFDF);  // alt surface
  static const Color ink          = Color(0xFF1A2E22);
  static const Color ink2         = Color(0xFF4A5147);  // вторичный текст
  static const Color ink3         = Color(0xFF8B9085);  // meta / labels
  static const Color line         = Color(0x141A2E22);  // rgba(26,46,34,0.08)

  static const Color primary      = Color(0xFF2D5F3F);
  static const Color primaryDeep  = Color(0xFF1F4A2E);  // lip для primary-кнопки
  static const Color primarySoft  = Color(0xFFA8D5BA);  // мятный fill
  static const Color primaryTint  = Color(0xFFD9EBDD);  // светло-зелёный

  static const Color accentWarm   = Color(0xFFFF7A4A);  // стрик / огонь
  static const Color accentDeep   = Color(0xFFD9512A);  // lip для warm
  static const Color accentSoft   = Color(0xFFFFD4BF);  // tint warm
  static const Color accentYellow = Color(0xFFFFC857);  // XP / монеты
  static const Color accentYellowDeep = Color(0xFFE5A82E);  // lip yellow
  static const Color accentPurple = Color(0xFF9B7DE0);  // лига / навыки

  // Цвета категорий кейсов
  static const Color catCommColor = Color(0xFF2D5F3F);
  static const Color catCommBg    = Color(0xFFA8D5BA);
  static const Color catLeadColor = Color(0xFFD9512A);
  static const Color catLeadBg    = Color(0xFFFFD4BF);
  static const Color catNegColor  = Color(0xFF5D4FC4);
  static const Color catNegBg     = Color(0xFFD9D2F4);
  static const Color catConfColor = Color(0xFFC49120);
  static const Color catConfBg    = Color(0xFFFFE9B3);

  // ── BoxDecoration-хелперы (claymorphism) ──────────────────────────────────

  /// Стандартная выпуклая карточка
  static BoxDecoration clay({
    required Color color,
    double radius = 20,
  }) =>
      BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x241A2E22),
            blurRadius: 24,
            offset: Offset(0, 12),
            spreadRadius: -8,
          ),
          BoxShadow(
            color: Color(0x0F1A2E22),
            blurRadius: 8,
            offset: Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      );

  /// Лёгкая карточка (chip, иконный контейнер)
  static BoxDecoration claySoft({
    required Color color,
    double radius = 20,
  }) =>
      BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A1A2E22),
            blurRadius: 14,
            offset: Offset(0, 6),
            spreadRadius: -6,
          ),
        ],
      );

  /// Глубокая карточка (hero, аватар)
  static BoxDecoration clayDeep({
    required Color color,
    double radius = 20,
  }) =>
      BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x381A2E22),
            blurRadius: 36,
            offset: Offset(0, 22),
            spreadRadius: -12,
          ),
          BoxShadow(
            color: Color(0x141A2E22),
            blurRadius: 14,
            offset: Offset(0, 8),
            spreadRadius: -6,
          ),
        ],
      );

  // ── ThemeExtension boilerplate ────────────────────────────────────────────

  @override
  ThemeExtension<AppPalette> copyWith({
    Color? primaryBtn,
    Color? contrastBg,
    Color? altBtn,
    Color? background,
    Color? accent,
    Color? surface,
  }) =>
      AppPalette(
        primaryBtn:  primaryBtn  ?? this.primaryBtn,
        contrastBg:  contrastBg  ?? this.contrastBg,
        altBtn:      altBtn      ?? this.altBtn,
        background:  background  ?? this.background,
        accent:      accent      ?? this.accent,
        surface:     surface     ?? this.surface,
      );

  @override
  ThemeExtension<AppPalette> lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      primaryBtn:  Color.lerp(primaryBtn,  other.primaryBtn,  t)!,
      contrastBg:  Color.lerp(contrastBg,  other.contrastBg,  t)!,
      altBtn:      Color.lerp(altBtn,      other.altBtn,      t)!,
      background:  Color.lerp(background,  other.background,  t)!,
      accent:      Color.lerp(accent,      other.accent,      t)!,
      surface:     Color.lerp(surface,     other.surface,     t)!,
    );
  }
}
