import 'package:flutter/material.dart';
import 'package:case_go/core/theme/app_palete.dart';

/// 3D-кнопка в стиле Duolingo с «губой» (extruded lip).
///
/// При нажатии: translateY(lipH) + убираем lip-тень → эффект «прожатия».
///
/// Цветовые схемы: primary | warm | yellow | surface | ink | soft
class ClayButton extends StatefulWidget {
  final Widget child;
  final String colorScheme;  // 'primary' | 'warm' | 'yellow' | 'surface' | 'ink' | 'soft'
  final ClayButtonSize size;
  final bool fullWidth;
  final Widget? leadingIcon;
  final VoidCallback? onTap;

  const ClayButton({
    super.key,
    required this.child,
    this.colorScheme = 'primary',
    this.size = ClayButtonSize.lg,
    this.fullWidth = false,
    this.leadingIcon,
    this.onTap,
  });

  /// Именованный конструктор — primary (зелёный)
  const ClayButton.primary({
    super.key,
    required this.child,
    this.size = ClayButtonSize.lg,
    this.fullWidth = false,
    this.leadingIcon,
    this.onTap,
  }) : colorScheme = 'primary';

  /// Именованный конструктор — warm (оранжевый)
  const ClayButton.warm({
    super.key,
    required this.child,
    this.size = ClayButtonSize.lg,
    this.fullWidth = false,
    this.leadingIcon,
    this.onTap,
  }) : colorScheme = 'warm';

  /// Именованный конструктор — yellow (XP / золотой)
  const ClayButton.yellow({
    super.key,
    required this.child,
    this.size = ClayButtonSize.lg,
    this.fullWidth = false,
    this.leadingIcon,
    this.onTap,
  }) : colorScheme = 'yellow';

  /// Именованный конструктор — surface (кремовый / вторичный)
  const ClayButton.surface({
    super.key,
    required this.child,
    this.size = ClayButtonSize.lg,
    this.fullWidth = false,
    this.leadingIcon,
    this.onTap,
  }) : colorScheme = 'surface';

  @override
  State<ClayButton> createState() => _ClayButtonState();
}

enum ClayButtonSize { sm, md, lg }

class _ClayButtonState extends State<ClayButton> {
  bool _pressed = false;

  // ── Цветовые схемы (bg, lip, text) ────────────────────────────────────────
  static const _schemes = {
    'primary': (
      bg: AppPalette.primary,
      lip: AppPalette.primaryDeep,
      fg: Color(0xFFFAF6EC),
    ),
    'warm': (
      bg: AppPalette.accentWarm,
      lip: AppPalette.accentDeep,
      fg: Colors.white,
    ),
    'yellow': (
      bg: AppPalette.accentYellow,
      lip: AppPalette.accentYellowDeep,
      fg: Color(0xFF3A2A0A),
    ),
    'surface': (
      bg: Color(0xFFFAF6EC),
      lip: Color(0xFFD9D2BE),
      fg: AppPalette.ink,
    ),
    'ink': (
      bg: AppPalette.ink,
      lip: Color(0xFF0E1A12),
      fg: Color(0xFFFAF6EC),
    ),
    'soft': (
      bg: AppPalette.primaryTint,
      lip: Color(0xFFB5CCB7),
      fg: AppPalette.primaryDeep,
    ),
  };

  // ── Размерные параметры ────────────────────────────────────────────────────
  static const _sizes = {
    ClayButtonSize.lg: (h: 60.0, px: 22.0, fs: 17.0, lip: 6.0, r: 20.0),
    ClayButtonSize.md: (h: 50.0, px: 18.0, fs: 15.0, lip: 5.0, r: 16.0),
    ClayButtonSize.sm: (h: 40.0, px: 14.0, fs: 13.0, lip: 4.0, r: 12.0),
  };

  @override
  Widget build(BuildContext context) {
    final scheme = _schemes[widget.colorScheme] ?? _schemes['primary']!;
    final sz = _sizes[widget.size]!;
    final lipH = sz.lip;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        width: widget.fullWidth ? double.infinity : null,
        height: sz.h,
        transform: Matrix4.translationValues(
            0, _pressed ? lipH : 0, 0),
        decoration: BoxDecoration(
          color: scheme.bg,
          borderRadius: BorderRadius.circular(sz.r),
          boxShadow: _pressed
              ? null
              : [
                  // «Губа» — твёрдая тень цвета lip
                  BoxShadow(
                    color: scheme.lip,
                    offset: Offset(0, lipH),
                    blurRadius: 0,
                  ),
                  // Ambient drop shadow
                  BoxShadow(
                    color: const Color(0x2E1A2E22),
                    offset: Offset(0, lipH + 6),
                    blurRadius: 14,
                    spreadRadius: -4,
                  ),
                  // Верхний inner highlight
                  const BoxShadow(
                    color: Color(0x38FFFFFF),
                    offset: Offset(0, 2),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: sz.px),
          child: Row(
            mainAxisSize:
                widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.leadingIcon != null) ...[
                widget.leadingIcon!,
                const SizedBox(width: 10),
              ],
              DefaultTextStyle(
                style: TextStyle(
                  fontFamily: 'Onest',
                  fontFamilyFallback: const ['Roboto'],
                  color: scheme.fg,
                  fontSize: sz.fs,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.005,
                  height: 1,
                ),
                child: widget.child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inset-стиль для полей ввода (clay-inset)
class ClayInset extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;

  const ClayInset({
    super.key,
    required this.child,
    this.radius = 16,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppPalette.bg2,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A1A2E22),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
          // Нижний highlight (имитация inset)
          BoxShadow(
            color: Color(0xB3FFFFFF),
            blurRadius: 0,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: child,
    );
  }
}
