import 'dart:math' as math;
import 'package:case_go/core/theme/app_palete.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;
  const ResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final palette =
        Theme.of(context).extension<AppPalette>() ?? AppPalette.defaultPalette;

    final skills = result['skills_rating'] as Map<String, dynamic>? ?? result;
    final stepsCount = result['steps_count'] ?? 0;
    final tokensUsed = result['tokens_used'] ?? 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) => context.go('/'),
      child: Scaffold(
        backgroundColor: palette.background,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: palette.contrastBg,
              expandedHeight: 140,
              pinned: true,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: palette.contrastBg,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 32),
                        Icon(Icons.emoji_events,
                            color: palette.altBtn, size: 48),
                        Text(
                          'Кейс завершён!',
                          style: TextStyle(
                              color: palette.background,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats row
                    Row(
                      children: [
                        _StatCard(
                          palette: palette,
                          label: 'Шагов',
                          value: '$stepsCount',
                          icon: Icons.format_list_numbered,
                        ),
                        const SizedBox(width: 12),
                        _StatCard(
                          palette: palette,
                          label: 'Токенов',
                          value: '$tokensUsed',
                          icon: Icons.auto_awesome,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Radar chart
                    Text(
                      'Оценка навыков',
                      style: TextStyle(
                          color: palette.contrastBg,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: SizedBox(
                        width: 260,
                        height: 260,
                        child: CustomPaint(
                          painter: _RadarPainter(
                            values: _extractValues(skills),
                            fillColor: palette.altBtn.withOpacity(0.3),
                            strokeColor: palette.primaryBtn,
                            gridColor:
                                palette.contrastBg.withOpacity(0.1),
                            labelColor: palette.contrastBg,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Skill bars
                    ..._skillEntries.map((e) {
                      final value =
                          (skills[e.$1] as num? ?? 0).toDouble();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _SkillRow(
                            palette: palette,
                            label: e.$2,
                            value: value),
                      );
                    }),

                    const SizedBox(height: 32),
                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => context.go('/cases'),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: palette.primaryBtn),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('Ещё кейс',
                                style: TextStyle(
                                    color: palette.primaryBtn,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => context.go('/'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: palette.primaryBtn,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('На главную',
                                style: TextStyle(
                                    color: palette.background,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _skillEntries = [
    ('assertiveness', 'Настойчивость'),
    ('empathy', 'Эмпатия'),
    ('clarity_communication', 'Ясность речи'),
    ('resistance', 'Стрессоустойчивость'),
    ('eloquence', 'Красноречие'),
    ('initiative', 'Инициатива'),
  ];

  List<double> _extractValues(Map<String, dynamic> s) =>
      _skillEntries.map((e) => (s[e.$1] as num? ?? 0).toDouble()).toList();
}

// ── Stat Card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final AppPalette palette;
  final String label;
  final String value;
  final IconData icon;

  const _StatCard(
      {required this.palette,
      required this.label,
      required this.value,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.contrastBg.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.contrastBg.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: palette.primaryBtn, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        color: palette.contrastBg,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                Text(label,
                    style: TextStyle(
                        color: palette.contrastBg.withOpacity(0.55),
                        fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Skill Row ─────────────────────────────────────────────────────────────────

class _SkillRow extends StatelessWidget {
  final AppPalette palette;
  final String label;
  final double value;
  const _SkillRow(
      {required this.palette, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    color: palette.contrastBg, fontSize: 14)),
            Text('${(value * 100).round()}%',
                style: TextStyle(
                    color: palette.primaryBtn,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 10,
            backgroundColor: palette.contrastBg.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation(_scoreColor(value)),
          ),
        ),
      ],
    );
  }

  Color _scoreColor(double v) {
    if (v >= 0.7) return const Color(0xFF156B5D);
    if (v >= 0.4) return const Color(0xFFC4E860);
    return Colors.orange;
  }
}

// ── Radar Chart ───────────────────────────────────────────────────────────────

class _RadarPainter extends CustomPainter {
  final List<double> values;
  final Color fillColor;
  final Color strokeColor;
  final Color gridColor;
  final Color labelColor;

  const _RadarPainter({
    required this.values,
    required this.fillColor,
    required this.strokeColor,
    required this.gridColor,
    required this.labelColor,
  });

  static const _labels = [
    'Настойч.',
    'Эмпатия',
    'Ясность',
    'Стойкость',
    'Красноречие',
    'Инициатива',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 30;
    final n = values.length;
    final step = 2 * math.pi / n;

    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int level = 1; level <= 5; level++) {
      final r = radius * level / 5;
      final path = Path();
      for (int i = 0; i < n; i++) {
        final a = -math.pi / 2 + i * step;
        final x = center.dx + r * math.cos(a);
        final y = center.dy + r * math.sin(a);
        i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    for (int i = 0; i < n; i++) {
      final a = -math.pi / 2 + i * step;
      canvas.drawLine(
          center,
          Offset(center.dx + radius * math.cos(a),
              center.dy + radius * math.sin(a)),
          gridPaint);
    }

    final dataPath = Path();
    for (int i = 0; i < n; i++) {
      final a = -math.pi / 2 + i * step;
      final r = radius * values[i].clamp(0.0, 1.0);
      final x = center.dx + r * math.cos(a);
      final y = center.dy + r * math.sin(a);
      i == 0 ? dataPath.moveTo(x, y) : dataPath.lineTo(x, y);
    }
    dataPath.close();

    canvas.drawPath(dataPath,
        Paint()
          ..color = fillColor
          ..style = PaintingStyle.fill);
    canvas.drawPath(
        dataPath,
        Paint()
          ..color = strokeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5);

    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < n; i++) {
      final a = -math.pi / 2 + i * step;
      final lr = radius + 20;
      final x = center.dx + lr * math.cos(a);
      final y = center.dy + lr * math.sin(a);
      tp.text = TextSpan(
          text: _labels[i],
          style: TextStyle(color: labelColor, fontSize: 10));
      tp.layout();
      tp.paint(canvas,
          Offset(x - tp.width / 2, y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => true;
}
