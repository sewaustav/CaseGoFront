import 'package:case_go/core/theme/app_palete.dart';
import 'package:case_go/features/admin/admin_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<AdminCubit>().load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette =
        Theme.of(context).extension<AppPalette>() ?? AppPalette.defaultPalette;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.contrastBg,
        foregroundColor: palette.background,
        title: const Text('Админ-панель',
            style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: palette.altBtn,
          unselectedLabelColor: palette.background.withOpacity(0.6),
          indicatorColor: palette.altBtn,
          tabs: const [
            Tab(text: 'Кейсы'),
            Tab(text: 'Пользователи'),
            Tab(text: 'Статистика'),
          ],
        ),
      ),
      body: BlocConsumer<AdminCubit, AdminState>(
        listener: (context, state) {
          if (state is AdminError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ошибка: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AdminLoading || state is AdminInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AdminError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Ошибка загрузки', style: TextStyle(color: palette.contrastBg)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.read<AdminCubit>().load(),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }
          if (state is AdminLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                _CasesTab(cases: state.cases, palette: palette),
                _UsersTab(users: state.users, palette: palette),
                _StatsTab(stats: state.stats, palette: palette),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ── Cases Tab ─────────────────────────────────────────────────────────────────

class _CasesTab extends StatelessWidget {
  final List<Map<String, dynamic>> cases;
  final AppPalette palette;

  const _CasesTab({required this.cases, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: palette.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: palette.contrastBg,
        foregroundColor: palette.altBtn,
        onPressed: () => _showCaseDialog(context, null),
        child: const Icon(Icons.add),
      ),
      body: cases.isEmpty
          ? const Center(child: Text('Нет кейсов'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: cases.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final c = cases[i];
                return _CaseTile(
                  caseData: c,
                  palette: palette,
                  onEdit: () => _showCaseDialog(context, c),
                  onDelete: () => _confirmDelete(context, c),
                );
              },
            ),
    );
  }

  void _showCaseDialog(BuildContext context, Map<String, dynamic>? existing) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<AdminCubit>(),
        child: _CaseFormDialog(existing: existing),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Map<String, dynamic> c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить кейс?'),
        content: Text('«${c['topic']}»'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<AdminCubit>()
                  .deleteCase((c['id'] as num).toInt());
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _CaseTile extends StatelessWidget {
  final Map<String, dynamic> caseData;
  final AppPalette palette;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CaseTile({
    required this.caseData,
    required this.palette,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.contrastBg.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.contrastBg.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  caseData['topic'] as String? ?? '—',
                  style: TextStyle(
                    color: palette.contrastBg,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  caseData['description'] as String? ?? '',
                  style: TextStyle(
                    color: palette.contrastBg.withOpacity(0.6),
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, color: palette.primaryBtn),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _CaseFormDialog extends StatefulWidget {
  final Map<String, dynamic>? existing;

  const _CaseFormDialog({this.existing});

  @override
  State<_CaseFormDialog> createState() => _CaseFormDialogState();
}

class _CaseFormDialogState extends State<_CaseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _topicCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _questionCtrl;
  int _category = 1;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _topicCtrl = TextEditingController(text: e?['topic'] as String? ?? '');
    _descCtrl =
        TextEditingController(text: e?['description'] as String? ?? '');
    _questionCtrl =
        TextEditingController(text: e?['first_question'] as String? ?? '');
    _category = (e?['category'] as num?)?.toInt() ?? 1;
  }

  @override
  void dispose() {
    _topicCtrl.dispose();
    _descCtrl.dispose();
    _questionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Редактировать кейс' : 'Новый кейс'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _topicCtrl,
                decoration: const InputDecoration(labelText: 'Тема'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Обязательно' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Описание'),
                maxLines: 3,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Обязательно' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _questionCtrl,
                decoration: const InputDecoration(labelText: 'Первый вопрос'),
                maxLines: 2,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Обязательно' : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Категория'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1 — Общение')),
                  DropdownMenuItem(value: 2, child: Text('2 — Управление')),
                  DropdownMenuItem(value: 3, child: Text('3 — Продажи')),
                  DropdownMenuItem(value: 4, child: Text('4 — Переговоры')),
                  DropdownMenuItem(value: 5, child: Text('5 — HR')),
                ],
                onChanged: (v) => setState(() => _category = v ?? 1),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: Text(_saving
              ? 'Сохранение...'
              : (isEdit ? 'Сохранить' : 'Создать')),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final body = {
      'topic': _topicCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'first_question': _questionCtrl.text.trim(),
      'category': _category,
    };
    final cubit = context.read<AdminCubit>();
    if (widget.existing != null) {
      await cubit.updateCase(
          (widget.existing!['id'] as num).toInt(), body);
    } else {
      await cubit.createCase(body);
    }
    if (mounted) Navigator.pop(context);
  }
}

// ── Users Tab ─────────────────────────────────────────────────────────────────

class _UsersTab extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  final AppPalette palette;

  const _UsersTab({required this.users, required this.palette});

  static const _roleLabels = {0: 'Админ', 1: 'Пользователь', 2: 'Создатель'};

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final u = users[i];
        final role = (u['role'] as num?)?.toInt() ?? 1;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: palette.contrastBg.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.contrastBg.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u['username'] as String? ?? u['email'] as String? ?? '—',
                      style: TextStyle(
                        color: palette.contrastBg,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      u['email'] as String? ?? '',
                      style: TextStyle(
                        color: palette.contrastBg.withOpacity(0.55),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              DropdownButton<int>(
                value: role,
                underline: const SizedBox(),
                style: TextStyle(color: palette.contrastBg, fontSize: 13),
                items: _roleLabels.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ))
                    .toList(),
                onChanged: (newRole) {
                  if (newRole != null && newRole != role) {
                    context
                        .read<AdminCubit>()
                        .updateUserRole((u['id'] as num).toInt(), newRole);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Stats Tab ─────────────────────────────────────────────────────────────────

class _StatsTab extends StatelessWidget {
  final Map<String, dynamic>? stats;
  final AppPalette palette;

  const _StatsTab({required this.stats, required this.palette});

  @override
  Widget build(BuildContext context) {
    if (stats == null) {
      return const Center(child: Text('Статистика недоступна'));
    }
    final totalCases = stats!['total_cases'] ?? 0;
    final totalDialogs = stats!['total_dialogs'] ?? 0;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Общая статистика',
            style: TextStyle(
              color: palette.contrastBg,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _StatCard(
            palette: palette,
            icon: Icons.work_outline,
            label: 'Всего кейсов',
            value: '$totalCases',
          ),
          const SizedBox(height: 16),
          _StatCard(
            palette: palette,
            icon: Icons.chat_bubble_outline,
            label: 'Всего диалогов',
            value: '$totalDialogs',
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final AppPalette palette;
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.palette,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.contrastBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: palette.altBtn, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: palette.altBtn,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: palette.background.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
