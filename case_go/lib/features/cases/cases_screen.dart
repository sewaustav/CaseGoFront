import 'package:case_go/core/theme/app_palete.dart';
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
    final palette =
        Theme.of(context).extension<AppPalette>() ?? AppPalette.defaultPalette;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        elevation: 0,
        title: Text(
          'Кейсы',
          style: TextStyle(
              color: palette.contrastBg,
              fontWeight: FontWeight.bold,
              fontSize: 22),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: palette.contrastBg),
            onPressed: () => context.push('/instructions'),
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(
              palette: palette,
              topicCtrl: _topicCtrl,
              onApply: () => context
                  .read<CasesCubit>()
                  .applyTopicFilter(_topicCtrl.text)),
          Expanded(
            child: BlocBuilder<CasesCubit, CasesState>(
              builder: (context, state) {
                if (state is CasesLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is CasesError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Ошибка загрузки',
                            style: TextStyle(color: palette.contrastBg)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => context.read<CasesCubit>().load(),
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  );
                }
                final loaded = state as CasesLoaded;
                if (loaded.cases.isEmpty) {
                  return Center(
                    child: Text('Нет кейсов',
                        style: TextStyle(color: palette.contrastBg.withOpacity(0.5))),
                  );
                }
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount:
                      loaded.cases.length + (loaded.loadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == loaded.cases.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return _CaseCard(
                      palette: palette,
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

// ── Filter Bar ────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final AppPalette palette;
  final TextEditingController topicCtrl;
  final VoidCallback onApply;
  const _FilterBar(
      {required this.palette,
      required this.topicCtrl,
      required this.onApply});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: palette.background,
        border: Border(
            bottom: BorderSide(color: palette.contrastBg.withOpacity(0.08))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: topicCtrl,
              decoration: InputDecoration(
                hintText: 'Поиск по теме...',
                hintStyle: TextStyle(
                    color: palette.contrastBg.withOpacity(0.4), fontSize: 14),
                prefixIcon: Icon(Icons.search,
                    color: palette.contrastBg.withOpacity(0.4), size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: palette.contrastBg.withOpacity(0.15)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: palette.contrastBg.withOpacity(0.15)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: palette.primaryBtn),
                ),
                filled: true,
                fillColor: palette.contrastBg.withOpacity(0.04),
              ),
              onSubmitted: (_) => onApply(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onApply,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.primaryBtn,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.tune, color: palette.background, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Case Card ─────────────────────────────────────────────────────────────────

class _CaseCard extends StatelessWidget {
  final AppPalette palette;
  final Map<String, dynamic> caseData;
  final VoidCallback onTap;

  const _CaseCard(
      {required this.palette, required this.caseData, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final topic = caseData['topic'] as String? ?? 'Без темы';
    final description = caseData['description'] as String? ?? '';
    final category = caseData['category'];
    final isGenerated = caseData['is_generated'] as bool? ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: palette.background,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: palette.contrastBg.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      topic,
                      style: TextStyle(
                          color: palette.contrastBg,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (isGenerated)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: palette.altBtn.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'AI',
                        style: TextStyle(
                            color: palette.contrastBg,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: palette.contrastBg.withOpacity(0.65),
                      fontSize: 13),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (category != null)
                    _Tag(
                        palette: palette,
                        text: 'Категория: $category',
                        icon: Icons.folder_outlined),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: palette.primaryBtn,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Начать',
                      style: TextStyle(
                          color: palette.background,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final AppPalette palette;
  final String text;
  final IconData icon;
  const _Tag(
      {required this.palette, required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: palette.contrastBg.withOpacity(0.5)),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(
                color: palette.contrastBg.withOpacity(0.5), fontSize: 12)),
      ],
    );
  }
}
