import 'dart:math' as math;
import 'package:case_go/core/theme/app_palete.dart';
import 'package:case_go/core/widgets/clay_button.dart';
import 'package:case_go/features/profile/profile_cubit.dart';
import 'package:case_go/features/profile_setup/profile_setup_extra.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoading) {
          return Scaffold(
            backgroundColor: AppPalette.defaultPalette.background,
            body: const Center(
              child: CircularProgressIndicator(
                color: AppPalette.primary,
                strokeWidth: 3,
              ),
            ),
          );
        }

        if (state is ProfileError) {
          return Scaffold(
            backgroundColor: AppPalette.defaultPalette.background,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.message,
                        style: const TextStyle(
                            color: AppPalette.ink2, fontSize: 14),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    ClayButton.warm(
                      size: ClayButtonSize.md,
                      onTap: () => context.read<ProfileCubit>().load(),
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final loaded = state as ProfileLoaded;
        return Scaffold(
          backgroundColor: AppPalette.defaultPalette.background,
          body: CustomScrollView(
            slivers: [
              _ProfileSliverAppBar(profile: loaded.profile),
              SliverToBoxAdapter(
                child: _ProfileBody(loaded: loaded),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        );
      },
    );
  }
}

// ── Sliver App Bar ────────────────────────────────────────────────────────────

class _ProfileSliverAppBar extends StatelessWidget {
  final Map<String, dynamic> profile;
  const _ProfileSliverAppBar({required this.profile});

  String _initials(Map<String, dynamic> p) {
    final name = p['name'] as String? ?? '';
    final surname = p['surname'] as String? ?? '';
    final parts = [name, surname].where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.map((s) => s[0].toUpperCase()).take(2).join();
  }

  @override
  Widget build(BuildContext context) {
    final username = profile['username'] as String? ?? 'Профиль';
    final name = [
      profile['name'] as String? ?? '',
      profile['surname'] as String? ?? '',
    ].where((s) => s.isNotEmpty).join(' ');

    return SliverAppBar(
      backgroundColor: AppPalette.ink,
      expandedHeight: 200,
      pinned: true,
      elevation: 0,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => context.push(
              '/profile/setup',
              extra: const ProfileSetupExtra(mode: ProfileSetupMode.edit),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppPalette.accentWarm,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: AppPalette.accentDeep,
                    offset: Offset(0, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Text(
                'Изменить',
                style: TextStyle(
                  fontFamily: 'Onest',
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: AppPalette.ink,
          padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppPalette.primaryTint,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppPalette.primarySoft, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x40000000),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _initials(profile),
                        style: const TextStyle(
                          fontFamily: 'Unbounded',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppPalette.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isNotEmpty ? name : username,
                          style: const TextStyle(
                            fontFamily: 'Unbounded',
                            color: Color(0xFFFAF6EC),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (name.isNotEmpty)
                          Text(
                            '@$username',
                            style: const TextStyle(
                              fontFamily: 'Onest',
                              color: Color(0x99FAF6EC),
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Case count badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppPalette.primaryTint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${profile['case_count'] ?? 0}',
                          style: const TextStyle(
                            fontFamily: 'Unbounded',
                            color: AppPalette.primary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Text(
                          'кейсов',
                          style: TextStyle(
                            fontFamily: 'Onest',
                            color: AppPalette.primaryDeep,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        title: Text(
          username,
          style: const TextStyle(
            fontFamily: 'Unbounded',
            color: Color(0xFFFAF6EC),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        titlePadding: const EdgeInsetsDirectional.only(start: 20, bottom: 16),
      ),
    );
  }
}

// ── Profile Body ──────────────────────────────────────────────────────────────

class _ProfileBody extends StatelessWidget {
  final ProfileLoaded loaded;
  const _ProfileBody({required this.loaded});

  @override
  Widget build(BuildContext context) {
    final profile = loaded.profile;
    final city = profile['city'] as String?;
    final age = profile['age'];
    final description = profile['description'] as String?;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Meta info
          if (city != null || age != null || description != null)
            _ClaySection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (city != null || age != null)
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 16, color: AppPalette.ink3),
                        const SizedBox(width: 6),
                        Text(
                          [
                            if (city != null) city,
                            if (age != null) '$age лет',
                          ].join(', '),
                          style: const TextStyle(
                            fontFamily: 'Onest',
                            color: AppPalette.ink2,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  if (description != null && description.isNotEmpty) ...[
                    if (city != null || age != null) const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(
                        fontFamily: 'Onest',
                        color: AppPalette.ink,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // ── Purposes
          if (loaded.purposes.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionTitle(title: 'Цели'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: loaded.purposes
                  .map((p) => _PurposeChip(
                      text: p['purpose'] as String? ?? ''))
                  .toList(),
            ),
          ],

          // ── Socials
          if (loaded.socials.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionTitle(title: 'Соцсети'),
            const SizedBox(height: 10),
            _ClaySection(
              child: Column(
                children: loaded.socials.map((s) {
                  final url = s['url'] as String? ?? '';
                  final type = s['type'] as String? ?? '';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppPalette.primaryTint,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _socialIcon(type),
                            size: 16,
                            color: AppPalette.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            url,
                            style: const TextStyle(
                              fontFamily: 'Onest',
                              color: AppPalette.ink2,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // ── Skills
          const SizedBox(height: 20),
          Row(
            children: [
              _SectionTitle(title: 'Профиль навыков'),
              const Spacer(),
              GestureDetector(
                onTap: () =>
                    context.read<ProfileCubit>().toggleCharts(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppPalette.primaryTint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        loaded.chartsVisible
                            ? Icons.visibility_off
                            : Icons.bar_chart,
                        size: 15,
                        color: AppPalette.primary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        loaded.chartsVisible ? 'Скрыть' : 'Графики',
                        style: const TextStyle(
                          fontFamily: 'Onest',
                          color: AppPalette.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (loaded.skills != null) ...[
            const SizedBox(height: 16),
            _ClaySection(
              child: _SkillRadarChart(skills: loaded.skills!),
            ),
            const SizedBox(height: 12),
            _ClaySection(
              child: _SkillBars(skills: loaded.skills!),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Text(
              'Нажмите "Графики" чтобы загрузить статистику навыков',
              style: const TextStyle(
                fontFamily: 'Onest',
                color: AppPalette.ink3,
                fontSize: 13,
              ),
            ),
          ],

          // ── History
          if (loaded.chartsVisible && loaded.history.isNotEmpty) ...[
            const SizedBox(height: 24),
            _SectionTitle(title: 'История результатов'),
            const SizedBox(height: 12),
            ...loaded.history.take(10).map((r) => _MiniHistoryCard(result: r)),
          ],
        ],
      ),
    );
  }

  IconData _socialIcon(String type) {
    return switch (type) {
      'telegram' => Icons.send,
      'github' => Icons.code,
      'linkedin' => Icons.work,
      'instagram' || 'vk' => Icons.photo_camera,
      _ => Icons.link,
    };
  }
}

// ── Clay Section wrapper ──────────────────────────────────────────────────────

class _ClaySection extends StatelessWidget {
  final Widget child;
  const _ClaySection({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.defaultPalette.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1C1A2E22),
            blurRadius: 20,
            offset: Offset(0, 8),
            spreadRadius: -6,
          ),
          BoxShadow(
            color: Color(0x0A1A2E22),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ── Section Title ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Unbounded',
        color: AppPalette.ink,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ── Purpose Chip ──────────────────────────────────────────────────────────────

class _PurposeChip extends StatelessWidget {
  final String text;
  const _PurposeChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppPalette.primaryTint,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppPalette.primarySoft,
            offset: Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Onest',
          color: AppPalette.primaryDeep,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Radar Chart ───────────────────────────────────────────────────────────────

class _SkillRadarChart extends StatelessWidget {
  final Map<String, dynamic> skills;

  const _SkillRadarChart({required this.skills});

  static const _skillKeys = [
    'assertiveness',
    'empathy',
    'clarity_communication',
    'resistance',
    'eloquence',
    'initiative',
  ];

  List<double> _extractValues(Map<String, dynamic> s) =>
      _skillKeys.map((k) => (s[k] as num? ?? 0).toDouble()).toList();

  @override
  Widget build(BuildContext context) {
    final values = _extractValues(skills);
    return Center(
      child: SizedBox(
        width: 240,
        height: 240,
        child: CustomPaint(
          painter: _RadarPainter(
            values: values,
            fillColor: AppPalette.primary.withOpacity(0.2),
            strokeColor: AppPalette.primary,
            gridColor: AppPalette.line,
            labelColor: AppPalette.ink2,
          ),
        ),
      ),
    );
  }
}

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
    final radius = size.width / 2 - 28;
    final n = values.length;
    final angleStep = 2 * math.pi / n;

    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Background rings
    for (int level = 1; level <= 5; level++) {
      final r = radius * level / 5;
      final path = Path();
      for (int i = 0; i < n; i++) {
        final angle = -math.pi / 2 + i * angleStep;
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);
        i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Axes
    for (int i = 0; i < n; i++) {
      final angle = -math.pi / 2 + i * angleStep;
      canvas.drawLine(
        center,
        Offset(center.dx + radius * math.cos(angle),
            center.dy + radius * math.sin(angle)),
        gridPaint,
      );
    }

    // Data polygon fill
    final dataPath = Path();
    for (int i = 0; i < n; i++) {
      final angle = -math.pi / 2 + i * angleStep;
      final r = radius * values[i].clamp(0.0, 1.0);
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      i == 0 ? dataPath.moveTo(x, y) : dataPath.lineTo(x, y);
    }
    dataPath.close();

    canvas.drawPath(
      dataPath,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Dots on vertices
    for (int i = 0; i < n; i++) {
      final angle = -math.pi / 2 + i * angleStep;
      final r = radius * values[i].clamp(0.0, 1.0);
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 4,
          Paint()..color = strokeColor);
      canvas.drawCircle(Offset(x, y), 2.5,
          Paint()..color = const Color(0xFFFAF6EC));
    }

    // Labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < n; i++) {
      final angle = -math.pi / 2 + i * angleStep;
      final labelRadius = radius + 20;
      final x = center.dx + labelRadius * math.cos(angle);
      final y = center.dy + labelRadius * math.sin(angle);

      textPainter.text = TextSpan(
        text: _labels[i],
        style: TextStyle(
          color: labelColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ── Skill Bars ────────────────────────────────────────────────────────────────

class _SkillBars extends StatelessWidget {
  final Map<String, dynamic> skills;
  const _SkillBars({required this.skills});

  static const _entries = [
    ('assertiveness', 'Настойчивость'),
    ('empathy', 'Эмпатия'),
    ('clarity_communication', 'Ясность речи'),
    ('resistance', 'Стрессоустойчивость'),
    ('eloquence', 'Красноречие'),
    ('initiative', 'Инициатива'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _entries.map((e) {
        final value = (skills[e.$1] as num? ?? 0).toDouble();
        final pct = (value * 100).round();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      e.$2,
                      style: const TextStyle(
                        fontFamily: 'Onest',
                        color: AppPalette.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '$pct%',
                    style: const TextStyle(
                      fontFamily: 'Onest',
                      color: AppPalette.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: AppPalette.primaryTint,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppPalette.primary,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Mini History Card ─────────────────────────────────────────────────────────

class _MiniHistoryCard extends StatelessWidget {
  final Map<String, dynamic> result;
  const _MiniHistoryCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final caseId = result['case_id'];
    final steps = result['steps_count'] ?? 0;
    final date = result['finished_at'] as String?;
    final assertiveness =
        (result['assertiveness'] as num? ?? 0).toDouble();
    final empathy = (result['empathy'] as num? ?? 0).toDouble();
    final clarity =
        (result['clarity_communication'] as num? ?? 0).toDouble();
    final avg = (assertiveness + empathy + clarity) / 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppPalette.defaultPalette.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x141A2E22),
            blurRadius: 12,
            offset: Offset(0, 4),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Кейс #$caseId',
                  style: const TextStyle(
                    fontFamily: 'Onest',
                    fontWeight: FontWeight.w700,
                    color: AppPalette.ink,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Шагов: $steps • ${_formatDate(date)}',
                  style: const TextStyle(
                    fontFamily: 'Onest',
                    fontSize: 12,
                    color: AppPalette.ink3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _scoreColor(avg).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${(avg * 100).round()}%',
              style: TextStyle(
                fontFamily: 'Onest',
                color: _scoreColor(avg),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _scoreColor(double v) {
    if (v >= 0.7) return AppPalette.primary;
    if (v >= 0.4) return AppPalette.accentWarm;
    return const Color(0xFFE05252);
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return '';
    }
  }
}
