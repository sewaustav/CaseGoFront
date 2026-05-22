import 'package:case_go/core/theme/app_palete.dart';
import 'package:case_go/core/widgets/casey_mascot.dart';
import 'package:case_go/core/widgets/clay_button.dart';
import 'package:case_go/features/cases/cases_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class CasesScreen extends StatefulWidget {
  const CasesScreen({super.key});

  @override
  State<CasesScreen> createState() => _CasesScreenState();
}

class _CasesScreenState extends State<CasesScreen> {
  final _topicCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<CasesCubit>().load();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<CasesCubit>().loadMore();
    }
  }

  @override
  void dispose() {
    _topicCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.defaultPalette.background,
      appBar: AppBar(
        backgroundColor: AppPalette.defaultPalette.background,
        elevation: 0,
        title: const Text('Кейсы'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => context.push('/instructions'),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppPalette.defaultPalette.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A1A2E22),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: AppPalette.primary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _SearchBar(
            topicCtrl: _topicCtrl,
            onApply: () =>
                context.read<CasesCubit>().applyTopicFilter(_topicCtrl.text),
          ),
          Expanded(
            child: BlocBuilder<CasesCubit, CasesState>(
              builder: (context, state) {
                if (state is CasesLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppPalette.primary,
                      strokeWidth: 3,
                    ),
                  );
                }
                if (state is CasesError) {
                  return _ErrorState(
                    onRetry: () => context.read<CasesCubit>().load(),
                  );
                }
                final loaded = state as CasesLoaded;
                if (loaded.cases.isEmpty) {
                  return const _EmptyState();
                }
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount:
                      loaded.cases.length + (loaded.loadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == loaded.cases.length) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppPalette.primary,
                            strokeWidth: 2.5,
                          ),
                        ),
                      );
                    }
                    return _CaseCard(
                      caseData: loaded.cases[index],
                      onTap: () => context.push(
                        '/cases/${loaded.cases[index]['id']}',
                        extra: loaded.cases[index],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Search Bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController topicCtrl;
  final VoidCallback onApply;
  const _SearchBar({required this.topicCtrl, required this.onApply});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: ClayInset(
              radius: 14,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.search,
                      color: AppPalette.ink3, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: topicCtrl,
                      onSubmitted: (_) => onApply(),
                      style: const TextStyle(
                        fontFamily: 'Onest',
                        fontSize: 15,
                        color: AppPalette.ink,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Поиск по теме...',
                        hintStyle: TextStyle(
                          color: AppPalette.ink3,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onApply,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppPalette.primary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: AppPalette.primaryDeep,
                    offset: Offset(0, 4),
                    blurRadius: 0,
                  ),
                  BoxShadow(
                    color: Color(0x241A2E22),
                    offset: Offset(0, 8),
                    blurRadius: 12,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: const Icon(Icons.tune,
                  color: Color(0xFFFAF6EC), size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Case Card ─────────────────────────────────────────────────────────────────

class _CaseCard extends StatelessWidget {
  final Map<String, dynamic> caseData;
  final VoidCallback onTap;

  const _CaseCard({required this.caseData, required this.onTap});

  // Map category string → color tokens
  static const _catColors = {
    'communication': (
      bg: AppPalette.catCommBg,
      fg: AppPalette.catCommColor,
    ),
    'leadership': (
      bg: AppPalette.catLeadBg,
      fg: AppPalette.catLeadColor,
    ),
    'negotiation': (
      bg: AppPalette.catNegBg,
      fg: AppPalette.catNegColor,
    ),
    'conflict': (
      bg: AppPalette.catConfBg,
      fg: AppPalette.catConfColor,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final topic = caseData['topic'] as String? ?? 'Без темы';
    final description = caseData['description'] as String? ?? '';
    // category может быть int или String — используем toString() для безопасности
    final categoryRaw = caseData['category'];
    final category = categoryRaw != null ? categoryRaw.toString().toLowerCase() : '';
    final isGenerated = caseData['is_generated'] as bool? ?? false;

    final cat = _catColors[category];
    final catBg = cat?.bg ?? AppPalette.primaryTint;
    final catFg = cat?.fg ?? AppPalette.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppPalette.defaultPalette.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x201A2E22),
              blurRadius: 20,
              offset: Offset(0, 8),
              spreadRadius: -6,
            ),
            BoxShadow(
              color: Color(0x0C1A2E22),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
            BoxShadow(
              color: Color(0x30FFFFFF),
              blurRadius: 0,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: topic + AI badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    topic,
                    style: const TextStyle(
                      fontFamily: 'Onest',
                      color: AppPalette.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ),
                if (isGenerated) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppPalette.accentYellow.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '✨ AI',
                      style: TextStyle(
                        color: AppPalette.accentYellowDeep,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Onest',
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Onest',
                  color: AppPalette.ink2,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 12),
            // ── Bottom row: category chip + start button
            Row(
              children: [
                if (categoryRaw != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: catBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.folder_outlined,
                            size: 13, color: catFg),
                        const SizedBox(width: 4),
                        Text(
                          categoryRaw.toString(),
                          style: TextStyle(
                            fontFamily: 'Onest',
                            color: catFg,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                ClayButton.primary(
                  size: ClayButtonSize.sm,
                  onTap: onTap,
                  child: const Text('Начать'),
                ),
              ],
            ),
          ],
        ),
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
          children: [
            const CaseyMascot(size: 100, expression: 'sleep'),
            const SizedBox(height: 24),
            const Text(
              'Кейсов пока нет',
              style: TextStyle(
                fontFamily: 'Unbounded',
                color: AppPalette.ink,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Попробуйте изменить фильтр\nили проверьте позже',
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
              'Что-то пошло не так',
              style: TextStyle(
                fontFamily: 'Unbounded',
                color: AppPalette.ink,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Не удалось загрузить кейсы',
              style: TextStyle(
                fontFamily: 'Onest',
                color: AppPalette.ink2,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ClayButton.warm(
              size: ClayButtonSize.md,
              onTap: onRetry,
              leadingIcon: const Icon(Icons.refresh,
                  color: Colors.white, size: 18),
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}
