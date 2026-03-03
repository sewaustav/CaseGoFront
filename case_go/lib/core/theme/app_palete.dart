import 'package:flutter/material.dart';

class AppPalette extends ThemeExtension<AppPalette> {
  final Color primaryBtn;
  final Color contrastBg;
  final Color altBtn;
  final Color background;

  const AppPalette({
    required this.primaryBtn,
    required this.contrastBg,
    required this.altBtn,
    required this.background,
  });

  // Предустановленная тема (твои текущие цвета)
  static const defaultPalette = AppPalette(
    primaryBtn: Color(0xFF156B5D),
    contrastBg: Color(0xFF1D2323),
    altBtn: Color(0xFFC4E860),
    background: Color(0xFFFFFFFF),
  );

  @override
  ThemeExtension<AppPalette> copyWith({
    Color? primaryBtn,
    Color? contrastBg,
    Color? altBtn,
    Color? background,
  }) {
    return AppPalette(
      primaryBtn: primaryBtn ?? this.primaryBtn,
      contrastBg: contrastBg ?? this.contrastBg,
      altBtn: altBtn ?? this.altBtn,
      background: background ?? this.background,
    );
  }

  @override
  ThemeExtension<AppPalette> lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      primaryBtn: Color.lerp(primaryBtn, other.primaryBtn, t)!,
      contrastBg: Color.lerp(contrastBg, other.contrastBg, t)!,
      altBtn: Color.lerp(altBtn, other.altBtn, t)!,
      background: Color.lerp(background, other.background, t)!,
    );
  }
}