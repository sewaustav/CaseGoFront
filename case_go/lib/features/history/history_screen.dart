import 'package:case_go/core/theme/app_palete.dart';
import 'package:case_go/core/widgets/casey_mascot.dart';
import 'package:case_go/core/widgets/clay_button.dart';
import 'package:case_go/features/history/history_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HistoryCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.defaultPalette.background,
      appBar: AppBar(
        backgroundColor: AppPalette.defaultPalette.background,
        elevation: 0,
        title: const Text('История'),
      ),
      body: BlocBuilder<HistoryCubit, HistoryState>(
        builder: (context, state) {
          if (state is HistoryLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppPalette.primary,
                strokeWidth: 3,
              ),
            );
          }
          if (state is HistoryError) {
            return _ErrorState(
              onRetry: () => context.read<HistoryCubit>().load(),
            );
          }
          final items = (state as HistoryLoaded).items;
          if (items.isEmpty) {
            return const _EmptyState();
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: items.length,
            itemBuilder: (context, index) => _HistoryCard(
              result: items[index],
              dialogNumber: items.length - index,
            ),
          );
        },
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CaseyMascot(size: 100, expression: 'sleep'),
            SizedBox(height: 24),
            Text(
              'Пока пусто',
              style: TextStyle(
                fontFamily: 'Unbounded',
                color: AppPalette.ink,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Пройдите свой первый кейс,\nчтобы видеть результаты здесь',
              style: TextStyle(
                fontFamily: 'Onest',
                color: AppPalette.ink2,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error State ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CaseyMascot(size: 90, expression: 'wow'),
            const SizedBox(height: 24),
            const Text(
              'Не удалось загрузить историю',
              style: TextStyle(
                fontFamily: 'Unbounded',
                color: AppPalette.ink,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ClayButton.warm(
              size: ClayButtonSize.md,
              leadingIcon:
                  const Icon(Icons.refresh, color: Colors.white, size: 18),
              onTap: onRetry,
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── History Card ──────────────────────────────────────────────────────────────

class _HistoryCard extends StatefulWidget {
  final Map<String, dynamic> result;
  final int dialogNumber;
  const _HistoryCard(
      {required this.result, required this.dialogNumber});

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final caseId = r['case_id'];
    final steps = r['steps_count'] ?? 0;
    final tokens = r['tokens_used'] ?? 0;
    final finishedAt = r['finished_at'] as String?;

    final assertiveness = (r['assertiveness'] as num? ?? 0).toDouble();
    final empathy = (r['empathy'] as num? ?? 0).toDouble();
    final clarity = (r['clarity_communication'] as num? ?? 0).toDouble();
    final resistance = (r['resistance'] as num? ?? 0).toDouble();
    final eloquence = (r['eloquence'] as num? ?? 0).toDouble();
    final initiative = (r['initiative'] as num? ?? 0).toDouble();

    final avgScore =
        (assertiveness + empathy + clarity + resistance + eloquence + initiative) /
            6;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppPalette.defaultPalette.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0x201A2E22),
              blurRadius: _expanded ? 28 : 16,
              offset: const Offset(0, 8),
              spreadRadius: -6,
            ),
            const BoxShadow(
              color: Color(0x0A1A2E22),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row
            Row(
              children: [
                // Score circle
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _scoreColor(avgScore).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${(avgScore * 100).round()}',
                      style: TextStyle(
                        fontFamily: 'Unbounded',
                        color: _scoreColor(avgScore),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Кейс #$caseId',
                        style: const TextStyle(
                          fontFamily: 'Onest',
                          color: AppPalette.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Диалог #${widget.dialogNumber} · ${_formatDate(finishedAt)}',
                        style: const TextStyle(
                          fontFamily: 'Onest',
                          color: AppPalette.ink3,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Expand chevron
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppPalette.ink3,
                    size: 22,
                  ),
                ),
              ],
            ),

            // ── Meta chips row
            const SizedBox(height: 10),
            Row(
              children: [
                _MetaChip(
                  icon: Icons.format_list_numbered,
                  label: '$steps шагов',
                ),
                const SizedBox(width: 8),
                _MetaChip(
                  icon: Icons.auto_awesome,
                  label: '$tokens токенов',
                ),
              ],
            ),

            // ── Expanded: skill breakdown
            if (_expanded) ...[
              const SizedBox(height: 14),
              const Divider(color: AppPalette.line, height: 1),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SkillChip(
                      label: 'Настойч.',
                      value: assertiveness),
                  _SkillChip(label: 'Эмпатия', value: empathy),
                  _SkillChip(label: 'Ясность', value: clarity),
                  _SkillChip(
                      label: 'Стойкость', value: resistance),
                  _SkillChip(
                      label: 'Красноречие', value: eloquence),
                  _SkillChip(
                      label: 'Инициатива', value: initiative),
                ],
              ),
            ],
          ],
        ),
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

// ── Meta Chip ─────────────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppPalette.bg2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppPalette.ink3),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Onest',
              color: AppPalette.ink2,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skill Chip ────────────────────────────────────────────────────────────────

class _SkillChip extends StatelessWidget {
  final String label;
  final double value;
  const _SkillChip({required this.label, required this.value});

  Color _color(double v) {
    if (v >= 0.7) return AppPalette.primary;
    if (v >= 0.4) return AppPalette.accentWarm;
    return const Color(0xFFE05252);
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(value);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Onest',
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '${(value * 100).round()}%',
            style: TextStyle(
              fontFamily: 'Onest',
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
