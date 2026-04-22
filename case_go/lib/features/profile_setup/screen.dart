import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:case_go/core/theme/app_palete.dart';
import 'package:case_go/features/home/home_bloc.dart';
import 'package:case_go/features/profile/profile_cubit.dart';
import 'package:case_go/features/profile_setup/profile_setup_bloc.dart';
import 'package:case_go/features/profile_setup/profile_setup_extra.dart';
import 'package:case_go/features/profile_setup/profile_setup_repository.dart';

class ProfileSetupScreen extends StatelessWidget {
  final ProfileSetupMode mode;
  const ProfileSetupScreen({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    return _ProfileSetupView(mode: mode);
  }
}

enum _Tab { main, purposes, socials }

class _ProfileSetupView extends StatefulWidget {
  final ProfileSetupMode mode;
  const _ProfileSetupView({required this.mode});

  @override
  State<_ProfileSetupView> createState() => _ProfileSetupViewState();
}

class _ProfileSetupViewState extends State<_ProfileSetupView> {
  final _formKey = GlobalKey<FormState>();
  _Tab _currentTab = _Tab.main;

  final _usernameCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _surnameCtrl = TextEditingController();
  final _patronymicCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _professionCtrl = TextEditingController();
  int? _selectedSex;

  final List<TextEditingController> _purposeCtrs = [TextEditingController()];
  final List<_SocialEntry> _socialEntries = [];

  static const _socialTypes = [
    'telegram', 'vk', 'instagram', 'linkedin', 'github', 'other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.mode == ProfileSetupMode.edit) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _prefillFromProfile());
    }
  }

  void _prefillFromProfile() {
    final state = context.read<ProfileCubit>().state;
    if (state is! ProfileLoaded) return;

    final p = state.profile;
    _usernameCtrl.text = p['username'] as String? ?? '';
    _nameCtrl.text = p['name'] as String? ?? '';
    _surnameCtrl.text = p['surname'] as String? ?? '';
    _patronymicCtrl.text = p['patronymic'] as String? ?? '';
    _cityCtrl.text = p['city'] as String? ?? '';
    _ageCtrl.text = p['age']?.toString() ?? '';
    _descriptionCtrl.text = p['description'] as String? ?? '';
    _professionCtrl.text = p['profession'] as String? ?? '';

    final sex = p['sex'];
    if (sex != null) setState(() => _selectedSex = sex as int?);

    if (state.purposes.isNotEmpty) {
      for (final c in _purposeCtrs) c.dispose();
      _purposeCtrs.clear();
      for (final pur in state.purposes) {
        _purposeCtrs.add(TextEditingController(text: pur['purpose'] as String? ?? ''));
      }
    }

    if (state.socials.isNotEmpty) {
      for (final e in _socialEntries) e.urlCtrl.dispose();
      _socialEntries.clear();
      for (final s in state.socials) {
        final entry = _SocialEntry();
        entry.selectedType = s['type'] as String?;
        entry.urlCtrl.text = s['url'] as String? ?? '';
        _socialEntries.add(entry);
      }
    }

    setState(() {});
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _nameCtrl.dispose();
    _surnameCtrl.dispose();
    _patronymicCtrl.dispose();
    _cityCtrl.dispose();
    _ageCtrl.dispose();
    _descriptionCtrl.dispose();
    _professionCtrl.dispose();
    for (final c in _purposeCtrs) c.dispose();
    for (final e in _socialEntries) e.urlCtrl.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      setState(() => _currentTab = _Tab.main);
      return;
    }

    final purposes = _purposeCtrs
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (purposes.isEmpty) {
      setState(() => _currentTab = _Tab.purposes);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Добавьте хотя бы одну цель')),
      );
      return;
    }

    final socialLinks = _socialEntries
        .where((e) => e.selectedType != null && e.urlCtrl.text.trim().isNotEmpty)
        .map((e) => SocialLinkData(type: e.selectedType!, url: e.urlCtrl.text.trim()))
        .toList();

    dev.log('📝 ProfileSetupScreen: submitting form', name: 'ProfileSetup');

    context.read<ProfileSetupBloc>().add(
          ProfileSetupSubmitted(
            mode: widget.mode,
            data: ProfileSetupData(
              username: _usernameCtrl.text.trim(),
              name: _nameCtrl.text.trim(),
              surname: _surnameCtrl.text.trim(),
              patronymic: _patronymicCtrl.text.trim().isEmpty
                  ? null
                  : _patronymicCtrl.text.trim(),
              city: _cityCtrl.text.trim().isEmpty
                  ? null
                  : _cityCtrl.text.trim(),
              age: int.tryParse(_ageCtrl.text.trim()),
              sex: _selectedSex,
              description: _descriptionCtrl.text.trim(),
              profession: _professionCtrl.text.trim().isEmpty
                  ? null
                  : _professionCtrl.text.trim(),
              purposes: purposes,
              socialLinks: socialLinks,
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final palette =
        Theme.of(context).extension<AppPalette>() ?? AppPalette.defaultPalette;
    final isCreate = widget.mode == ProfileSetupMode.create;

    return BlocConsumer<ProfileSetupBloc, ProfileSetupState>(
      listener: (context, state) {
        dev.log('👂 ProfileSetupScreen listener: state=${state.runtimeType}', name: 'ProfileSetup');

        if (state is ProfileSetupSuccess) {
          dev.log('✅ ProfileSetupSuccess caught in listener → dispatching ProfileSetupCompleted to HomeBloc', name: 'ProfileSetup');
          // Меняем состояние HomeBloc: AuthenticatedNeedsProfile → Authenticated.
          // GoRouter подписан на HomeBloc через refreshListenable и автоматически
          // пересчитает redirect — needsProfile станет false и редиректа не будет.
          context.read<HomeBloc>().add(ProfileSetupCompleted());
          dev.log('✅ ProfileSetupCompleted dispatched, navigating to /', name: 'ProfileSetup');
          context.go('/');
        }

        if (state is ProfileSetupError) {
          dev.log('❌ ProfileSetupError: ${state.message}', name: 'ProfileSetup');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is ProfileSetupLoading;

        return Scaffold(
          backgroundColor: palette.background,
          appBar: AppBar(
            backgroundColor: palette.background,
            elevation: 0,
            automaticallyImplyLeading: !isCreate,
            title: Text(
              isCreate ? 'Настройка профиля' : 'Редактировать профиль',
              style: TextStyle(
                color: palette.contrastBg,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          body: Form(
            key: _formKey,
            child: Column(
              children: [
                _ProfileCard(
                  palette: palette,
                  currentTab: _currentTab,
                  onTabChanged: (t) => setState(() => _currentTab = t),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                    child: _buildTabContent(palette),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _BottomSaveBar(
            label: isCreate ? 'Готово' : 'Сохранить',
            isLoading: isLoading,
            palette: palette,
            onTap: () => _submit(context),
          ),
        );
      },
    );
  }

  Widget _buildTabContent(AppPalette palette) {
    return switch (_currentTab) {
      _Tab.main => _MainInfoTab(
          usernameCtrl: _usernameCtrl,
          nameCtrl: _nameCtrl,
          surnameCtrl: _surnameCtrl,
          patronymicCtrl: _patronymicCtrl,
          cityCtrl: _cityCtrl,
          ageCtrl: _ageCtrl,
          descriptionCtrl: _descriptionCtrl,
          professionCtrl: _professionCtrl,
          selectedSex: _selectedSex,
          onSexChanged: (v) => setState(() => _selectedSex = v),
          palette: palette,
        ),
      _Tab.purposes => _PurposesTab(
          controllers: _purposeCtrs,
          onAdd: () => setState(() => _purposeCtrs.add(TextEditingController())),
          onRemove: (i) => setState(() {
            _purposeCtrs[i].dispose();
            _purposeCtrs.removeAt(i);
          }),
          palette: palette,
        ),
      _Tab.socials => _SocialsTab(
          entries: _socialEntries,
          types: _socialTypes,
          onAdd: () => setState(() => _socialEntries.add(_SocialEntry())),
          onRemove: (i) => setState(() {
            _socialEntries[i].urlCtrl.dispose();
            _socialEntries.removeAt(i);
          }),
          onTypeChanged: (i, v) =>
              setState(() => _socialEntries[i].selectedType = v),
          palette: palette,
        ),
    };
  }
}

// ── Profile card with tabs ────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final AppPalette palette;
  final _Tab currentTab;
  final ValueChanged<_Tab> onTabChanged;

  const _ProfileCard({
    required this.palette,
    required this.currentTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: palette.contrastBg.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.contrastBg.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: palette.contrastBg.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: palette.contrastBg.withOpacity(0.15), width: 2),
                  ),
                  child: Icon(Icons.person,
                      color: palette.contrastBg.withOpacity(0.4), size: 28),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Новый пользователь',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: palette.contrastBg,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Заполни информацию о себе',
                      style: TextStyle(
                        fontSize: 12,
                        color: palette.contrastBg.withOpacity(0.45),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                _TabChip(
                  label: 'Информация',
                  icon: Icons.person_outline,
                  isActive: currentTab == _Tab.main,
                  palette: palette,
                  onTap: () => onTabChanged(_Tab.main),
                ),
                const SizedBox(width: 8),
                _TabChip(
                  label: 'Цели',
                  icon: Icons.flag_outlined,
                  isActive: currentTab == _Tab.purposes,
                  palette: palette,
                  onTap: () => onTabChanged(_Tab.purposes),
                ),
                const SizedBox(width: 8),
                _TabChip(
                  label: 'Соцсети',
                  icon: Icons.link,
                  isActive: currentTab == _Tab.socials,
                  palette: palette,
                  onTap: () => onTabChanged(_Tab.socials),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final AppPalette palette;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? palette.primaryBtn : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: isActive
                    ? Colors.white
                    : palette.contrastBg.withOpacity(0.5)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive
                    ? Colors.white
                    : palette.contrastBg.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab: Main info ────────────────────────────────────────────────────────────

class _MainInfoTab extends StatelessWidget {
  final TextEditingController usernameCtrl;
  final TextEditingController nameCtrl;
  final TextEditingController surnameCtrl;
  final TextEditingController patronymicCtrl;
  final TextEditingController cityCtrl;
  final TextEditingController ageCtrl;
  final TextEditingController descriptionCtrl;
  final TextEditingController professionCtrl;
  final int? selectedSex;
  final ValueChanged<int?> onSexChanged;
  final AppPalette palette;

  const _MainInfoTab({
    required this.usernameCtrl,
    required this.nameCtrl,
    required this.surnameCtrl,
    required this.patronymicCtrl,
    required this.cityCtrl,
    required this.ageCtrl,
    required this.descriptionCtrl,
    required this.professionCtrl,
    required this.selectedSex,
    required this.onSexChanged,
    required this.palette,
  });

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        _FieldRow(
          label: 'Никнейм',
          palette: palette,
          child: _InlineField(
            controller: usernameCtrl,
            palette: palette,
            hint: 'от 3 до 30 символов',
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Обязательное поле';
              if (v.trim().length < 3) return 'Мин. 3 символа';
              if (v.trim().length > 30) return 'Макс. 30';
              return null;
            },
          ),
        ),
        _FieldRow(label: 'Имя', palette: palette,
          child: _InlineField(controller: nameCtrl, palette: palette, validator: _required)),
        _FieldRow(label: 'Фамилия', palette: palette,
          child: _InlineField(controller: surnameCtrl, palette: palette, validator: _required)),
        _FieldRow(label: 'Отчество', palette: palette,
          child: _InlineField(controller: patronymicCtrl, palette: palette, hint: 'необязательно')),
        _FieldRow(label: 'Город', palette: palette,
          child: _InlineField(controller: cityCtrl, palette: palette, hint: 'необязательно')),
        _FieldRow(
          label: 'Возраст',
          palette: palette,
          child: _InlineField(
            controller: ageCtrl,
            palette: palette,
            hint: '14–120',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) {
              if (v == null || v.isEmpty) return null;
              final age = int.tryParse(v);
              if (age == null || age < 14 || age > 120) return '14–120';
              return null;
            },
          ),
        ),
        _FieldRow(label: 'Пол', palette: palette,
          child: _SexPicker(selected: selectedSex, palette: palette, onChanged: onSexChanged)),
        _FieldRow(label: 'Профессия', palette: palette,
          child: _InlineField(controller: professionCtrl, palette: palette, hint: 'необязательно')),
        _FieldRow(label: 'О себе', palette: palette, isLast: true,
          child: _InlineField(
            controller: descriptionCtrl,
            palette: palette,
            hint: 'до 500 символов',
            maxLines: 3,
            maxLength: 500,
          ),
        ),
      ],
    );
  }
}

// ── Tab: Purposes ─────────────────────────────────────────────────────────────

class _PurposesTab extends StatelessWidget {
  final List<TextEditingController> controllers;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final AppPalette palette;

  const _PurposesTab({
    required this.controllers,
    required this.onAdd,
    required this.onRemove,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(
          'Расскажи, чего хочешь достичь. Минимум одна цель.',
          style: TextStyle(color: palette.contrastBg.withOpacity(0.5), fontSize: 13),
        ),
        const SizedBox(height: 16),
        ...controllers.asMap().entries.map((entry) {
          final i = entry.key;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: palette.primaryBtn.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                          color: palette.primaryBtn,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: entry.value,
                    decoration: _inputDeco(palette, 'Цель ${i + 1}', 'минимум 5 символов'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Обязательное поле';
                      if (v.trim().length < 5) return 'Мин. 5 символов';
                      return null;
                    },
                  ),
                ),
                if (controllers.length > 1) ...[
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: () => onRemove(i),
                    icon: Icon(Icons.remove_circle_outline,
                        color: Colors.redAccent.withOpacity(0.7), size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ],
            ),
          );
        }),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: onAdd,
          icon: Icon(Icons.add_circle_outline, color: palette.primaryBtn, size: 20),
          label: Text('Добавить цель',
              style: TextStyle(color: palette.primaryBtn, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

// ── Tab: Socials ──────────────────────────────────────────────────────────────

class _SocialsTab extends StatelessWidget {
  final List<_SocialEntry> entries;
  final List<String> types;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final void Function(int, String?) onTypeChanged;
  final AppPalette palette;

  const _SocialsTab({
    required this.entries,
    required this.types,
    required this.onAdd,
    required this.onRemove,
    required this.onTypeChanged,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(
          'Добавь ссылки на свои профили (необязательно).',
          style: TextStyle(color: palette.contrastBg.withOpacity(0.5), fontSize: 13),
        ),
        const SizedBox(height: 16),
        ...entries.asMap().entries.map((e) {
          final i = e.key;
          final entry = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: palette.contrastBg.withOpacity(0.15)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: entry.selectedType,
                      hint: Text('Тип',
                          style: TextStyle(
                              color: palette.contrastBg.withOpacity(0.4),
                              fontSize: 13)),
                      items: types
                          .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t, style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (v) => onTypeChanged(i, v),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: entry.urlCtrl,
                    decoration: _inputDeco(palette, 'Ссылка', 'https://...'),
                    keyboardType: TextInputType.url,
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: () => onRemove(i),
                  icon: Icon(Icons.remove_circle_outline,
                      color: Colors.redAccent.withOpacity(0.7), size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: onAdd,
          icon: Icon(Icons.add_circle_outline, color: palette.primaryBtn, size: 20),
          label: Text('Добавить соцсеть',
              style: TextStyle(color: palette.primaryBtn, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

// ── Bottom save bar ───────────────────────────────────────────────────────────

class _BottomSaveBar extends StatelessWidget {
  final String label;
  final bool isLoading;
  final AppPalette palette;
  final VoidCallback onTap;

  const _BottomSaveBar({
    required this.label,
    required this.isLoading,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      decoration: BoxDecoration(
        color: palette.background,
        border: Border(top: BorderSide(color: palette.contrastBg.withOpacity(0.07))),
      ),
      child: SizedBox(
        height: 54,
        child: ElevatedButton(
          onPressed: isLoading ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: palette.altBtn,
            foregroundColor: palette.contrastBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: palette.contrastBg))
              : Text(label,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }
}

// ── Field row ─────────────────────────────────────────────────────────────────

class _FieldRow extends StatelessWidget {
  final String label;
  final Widget child;
  final AppPalette palette;
  final bool isLast;

  const _FieldRow({
    required this.label,
    required this.child,
    required this.palette,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                child: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 14,
                          color: palette.contrastBg.withOpacity(0.5))),
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
        if (!isLast)
          Divider(
              height: 1,
              thickness: 1,
              color: palette.contrastBg.withOpacity(0.07)),
      ],
    );
  }
}

// ── Inline text field ─────────────────────────────────────────────────────────

class _InlineField extends StatelessWidget {
  final TextEditingController controller;
  final AppPalette palette;
  final String? hint;
  final bool obscureText;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final int maxLines;
  final int? maxLength;

  const _InlineField({
    required this.controller,
    required this.palette,
    this.hint,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
    this.maxLines = 1,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      maxLength: maxLength,
      textAlign: TextAlign.right,
      style: TextStyle(color: palette.contrastBg, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: palette.contrastBg.withOpacity(0.3), fontSize: 14),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.redAccent, width: 1)),
        focusedErrorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.redAccent, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        counterText: '',
      ),
    );
  }
}

// ── Sex picker ────────────────────────────────────────────────────────────────

class _SexPicker extends StatelessWidget {
  final int? selected;
  final AppPalette palette;
  final ValueChanged<int?> onChanged;

  const _SexPicker({
    required this.selected,
    required this.palette,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _Chip(
            label: 'Мужской',
            isSelected: selected == 1,
            palette: palette,
            onTap: () => onChanged(selected == 1 ? null : 1),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Женский',
            isSelected: selected == 0,
            palette: palette,
            onTap: () => onChanged(selected == 0 ? null : 0),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final AppPalette palette;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.isSelected,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? palette.altBtn : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? palette.altBtn
                : palette.contrastBg.withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? palette.contrastBg
                : palette.contrastBg.withOpacity(0.55),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SocialEntry {
  String? selectedType;
  final TextEditingController urlCtrl = TextEditingController();
}

InputDecoration _inputDeco(AppPalette palette, String label, [String? hint]) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    hintStyle:
        TextStyle(color: palette.contrastBg.withOpacity(0.35), fontSize: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: palette.contrastBg.withOpacity(0.15)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: palette.contrastBg.withOpacity(0.15)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: palette.altBtn, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Colors.redAccent, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}