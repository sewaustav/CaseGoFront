import 'package:flutter/material.dart';
import 'package:case_go/core/theme/app_palete.dart';

/// Маскот «Кейси» — дружелюбный антропоморфный портфель.
///
/// Выражения: happy (default) | wow | wink | sleep | cheer
/// Анимации: blink (5.5s), float (3.4s), wobble (4s, только cheer)
class CaseyMascot extends StatefulWidget {
  final double size;
  final String expression;
  final Color? accentColor;
  final bool animate;

  const CaseyMascot({
    super.key,
    this.size = 120,
    this.expression = 'happy',
    this.accentColor,
    this.animate = true,
  });

  @override
  State<CaseyMascot> createState() => _CaseyMascotState();
}

class _CaseyMascotState extends State<CaseyMascot>
    with TickerProviderStateMixin {
  late final AnimationController _blinkCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _wobbleCtrl;

  late final Animation<double> _blinkAnim;
  late final Animation<double> _floatAnim;
  late final Animation<double> _wobbleAnim;

  @override
  void initState() {
    super.initState();

    // Blink: глаза моргают раз в 5.5 сек
    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    );
    _blinkAnim = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 92),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.1)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 2),
      TweenSequenceItem(tween: ConstantTween(0.1), weight: 4),
      TweenSequenceItem(
          tween: Tween(begin: 0.1, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 2),
    ]).animate(_blinkCtrl);

    // Float: плавное покачивание вверх-вниз на 6px
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    );
    _floatAnim = Tween<double>(begin: 0.0, end: -6.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    // Wobble: покачивание ±2° для выражения cheer
    _wobbleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    _wobbleAnim = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _wobbleCtrl, curve: Curves.easeInOut),
    );

    if (widget.animate) {
      _blinkCtrl.repeat();
      _floatCtrl.repeat(reverse: true);
      if (widget.expression == 'cheer') {
        _wobbleCtrl.repeat(reverse: true);
      }
    }
  }

  @override
  void didUpdateWidget(CaseyMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expression == 'cheer' && !_wobbleCtrl.isAnimating) {
      _wobbleCtrl.repeat(reverse: true);
    } else if (widget.expression != 'cheer' && _wobbleCtrl.isAnimating) {
      _wobbleCtrl.stop();
      _wobbleCtrl.reset();
    }
  }

  @override
  void dispose() {
    _blinkCtrl.dispose();
    _floatCtrl.dispose();
    _wobbleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette =
        Theme.of(context).extension<AppPalette>() ?? AppPalette.defaultPalette;
    final bodyColor = widget.accentColor ?? palette.primaryBtn;

    return AnimatedBuilder(
      animation: Listenable.merge([_blinkCtrl, _floatCtrl, _wobbleCtrl]),
      builder: (context, _) {
        final floatY = widget.animate ? _floatAnim.value : 0.0;
        final wobbleDeg = (widget.animate && widget.expression == 'cheer')
            ? _wobbleAnim.value
            : 0.0;

        return Transform.translate(
          offset: Offset(0, floatY),
          child: Transform.rotate(
            angle: wobbleDeg * 3.14159265 / 180.0,
            alignment: Alignment.bottomCenter,
            child: CustomPaint(
              size: Size(widget.size, widget.size * 180 / 192),
              painter: _CaseyPainter(
                expression: widget.expression,
                bodyColor: bodyColor,
                darkColor: AppPalette.primaryDeep,
                blinkScale: widget.animate ? _blinkAnim.value : 1.0,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── CustomPainter ─────────────────────────────────────────────────────────────

class _CaseyPainter extends CustomPainter {
  final String expression;
  final Color bodyColor;
  final Color darkColor;
  final double blinkScale;

  const _CaseyPainter({
    required this.expression,
    required this.bodyColor,
    required this.darkColor,
    required this.blinkScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Масштабируем canvas с viewBox 192×180 до нужного размера
    canvas.scale(size.width / 192, size.height / 180);

    const cream = Color(0xFFFAF6EC);

    // 1. Тень под Кейси
    canvas.drawOval(
      Rect.fromCenter(
          center: const Offset(96, 168), width: 112, height: 12),
      Paint()..color = const Color(0x2E1A2E22),
    );

    // 2. Ручка-дужка
    final handle = Path()
      ..moveTo(76, 36)
      ..relativeQuadraticBezierTo(0, -14, 20, -14)
      ..relativeQuadraticBezierTo(20, 0, 20, 14)
      ..relativeLineTo(0, 8);
    canvas.drawPath(
      handle,
      Paint()
        ..color = darkColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round,
    );

    // 3. Тело — chunky rounded square
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(22, 40, 148, 118), const Radius.circular(32)),
      Paint()..color = bodyColor,
    );

    // 4. Верхний highlight
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(28, 44, 136, 14), const Radius.circular(7)),
      Paint()..color = Colors.white.withOpacity(0.22),
    );

    // 5. Нижняя тень
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(22, 138, 148, 20), const Radius.circular(20)),
      Paint()..color = Colors.black.withOpacity(0.10),
    );

    // 6. Центральная полоска-замок
    canvas.drawRect(
      const Rect.fromLTWH(22, 86, 148, 8),
      Paint()..color = Colors.black.withOpacity(0.10),
    );

    // 7. Замочек
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(88, 84, 16, 12), const Radius.circular(3)),
      Paint()..color = darkColor,
    );

    // 8. Глаза
    _drawEyes(canvas);

    // 9. Рот
    _drawMouth(canvas);

    // 10. Щёки (кроме sleep)
    if (expression != 'sleep') {
      final cheek = Paint()..color = const Color(0x8CFF7A4A);
      canvas.drawOval(
          Rect.fromCenter(
              center: const Offset(64, 98), width: 12, height: 7),
          cheek);
      canvas.drawOval(
          Rect.fromCenter(
              center: const Offset(128, 98), width: 12, height: 7),
          cheek);
    }
  }

  void _drawEyes(Canvas canvas) {
    const eyeY = 78.0;
    final ink = Paint()..color = const Color(0xFF1A2E22);
    final stroke = Paint()
      ..color = const Color(0xFF1A2E22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    switch (expression) {
      case 'sleep':
        // Оба глаза — закрытые дуги
        final p1 = Path()
          ..moveTo(72, 78)
          ..relativeQuadraticBezierTo(6, -2, 12, 0);
        final p2 = Path()
          ..moveTo(108, 78)
          ..relativeQuadraticBezierTo(6, -2, 12, 0);
        canvas.drawPath(p1, stroke);
        canvas.drawPath(p2, stroke);

      case 'wow':
        // Большие круглые глаза
        canvas.drawCircle(const Offset(78, eyeY), 7, ink);
        canvas.drawCircle(
            const Offset(80, eyeY - 2), 2, Paint()..color = Colors.white);
        canvas.drawCircle(const Offset(114, eyeY), 7, ink);
        canvas.drawCircle(
            const Offset(116, eyeY - 2), 2, Paint()..color = Colors.white);

      case 'wink':
        // Левый — овал с морганием
        _drawScaledEye(canvas, 78, eyeY, ink);
        // Правый — закрыт
        final wink = Path()
          ..moveTo(108, 78)
          ..relativeQuadraticBezierTo(6, -2, 12, 0);
        canvas.drawPath(wink, stroke);

      default:
        // happy / cheer — оба овала с морганием
        _drawScaledEye(canvas, 78, eyeY, ink);
        _drawScaledEye(canvas, 114, eyeY, ink);
    }
  }

  void _drawScaledEye(Canvas canvas, double cx, double cy, Paint ink) {
    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(1.0, blinkScale);
    canvas.translate(-cx, -cy);
    // Белок
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: 12, height: 14),
      ink,
    );
    // Блик
    canvas.drawCircle(
      Offset(cx + 2.5, cy - 2.5),
      1.8,
      Paint()..color = Colors.white,
    );
    canvas.restore();
  }

  void _drawMouth(Canvas canvas) {
    final ink = Paint()..color = const Color(0xFF1A2E22);

    switch (expression) {
      case 'wow':
        canvas.drawOval(
          Rect.fromCenter(
              center: const Offset(96, 100), width: 14, height: 18),
          ink,
        );

      case 'sleep':
        final path = Path()
          ..moveTo(88, 102)
          ..relativeQuadraticBezierTo(8, 4, 16, 0);
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFF1A2E22)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.5
            ..strokeCap = StrokeCap.round,
        );

      case 'cheer':
        // Полумесяц-улыбка (filled)
        final path = Path()
          ..moveTo(82, 96)
          ..relativeQuadraticBezierTo(14, 14, 28, 0)
          ..relativeQuadraticBezierTo(-14, 4, -28, 0)
          ..close();
        canvas.drawPath(path, ink);

      default:
        // happy / wink — дуга
        final path = Path()
          ..moveTo(84, 98)
          ..relativeQuadraticBezierTo(12, 10, 24, 0);
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFF1A2E22)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4.0
            ..strokeCap = StrokeCap.round,
        );
    }
  }

  @override
  bool shouldRepaint(_CaseyPainter old) =>
      old.expression != expression ||
      old.blinkScale != blinkScale ||
      old.bodyColor != bodyColor;
}
