import 'dart:math' as math;
import 'package:case_go/core/theme/app_palete.dart';
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
        final palette =
            Theme.of(context).extension<AppPalette>() ?? AppPalette.defaultPalette;

        if (state is ProfileLoading) {
          return Scaffold(
            backgroundColor: palette.background,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state is ProfileError) {
          return Scaffold(
            backgroundColor: palette.background,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<ProfileCubit>().load(),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            ),
          );
        }

        final loaded = state as ProfileLoaded;
        return Scaffold(
          backgroundColor: palette.background,
          body: CustomScrollView(
            slivers: [
              _AppBar(palette: palette, profile: loaded.profile),
              SliverToBoxAdapter(
                child: _ProfileHeader(
                    palette: palette, profile: loaded.profile),
              ),
              SliverToBoxAdapter(
                child:
                    _InfoSection(palette: palette, loaded: loaded),
              ),
              SliverToBoxAdapter(
                child: _SkillsSection(palette: palette, loaded: loaded),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        );
      },
    );
  }
}

// ── AppBar ────────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  final AppPalette palette;
  final Map<String, dynamic> profile;
  const _AppBar({required this.palette, required this.profile});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: palette.contrastBg,
      expandedHeight: 160,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(color: palette.contrastBg),
        title: Text(
          profile['username'] as String? ?? 'Профиль',
          style: TextStyle(
              color: palette.background, fontWeight: FontWeight.bold),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.edit, color: palette.altBtn),
          onPressed: () => context.push(
            '/profile/setup',
            extra: const ProfileSetupExtra(mode: ProfileSetupMode.edit),
          ),
        ),
      ],
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final AppPalette palette;
  final Map<String, dynamic> profile;
  const _ProfileHeader({required this.palette, required this.profile});

  @override
  Widget build(BuildContext context) {
    final name = [
      profile['name'] as String? ?? '',
      profile['surname'] as String? ?? '',
    ].where((s) => s.isNotEmpty).join(' ');

    final city = profile['city'] as String?;
    final age = profile['age'];
    final description = profile['description'] as String?;
    final totalCases = profile['case_count'] ?? 0;

    return Container(
      color: palette.contrastBg,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: palette.altBtn,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: palette.contrastBg),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isNotEmpty ? name : 'Без имени',
                      style: TextStyle(
                          color: palette.background,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    if (city != null || age != null)
                      Text(
                        [if (city != null) city, if (age != null) '$age лет']
                            .join(', '),
                        style: TextStyle(
                            color: palette.background.withOpacity(0.7),
                            fontSize: 13),
                      ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    '$totalCases',
                    style: TextStyle(
                        color: palette.altBtn,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                  Text('кейсов',
                      style: TextStyle(
                          color: palette.background.withOpacity(0.7),
                          fontSize: 11)),
                ],
              ),
            ],
          ),
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                  color: palette.background.withOpacity(0.85), fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Info Section ──────────────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  final AppPalette palette;
  final ProfileLoaded loaded;
  const _InfoSection({required this.palette, required this.loaded});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (loaded.purposes.isNotEmpty) ...[
            _SectionTitle(palette: palette, title: 'Цели'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: loaded.purposes
                  .map((p) => Chip(
                        label: Text(p['purpose'] as String? ?? ''),
                        backgroundColor: palette.altBtn.withOpacity(0.15),
                        labelStyle: TextStyle(
                            color: palette.contrastBg, fontSize: 13),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
          if (loaded.socials.isNotEmpty) ...[
            _SectionTitle(palette: palette, title: 'Соцсети'),
            const SizedBox(height: 8),
            ...loaded.socials.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(_socialIcon(s['type'] as String? ?? ''),
                          size: 18, color: palette.primaryBtn),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s['url'] as String? ?? '',
                          style: TextStyle(
                              color: palette.contrastBg.withOpacity(0.8),
                              fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
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

// ── Skills Section ────────────────────────────────────────────────────────────

class _SkillsSection extends StatelessWidget {
  final AppPalette palette;
  final ProfileLoaded loaded;
  const _SkillsSection({required this.palette, required this.loaded});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SectionTitle(palette: palette, title: 'Профиль навыков'),
              const Spacer(),
              TextButton.icon(
                onPressed: () => context.read<ProfileCubit>().toggleCharts(),
                icon: Icon(
                  loaded.chartsVisible
                      ? Icons.visibility_off
                      : Icons.bar_chart,
                  size: 18,
                  color: palette.primaryBtn,
                ),
                label: Text(
                  loaded.chartsVisible ? 'Скрыть' : 'Показать графики',
                  style: TextStyle(color: palette.primaryBtn, fontSize: 13),
                ),
              ),
            ],
          ),
          if (loaded.skills != null) ...[
            const SizedBox(height: 12),
            _SkillRadarChart(palette: palette, skills: loaded.skills!),
            const SizedBox(height: 12),
            _SkillBars(palette: palette, skills: loaded.skills!),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'Нажмите "Показать графики" чтобы загрузить статистику навыков',
              style: TextStyle(
                  color: palette.contrastBg.withOpacity(0.5), fontSize: 13),
            ),
          ],
          if (loaded.chartsVisible && loaded.history.isNotEmpty) ...[
            const SizedBox(height: 24),
            _SectionTitle(palette: palette, title: 'История результатов'),
            const SizedBox(height: 12),
            _HistoryList(palette: palette, history: loaded.history),
          ],
        ],
      ),
    );
  }
}

// ── Radar Chart ───────────────────────────────────────────────────────────────

class _SkillRadarChart extends StatelessWidget {
  final AppPalette palette;
  final Map<String, dynamic> skills;

  const _SkillRadarChart({required this.palette, required this.skills});

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
            fillColor: palette.primaryBtn.withOpacity(0.25),
            strokeColor: palette.primaryBtn,
            gridColor: palette.contrastBg.withOpacity(0.12),
            labelColor: palette.contrastBg,
          ),
        ),
      ),
    );
  }

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

    // Grid
    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

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

    // Data polygon
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
        ..strokeWidth = 2,
    );

    // Labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < n; i++) {
      final angle = -math.pi / 2 + i * angleStep;
      final labelRadius = radius + 18;
      final x = center.dx + labelRadius * math.cos(angle);
      final y = center.dy + labelRadius * math.sin(angle);

      textPainter.text = TextSpan(
        text: _labels[i],
        style: TextStyle(color: labelColor, fontSize: 10),
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
  final AppPalette palette;
  final Map<String, dynamic> skills;
  const _SkillBars({required this.palette, required this.skills});

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
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: Text(e.$2,
                    style: TextStyle(
                        color: palette.contrastBg,
                        fontSize: 13)),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    backgroundColor: palette.contrastBg.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(palette.primaryBtn),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(value * 100).round()}%',
                style: TextStyle(
                    color: palette.primaryBtn,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── History List ──────────────────────────────────────────────────────────────

class _HistoryList extends StatelessWidget {
  final AppPalette palette;
  final List<Map<String, dynamic>> history;
  const _HistoryList({required this.palette, required this.history});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: history.take(10).map((r) {
        final caseId = r['case_id'];
        final steps = r['steps_count'] ?? 0;
        final date = r['finished_at'] as String?;
        final assertiveness = (r['assertiveness'] as num? ?? 0).toDouble();
        final empathy = (r['empathy'] as num? ?? 0).toDouble();
        final clarity =
            (r['clarity_communication'] as num? ?? 0).toDouble();

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Кейс #$caseId',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: palette.contrastBg)),
                      const SizedBox(height: 4),
                      Text('Шагов: $steps • ${_formatDate(date)}',
                          style: TextStyle(
                              fontSize: 12,
                              color: palette.contrastBg.withOpacity(0.6))),
                    ],
                  ),
                ),
                Column(
                  children: [
                    _MiniStat(
                        label: 'Настойч.',
                        value: assertiveness,
                        palette: palette),
                    _MiniStat(
                        label: 'Эмпатия',
                        value: empathy,
                        palette: palette),
                    _MiniStat(
                        label: 'Ясность',
                        value: clarity,
                        palette: palette),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
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

class _MiniStat extends StatelessWidget {
  final String label;
  final double value;
  final AppPalette palette;
  const _MiniStat(
      {required this.label, required this.value, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: palette.contrastBg.withOpacity(0.6))),
        const SizedBox(width: 4),
        Text('${(value * 100).round()}%',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: palette.primaryBtn)),
      ],
    );
  }
}

// ── Shared ────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final AppPalette palette;
  final String title;
  const _SectionTitle({required this.palette, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
          color: palette.contrastBg,
          fontSize: 16,
          fontWeight: FontWeight.bold),
    );
  }
}
