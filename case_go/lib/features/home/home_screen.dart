import 'package:case_go/core/theme/app_palete.dart';
import 'package:case_go/core/widgets/casey_mascot.dart';
import 'package:case_go/core/widgets/clay_button.dart';
import 'package:case_go/features/home/home_bloc.dart';
import 'package:case_go/features/home/home_cases_cubit.dart';
import 'package:case_go/features/profile_setup/profile_setup_extra.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// ── Данные категорий (apiKey = int из БД) ─────────────────────────────────────

/// apiKey — числовой ID категории на бэкенде (1–5)
class _Category {
  final int apiKey;
  final String label;
  final Color color;
  final Color bg;
  final IconData icon;
  const _Category({
    required this.apiKey,
    required this.label,
    required this.color,
    required this.bg,
    required this.icon,
  });
}

const _categories = [
  _Category(
    apiKey: 1,
    label: 'Общение',
    color: AppPalette.catCommColor,
    bg: AppPalette.catCommBg,
    icon: Icons.chat_bubble_outline_rounded,
  ),
  _Category(
    apiKey: 2,
    label: 'Управление',
    color: AppPalette.catLeadColor,
    bg: AppPalette.catLeadBg,
    icon: Icons.emoji_events_outlined,
  ),
  _Category(
    apiKey: 3,
    label: 'Продажи',
    color: AppPalette.catNegColor,
    bg: AppPalette.catNegBg,
    icon: Icons.trending_up_rounded,
  ),
  _Category(
    apiKey: 4,
    label: 'Переговоры',
    color: AppPalette.catConfColor,
    bg: AppPalette.catConfBg,
    icon: Icons.people_outline_rounded,
  ),
];

// ── Экран ─────────────────────────────────────────────────────────────────────

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Доброе утро';
    if (h < 18) return 'Добрый день';
    return 'Добрый вечер';
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HomeBloc, HomeState>(
      listener: (context, state) {
        if (state is Unauthenticated) context.go('/auth');
        if (state is AuthenticatedNeedsProfile) {
          context.go('/profile/setup',
              extra:
                  const ProfileSetupExtra(mode: ProfileSetupMode.create));
        }
      },
      child: Scaffold(
        backgroundColor: AppPalette.defaultPalette.background,
        body: Stack(
          children: [
            CustomScrollView(
              slivers: [
                _buildTopBar(context),
                SliverToBoxAdapter(child: _buildGreeting(context)),
                SliverToBoxAdapter(child: _buildStats(context)),
                SliverToBoxAdapter(child: _buildHeroCard(context)),
                SliverToBoxAdapter(child: _buildCategories(context)),
                SliverToBoxAdapter(child: _buildQuickActions(context)),
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
            _buildBottomNav(context),
          ],
        ),
      ),
    );
  }

  // ── Top Bar ─────────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _CaseGoLogo(size: 26),
            BlocBuilder<HomeBloc, HomeState>(
              builder: (context, state) {
                final isAuth = state is Authenticated;
                final rawName = isAuth
                    ? ((state).user['username'] as String? ??
                        (state).user['email'] as String? ??
                        'U')
                    : null;
                // Инициалы берём только из никнейма/имени, без домена почты
                final initials = rawName != null ? _initials(rawName) : '?';

                return GestureDetector(
                  onTap: () => isAuth
                      ? context.push('/profile')
                      : context.push('/auth'),
                  // Аватар — тёмный clay с белыми инициалами
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppPalette.ink,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFF0E1A12),
                          offset: Offset(0, 4),
                          blurRadius: 0,
                        ),
                        BoxShadow(
                          color: Color(0x301A2E22),
                          offset: Offset(0, 8),
                          blurRadius: 14,
                          spreadRadius: -4,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontFamily: 'Unbounded',
                        fontFamilyFallback: ['Roboto'],
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFAF6EC),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Приветствие ─────────────────────────────────────────────────────────────

  Widget _buildGreeting(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        // Если нет никнейма — берём часть email до @
        String? username;
        if (state is Authenticated) {
          final raw = state.user['username'] as String? ??
              state.user['email'] as String? ??
              'друг';
          username = raw.contains('@') ? raw.split('@').first : raw;
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting,
                style: const TextStyle(
                  fontFamily: 'Onest',
                  fontFamilyFallback: ['Roboto'],
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.ink2,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                username != null
                    ? '$username 👋'
                    : 'Case Go 👋',
                style: const TextStyle(
                  fontFamily: 'Unbounded',
                  fontFamilyFallback: ['Roboto'],
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: AppPalette.ink,
                  height: 1.1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Трио стат ───────────────────────────────────────────────────────────────

  Widget _buildStats(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is! Authenticated) return const SizedBox(height: 16);
        final u = state.user;
        final streak = u['streak'] as int? ?? 0;
        final xp = u['xp'] as int? ?? 0;
        final level = u['level'] as int? ?? 1;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Row(
            children: [
              Expanded(
                  child: _StatPill(
                icon: Icons.local_fire_department_rounded,
                iconColor: AppPalette.accentWarm,
                value: '$streak',
                label: 'дней',
              )),
              const SizedBox(width: 10),
              Expanded(
                  child: _StatPill(
                icon: Icons.bolt_rounded,
                iconColor: AppPalette.accentYellow,
                value: '$xp',
                label: 'XP',
              )),
              const SizedBox(width: 10),
              Expanded(
                  child: _StatPill(
                icon: Icons.emoji_events_rounded,
                iconColor: AppPalette.accentPurple,
                value: 'L$level',
                label: 'уровень',
              )),
            ],
          ),
        );
      },
    );
  }

  // ── Hero-карточка «Сегодняшний вызов» ───────────────────────────────────────

  Widget _buildHeroCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Сегодняшний вызов'),
          const SizedBox(height: 10),
          BlocBuilder<HomeCasesCubit, HomeCasesState>(
            builder: (context, casesState) {
              // Данные кейса
              final featured = casesState is HomeCasesLoaded
                  ? casesState.featuredCase
                  : null;
              final topic = featured?['topic'] as String? ?? 'Загружаем кейс…';
              final desc = featured?['description'] as String? ?? '';
              final caseId = featured?['id'] as int?;
              final isLoading = casesState is HomeCasesLoading;

              return Container(
                decoration: AppPalette.clayDeep(
                  color: AppPalette.primary,
                  radius: 28,
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    // Декоративные блобы
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: const BoxDecoration(
                          color: Color(0x2EA8D5BA),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 40,
                      bottom: -50,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: const BoxDecoration(
                          color: Color(0x33FFC857),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    // Контент
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Eyebrow
                                Row(
                                  children: [
                                    const Icon(Icons.auto_awesome_rounded,
                                        color: AppPalette.accentYellow,
                                        size: 14),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'ЕЖЕДНЕВНЫЙ КЕЙС',
                                      style: TextStyle(
                                        fontFamily: 'Onest',
                                        fontFamilyFallback: ['Roboto'],
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppPalette.accentYellow,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Тема кейса
                                isLoading
                                    ? const _HeroSkeleton()
                                    : Text(
                                        topic,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: 'Unbounded',
                                          fontFamilyFallback: ['Roboto'],
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFFAF6EC),
                                          letterSpacing: -0.3,
                                          height: 1.2,
                                        ),
                                      ),
                                if (!isLoading && desc.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    desc,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Onest',
                                      fontSize: 13,
                                      color: Color(0xB3FAF6EC),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 14),
                                // Meta chips
                                const Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    _MetaChip(
                                        icon: Icons.bolt_rounded,
                                        text: '+120 XP',
                                        iconColor: AppPalette.accentYellow),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                // CTA
                                ClayButton(
                                  colorScheme: 'yellow',
                                  size: ClayButtonSize.md,
                                  leadingIcon: const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 18,
                                      color: Color(0xFF3A2A0A)),
                                  onTap: () {
                                    if (caseId != null && featured != null) {
                                      context.push(
                                        '/cases/$caseId',
                                        extra: featured,
                                      );
                                    } else {
                                      context.push('/cases');
                                    }
                                  },
                                  child: const Text('Начать'),
                                ),
                              ],
                            ),
                          ),
                          // Кейси cheer
                          Padding(
                            padding:
                                const EdgeInsets.only(right: -4, bottom: -8),
                            child: CaseyMascot(
                              size: 86,
                              expression: 'cheer',
                              accentColor: AppPalette.primarySoft,
                              animate: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Категории 2×2 ───────────────────────────────────────────────────────────

  Widget _buildCategories(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionTitle('Категории'),
              GestureDetector(
                onTap: () => context.push('/cases'),
                child: const Text(
                  'Все →',
                  style: TextStyle(
                    fontFamily: 'Onest',
                    fontFamilyFallback: ['Roboto'],
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          BlocBuilder<HomeCasesCubit, HomeCasesState>(
            builder: (context, casesState) {
              // Реальные счётчики из БД
              final counts = casesState is HomeCasesLoaded
                  ? casesState.categoryCounts
                  : <dynamic, int>{};

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: _categories
                    .map((cat) => _CategoryCard(
                          category: cat,
                          count: counts[cat.apiKey] ??
                              counts[cat.apiKey.toString()] ??
                              0,
                          onTap: () => context.push(
                            '/cases',
                            extra: {
                              'category': cat.apiKey,
                              'categoryLabel': cat.label,
                            },
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Быстрые действия ────────────────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Быстрые действия'),
          const SizedBox(height: 10),
          _QuickTile(
            icon: Icons.work_rounded,
            iconBg: AppPalette.catCommBg,
            iconColor: AppPalette.catCommColor,
            title: 'Все кейсы',
            subtitle: 'Выберите кейс для тренировки',
            onTap: () => context.push('/cases'),
          ),
          _QuickTile(
            icon: Icons.history_rounded,
            iconBg: AppPalette.accentSoft,
            iconColor: AppPalette.accentDeep,
            title: 'История',
            subtitle: 'Посмотреть прошлые сессии',
            onTap: () => context.push('/history'),
          ),
          _QuickTile(
            icon: Icons.lightbulb_outline_rounded,
            iconBg: const Color(0xFFD9D2F4),
            iconColor: AppPalette.catNegColor,
            title: 'Инструкция',
            subtitle: 'Как правильно проходить кейсы',
            onTap: () => context.push('/instructions'),
          ),
        ],
      ),
    );
  }

  // ── Bottom Nav ──────────────────────────────────────────────────────────────

  Widget _buildBottomNav(BuildContext context) {
    return Positioned(
      bottom: 20,
      left: 12,
      right: 12,
      child: Container(
        height: 68,
        decoration: AppPalette.clay(
          color: AppPalette.defaultPalette.surface,
          radius: 26,
        ),
        child: Row(
          children: [
            _NavItem(
              icon: Icons.home_rounded,
              label: 'Тренажёр',
              active: true,
              onTap: () {},
            ),
            _NavItem(
              icon: Icons.grid_view_rounded,
              label: 'Кейсы',
              onTap: () => context.push('/cases'),
            ),
            _NavItem(
              icon: Icons.history_rounded,
              label: 'История',
              onTap: () => context.push('/history'),
            ),
            _NavItem(
              icon: Icons.person_rounded,
              label: 'Профиль',
              onTap: () => context.push('/profile'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Утилиты ─────────────────────────────────────────────────────────────────

  static String _initials(String name) {
    // Если пришёл email — берём часть до @
    final clean = name.contains('@') ? name.split('@').first : name;
    final parts = clean.trim().split(RegExp(r'[\s._-]+'));
    if (parts.length >= 2 && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return clean.isNotEmpty ? clean[0].toUpperCase() : 'U';
  }
}

// ── Hero skeleton (пока грузятся кейсы) ──────────────────────────────────────

class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 22,
          width: 200,
          decoration: BoxDecoration(
            color: const Color(0x30FAF6EC),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 22,
          width: 140,
          decoration: BoxDecoration(
            color: const Color(0x20FAF6EC),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ],
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _CaseGoLogo extends StatelessWidget {
  final double size;
  const _CaseGoLogo({this.size = 26});

  @override
  Widget build(BuildContext context) {
    final markSize = size * 1.45;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Иконка-марк с clay-тенью
        Container(
          width: markSize,
          height: markSize,
          decoration: BoxDecoration(
            color: AppPalette.primary,
            borderRadius: BorderRadius.circular(markSize * 0.30),
            boxShadow: const [
              BoxShadow(
                color: AppPalette.primaryDeep,
                offset: Offset(0, 4),
                blurRadius: 0,
              ),
              BoxShadow(
                color: Color(0x281A2E22),
                offset: Offset(0, 8),
                blurRadius: 14,
                spreadRadius: -4,
              ),
            ],
          ),
          child: Icon(
            Icons.work_rounded,
            color: const Color(0xFFFAF6EC),
            size: markSize * 0.58,
          ),
        ),
        SizedBox(width: size * 0.4),
        // Текст «case go»
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontFamilyFallback: const ['Roboto'],
              fontSize: size,
              letterSpacing: -0.5,
              height: 1,
            ),
            children: const [
              TextSpan(
                text: 'case',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppPalette.ink,
                ),
              ),
              TextSpan(
                text: 'go',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppPalette.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Unbounded',
        fontFamilyFallback: ['Roboto'],
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: AppPalette.ink,
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatPill({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: AppPalette.claySoft(
        color: AppPalette.defaultPalette.surface,
        radius: 18,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Unbounded',
                  fontFamilyFallback: ['Roboto'],
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppPalette.ink,
                  height: 1,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.ink3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? iconColor;

  const _MetaChip({required this.icon, required this.text, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final ic = iconColor ?? const Color(0xCCFAF6EC);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x2FFAF6EC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: ic),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Onest',
              fontFamilyFallback: ['Roboto'],
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xCCFAF6EC),
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  final int level; // 1..3
  const _DifficultyChip({required this.level});

  @override
  Widget build(BuildContext context) {
    const labels = ['', 'легко', 'средне', 'сложно'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x2FFAF6EC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: List.generate(
              3,
              (i) => Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.only(right: 2),
                decoration: BoxDecoration(
                  color: i < level
                      ? AppPalette.accentYellow
                      : const Color(0x4DFAF6EC),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            labels[level.clamp(1, 3)],
            style: const TextStyle(
              fontFamily: 'Onest',
              fontFamilyFallback: ['Roboto'],
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xCCFAF6EC),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final _Category category;
  final int count;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AppPalette.clay(color: category.bg, radius: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: AppPalette.claySoft(
                  color: category.color, radius: 12),
              child: Icon(category.icon, color: Colors.white, size: 20),
            ),
            const Spacer(),
            Text(
              category.label,
              style: TextStyle(
                fontFamily: 'Unbounded',
                fontFamilyFallback: const ['Roboto'],
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
                color: AppPalette.ink,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$count кейсов',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppPalette.ink2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: AppPalette.clay(
            color: AppPalette.defaultPalette.surface, radius: 18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: AppPalette.claySoft(color: iconBg, radius: 13),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Unbounded',
                      fontFamilyFallback: ['Roboto'],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppPalette.ink,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppPalette.ink3,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppPalette.primaryTint,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.chevron_right_rounded,
                  color: AppPalette.primary, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (active)
              Container(
                width: 44,
                height: 32,
                decoration: BoxDecoration(
                  color: AppPalette.primaryTint,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: AppPalette.primaryDeep,
                      offset: Offset(0, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Icon(icon, color: AppPalette.primary, size: 20),
              )
            else
              Icon(icon, color: AppPalette.ink3, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Onest',
                fontFamilyFallback: const ['Roboto'],
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? AppPalette.ink : AppPalette.ink3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
