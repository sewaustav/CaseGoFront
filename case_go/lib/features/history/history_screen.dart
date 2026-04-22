import 'package:case_go/core/theme/app_palete.dart';
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
    final palette =
        Theme.of(context).extension<AppPalette>() ?? AppPalette.defaultPalette;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        elevation: 0,
        title: Text(
          'История кейсов',
          style: TextStyle(
              color: palette.contrastBg,
              fontWeight: FontWeight.bold,
              fontSize: 22),
        ),
      ),
      body: BlocBuilder<HistoryCubit, HistoryState>(
        builder: (context, state) {
          if (state is HistoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is HistoryError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline,
                      size: 48, color: Colors.red[300]),
                  const SizedBox(height: 12),
                  Text('Не удалось загрузить историю',
                      style: TextStyle(color: palette.contrastBg)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => context.read<HistoryCubit>().load(),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }
          final items = (state as HistoryLoaded).items;
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history,
                      size: 64, color: palette.contrastBg.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Text(
                    'Вы ещё не проходили кейсы',
                    style: TextStyle(
                        color: palette.contrastBg.withOpacity(0.5),
                        fontSize: 16),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) => _HistoryCard(
              palette: palette,
              result: items[index],
              dialogNumber: items.length - index,
            ),
          );
        },
      ),
    );
  }
}

// ── History Card ──────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final AppPalette palette;
  final Map<String, dynamic> result;
  final int dialogNumber;
  const _HistoryCard({required this.palette, required this.result, required this.dialogNumber});

  @override
  Widget build(BuildContext context) {
    final caseId = result['case_id'];
    final steps = result['steps_count'] ?? 0;
    final tokens = result['tokens_used'] ?? 0;
    final finishedAt = result['finished_at'] as String?;

    final assertiveness = (result['assertiveness'] as num? ?? 0).toDouble();
    final empathy = (result['empathy'] as num? ?? 0).toDouble();
    final clarity =
        (result['clarity_communication'] as num? ?? 0).toDouble();
    final resistance = (result['resistance'] as num? ?? 0).toDouble();
    final eloquence = (result['eloquence'] as num? ?? 0).toDouble();
    final initiative = (result['initiative'] as num? ?? 0).toDouble();

    final avgScore = (assertiveness +
            empathy +
            clarity +
            resistance +
            eloquence +
            initiative) /
        6;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.contrastBg.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Кейс #$caseId',
                        style: TextStyle(
                            color: palette.contrastBg,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                      Text(
                        'Диалог #$dialogNumber • ${_formatDate(finishedAt)}',
                        style: TextStyle(
                            color: palette.contrastBg.withOpacity(0.5),
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _scoreColor(avgScore).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(avgScore * 100).round()}%',
                    style: TextStyle(
                        color: _scoreColor(avgScore),
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.format_list_numbered,
                    size: 14,
                    color: palette.contrastBg.withOpacity(0.4)),
                const SizedBox(width: 4),
                Text('$steps шагов',
                    style: TextStyle(
                        color: palette.contrastBg.withOpacity(0.5),
                        fontSize: 12)),
                const SizedBox(width: 16),
                Icon(Icons.auto_awesome,
                    size: 14,
                    color: palette.contrastBg.withOpacity(0.4)),
                const SizedBox(width: 4),
                Text('$tokens токенов',
                    style: TextStyle(
                        color: palette.contrastBg.withOpacity(0.5),
                        fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _SkillChip(
                    palette: palette,
                    label: 'Настойч.',
                    value: assertiveness),
                _SkillChip(
                    palette: palette,
                    label: 'Эмпатия',
                    value: empathy),
                _SkillChip(
                    palette: palette,
                    label: 'Ясность',
                    value: clarity),
                _SkillChip(
                    palette: palette,
                    label: 'Стойкость',
                    value: resistance),
                _SkillChip(
                    palette: palette,
                    label: 'Красноречие',
                    value: eloquence),
                _SkillChip(
                    palette: palette,
                    label: 'Инициатива',
                    value: initiative),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _scoreColor(double v) {
    if (v >= 0.7) return const Color(0xFF156B5D);
    if (v >= 0.4) return Colors.orange;
    return Colors.red;
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

class _SkillChip extends StatelessWidget {
  final AppPalette palette;
  final String label;
  final double value;
  const _SkillChip(
      {required this.palette, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: palette.contrastBg.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label ${(value * 100).round()}%',
        style: TextStyle(
            color: palette.contrastBg.withOpacity(0.7), fontSize: 11),
      ),
    );
  }
}
