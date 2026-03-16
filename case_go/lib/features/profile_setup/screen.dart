import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:case_go/core/theme/app_palete.dart';
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

class _ProfileSetupView extends StatefulWidget {
  final ProfileSetupMode mode;

  const _ProfileSetupView({required this.mode});

  @override
  State<_ProfileSetupView> createState() => _ProfileSetupViewState();
}

class _ProfileSetupViewState extends State<_ProfileSetupView> {
  final _formKey = GlobalKey<FormState>();

  // Обязательные поля
  final _usernameCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _surnameCtrl = TextEditingController();

  // Опциональные поля
  final _patronymicCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _professionCtrl = TextEditingController();

  int? _selectedSex; // null / 0 / 1

  // Цели — минимум 1, динамический список
  final List<TextEditingController> _purposeControllers = [
    TextEditingController(),
  ];

  // Соцсети — опциональные, динамический список пар (type, url)
  final List<_SocialEntry> _socialEntries = [];

  static const _socialTypes = [
    'telegram',
    'vk',
    'instagram',
    'linkedin',
    'github',
    'other',
  ];

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
    for (final c in _purposeControllers) {
      c.dispose();
    }
    for (final e in _socialEntries) {
      e.urlCtrl.dispose();
    }
    super.dispose();
  }

  void _addPurpose() {
    setState(() => _purposeControllers.add(TextEditingController()));
  }

  void _removePurpose(int index) {
    if (_purposeControllers.length <= 1) return; // минимум 1
    setState(() {
      _purposeControllers[index].dispose();
      _purposeControllers.removeAt(index);
    });
  }

  void _addSocial() {
    setState(() => _socialEntries.add(_SocialEntry()));
  }

  void _removeSocial(int index) {
    setState(() {
      _socialEntries[index].urlCtrl.dispose();
      _socialEntries.removeAt(index);
    });
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final purposes = _purposeControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (purposes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Добавьте хотя бы одну цель')),
      );
      return;
    }

    final socialLinks = _socialEntries
        .where((e) => e.selectedType != null && e.urlCtrl.text.trim().isNotEmpty)
        .map((e) => SocialLinkData(
              type: e.selectedType!,
              url: e.urlCtrl.text.trim(),
            ))
        .toList();

    final data = ProfileSetupData(
      username: _usernameCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      surname: _surnameCtrl.text.trim(),
      patronymic: _patronymicCtrl.text.trim().isEmpty
          ? null
          : _patronymicCtrl.text.trim(),
      city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
      age: int.tryParse(_ageCtrl.text.trim()),
      sex: _selectedSex,
      description: _descriptionCtrl.text.trim(),
      profession: _professionCtrl.text.trim().isEmpty
          ? null
          : _professionCtrl.text.trim(),
      purposes: purposes,
      socialLinks: socialLinks,
    );

    context.read<ProfileSetupBloc>().add(
          ProfileSetupSubmitted(mode: widget.mode, data: data),
        );
  }

  @override
  Widget build(BuildContext context) {
    final palette =
        Theme.of(context).extension<AppPalette>() ?? AppPalette.defaultPalette;

    final title = widget.mode == ProfileSetupMode.create
        ? 'Расскажи о себе'
        : 'Редактировать профиль';

    return BlocConsumer<ProfileSetupBloc, ProfileSetupState>(
      listener: (context, state) {
        if (state is ProfileSetupSuccess) {
          context.go('/');
        }
        if (state is ProfileSetupError) {
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
            title: Text(
              title,
              style: TextStyle(
                color: palette.contrastBg,
                fontWeight: FontWeight.bold,
              ),
            ),
            // В режиме создания нет кнопки «назад» — пользователь должен
            // заполнить форму. В режиме редактирования — можно уйти.
            automaticallyImplyLeading: widget.mode == ProfileSetupMode.edit,
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.mode == ProfileSetupMode.create) ...[
                    Text(
                      'Шаг последний — заполни профиль, чтобы другие могли тебя найти',
                      style: TextStyle(
                        color: palette.contrastBg.withOpacity(0.5),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                  ],

                  // ── Основная информация ────────────────────────────

                  _SectionHeader(
                      label: 'Основная информация', palette: palette),
                  const SizedBox(height: 16),

                  _AppTextField(
                    controller: _usernameCtrl,
                    label: 'Никнейм',
                    hint: 'от 3 до 30 символов',
                    icon: Icons.alternate_email,
                    palette: palette,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Обязательное поле';
                      }
                      if (v.trim().length < 3) return 'Минимум 3 символа';
                      if (v.trim().length > 30) return 'Максимум 30 символов';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _AppTextField(
                          controller: _nameCtrl,
                          label: 'Имя',
                          icon: Icons.person_outline,
                          palette: palette,
                          validator: _requiredValidator,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AppTextField(
                          controller: _surnameCtrl,
                          label: 'Фамилия',
                          icon: Icons.badge_outlined,
                          palette: palette,
                          validator: _requiredValidator,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _AppTextField(
                    controller: _patronymicCtrl,
                    label: 'Отчество',
                    hint: 'необязательно',
                    icon: Icons.person_2_outlined,
                    palette: palette,
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _AppTextField(
                          controller: _cityCtrl,
                          label: 'Город',
                          hint: 'необязательно',
                          icon: Icons.location_city_outlined,
                          palette: palette,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AppTextField(
                          controller: _ageCtrl,
                          label: 'Возраст',
                          hint: '14–120',
                          icon: Icons.cake_outlined,
                          palette: palette,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (v) {
                            if (v == null || v.isEmpty) return null;
                            final age = int.tryParse(v);
                            if (age == null || age < 14 || age > 120) {
                              return '14–120';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Пол
                  _SexSelector(
                    selected: _selectedSex,
                    palette: palette,
                    onChanged: (v) => setState(() => _selectedSex = v),
                  ),
                  const SizedBox(height: 12),

                  _AppTextField(
                    controller: _professionCtrl,
                    label: 'Профессия',
                    hint: 'необязательно',
                    icon: Icons.work_outline,
                    palette: palette,
                  ),
                  const SizedBox(height: 12),

                  _AppTextField(
                    controller: _descriptionCtrl,
                    label: 'О себе',
                    hint: 'до 500 символов',
                    icon: Icons.notes_outlined,
                    palette: palette,
                    maxLines: 4,
                    maxLength: 500,
                  ),

                  const SizedBox(height: 32),

                  // ── Цели ──────────────────────────────────────────

                  _SectionHeader(
                    label: 'Цели',
                    palette: palette,
                    subtitle: 'Минимум одна цель',
                  ),
                  const SizedBox(height: 16),

                  ..._purposeControllers.asMap().entries.map((entry) {
                    final i = entry.key;
                    final ctrl = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: _AppTextField(
                              controller: ctrl,
                              label: 'Цель ${i + 1}',
                              hint: 'минимум 5 символов',
                              icon: Icons.flag_outlined,
                              palette: palette,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Обязательное поле';
                                }
                                if (v.trim().length < 5) {
                                  return 'Минимум 5 символов';
                                }
                                return null;
                              },
                            ),
                          ),
                          if (_purposeControllers.length > 1) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _removePurpose(i),
                              icon: Icon(Icons.remove_circle_outline,
                                  color: Colors.redAccent.withOpacity(0.7)),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),

                  _AddButton(
                    label: 'Добавить цель',
                    onTap: _addPurpose,
                    palette: palette,
                  ),

                  const SizedBox(height: 32),

                  // ── Соцсети ───────────────────────────────────────

                  _SectionHeader(
                    label: 'Соцсети',
                    palette: palette,
                    subtitle: 'Необязательно',
                  ),
                  const SizedBox(height: 16),

                  ..._socialEntries.asMap().entries.map((entry) {
                    final i = entry.key;
                    final e = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          // Тип соцсети
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: palette.contrastBg.withOpacity(0.15)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: e.selectedType,
                                hint: const Text('Тип'),
                                items: _socialTypes
                                    .map((t) => DropdownMenuItem(
                                          value: t,
                                          child: Text(t),
                                        ))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => e.selectedType = v),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _AppTextField(
                              controller: e.urlCtrl,
                              label: 'Ссылка',
                              icon: Icons.link,
                              palette: palette,
                              keyboardType: TextInputType.url,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _removeSocial(i),
                            icon: Icon(Icons.remove_circle_outline,
                                color: Colors.redAccent.withOpacity(0.7)),
                          ),
                        ],
                      ),
                    );
                  }),

                  _AddButton(
                    label: 'Добавить соцсеть',
                    onTap: _addSocial,
                    palette: palette,
                  ),

                  const SizedBox(height: 40),

                  // ── Кнопка отправки ───────────────────────────────

                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () => _submit(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.altBtn,
                        foregroundColor: palette.contrastBg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: palette.contrastBg,
                              ),
                            )
                          : Text(
                              widget.mode == ProfileSetupMode.create
                                  ? 'Готово'
                                  : 'Сохранить',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String? _requiredValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Обязательное поле';
    return null;
  }
}

// ── Вспомогательные виджеты (приватные для модуля) ───────────────────────────

class _SocialEntry {
  String? selectedType;
  final TextEditingController urlCtrl = TextEditingController();
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final String? subtitle;
  final AppPalette palette;

  const _SectionHeader({
    required this.label,
    required this.palette,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: palette.contrastBg,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 13,
              color: palette.contrastBg.withOpacity(0.45),
            ),
          ),
      ],
    );
  }
}

class _AddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final AppPalette palette;

  const _AddButton({
    required this.label,
    required this.onTap,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(Icons.add_circle_outline, color: palette.primaryBtn),
      label: Text(label,
          style: TextStyle(
              color: palette.primaryBtn, fontWeight: FontWeight.w600)),
    );
  }
}

class _SexSelector extends StatelessWidget {
  final int? selected;
  final AppPalette palette;
  final ValueChanged<int?> onChanged;

  const _SexSelector({
    required this.selected,
    required this.palette,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Пол:',
            style: TextStyle(
                color: palette.contrastBg.withOpacity(0.6), fontSize: 14)),
        const SizedBox(width: 16),
        _SexChip(
            label: 'Мужской',
            value: 1,
            selected: selected,
            palette: palette,
            onTap: onChanged),
        const SizedBox(width: 8),
        _SexChip(
            label: 'Женский',
            value: 0,
            selected: selected,
            palette: palette,
            onTap: onChanged),
        const SizedBox(width: 8),
        // Снять выбор
        if (selected != null)
          GestureDetector(
            onTap: () => onChanged(null),
            child: Text('Сбросить',
                style: TextStyle(
                    color: palette.contrastBg.withOpacity(0.4),
                    fontSize: 12,
                    decoration: TextDecoration.underline)),
          ),
      ],
    );
  }
}

class _SexChip extends StatelessWidget {
  final String label;
  final int value;
  final int? selected;
  final AppPalette palette;
  final ValueChanged<int?> onTap;

  const _SexChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            color: isSelected ? palette.contrastBg : palette.contrastBg.withOpacity(0.6),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final AppPalette palette;
  final bool obscureText;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final int maxLines;
  final int? maxLength;

  const _AppTextField({
    required this.controller,
    required this.label,
    required this.icon,
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
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: palette.contrastBg.withOpacity(0.5)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.contrastBg.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.contrastBg.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.altBtn, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        counterText: maxLength != null ? null : '',
      ),
    );
  }
}