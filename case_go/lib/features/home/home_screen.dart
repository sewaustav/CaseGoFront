import 'package:case_go/core/theme/app_palete.dart';
import 'package:case_go/features/home/home_bloc.dart';
import 'package:case_go/features/profile_setup/profile_setup_extra.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette =
        Theme.of(context).extension<AppPalette>() ?? AppPalette.defaultPalette;

    return BlocListener<HomeBloc, HomeState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          context.go('/auth');
        }
        if (state is AuthenticatedNeedsProfile) {
          context.go(
            '/profile/setup',
            extra: const ProfileSetupExtra(mode: ProfileSetupMode.create),
          );
        }
      },
      child: Scaffold(
        backgroundColor: palette.background,
        body: Stack(
          children: [
            CustomScrollView(
              slivers: [
                _buildAppBar(context, palette),
                SliverToBoxAdapter(child: _buildHeroSection(context, palette)),
                SliverToBoxAdapter(child: _buildActionGrid(context, palette)),
                SliverToBoxAdapter(child: _buildWelcomeBanner(context, palette)),
                SliverToBoxAdapter(child: _buildQuickActions(context, palette)),
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
            _buildFloatingBottomBar(context, palette),
          ],
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context, AppPalette palette) {
    return SliverAppBar(
      backgroundColor: palette.background,
      floating: true,
      elevation: 0,
      centerTitle: false,
      title: ShaderMask(
        shaderCallback: (bounds) =>
            AppPalette.primaryGradient.createShader(bounds),
        child: const Text(
          'Case Go',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ),
      actions: [
        BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            final isAuth = state is Authenticated;
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: PopupMenuButton<String>(
                offset: const Offset(0, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                onSelected: (value) {
                  switch (value) {
                    case 'login':
                    case 'reg':
                      context.push('/auth');
                    case 'profile':
                      context.push('/profile');
                    case 'history':
                      context.push('/history');
                    case 'admin':
                      context.push('/admin');
                    case 'logout':
                      context.read<HomeBloc>().add(LogoutRequested());
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: isAuth ? AppPalette.primaryGradient : null,
                    color: isAuth ? null : palette.surface,
                    shape: BoxShape.circle,
                    boxShadow: isAuth
                        ? [
                            BoxShadow(
                              color: palette.primaryBtn.withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : null,
                  ),
                  child: Icon(
                    isAuth ? Icons.person : Icons.person_outline,
                    color: isAuth ? Colors.white : palette.primaryBtn,
                    size: 22,
                  ),
                ),
                itemBuilder: (context) {
                  final role = isAuth
                      ? (state as Authenticated).user['role'] as int? ?? 1
                      : 1;
                  return isAuth
                      ? [
                          PopupMenuItem(
                            value: 'profile',
                            child: _menuRow(
                                Icons.person, 'Профиль', palette.primaryBtn),
                          ),
                          PopupMenuItem(
                            value: 'history',
                            child: _menuRow(
                                Icons.history, 'История', palette.altBtn),
                          ),
                          if (role == 0)
                            PopupMenuItem(
                              value: 'admin',
                              child: _menuRow(Icons.admin_panel_settings,
                                  'Админка', palette.accent),
                            ),
                          PopupMenuItem(
                            value: 'logout',
                            child: _menuRow(
                                Icons.logout, 'Выйти', Colors.red.shade400,
                                textColor: Colors.red.shade400),
                          ),
                        ]
                      : [
                          PopupMenuItem(
                            value: 'login',
                            child: _menuRow(
                                Icons.login, 'Войти', palette.primaryBtn),
                          ),
                          PopupMenuItem(
                            value: 'reg',
                            child: _menuRow(
                                Icons.person_add, 'Регистрация', palette.altBtn),
                          ),
                        ];
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _menuRow(IconData icon, String label, Color color,
      {Color? textColor}) {
    return Row(children: [
      Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
      const SizedBox(width: 10),
      Text(label, style: TextStyle(color: textColor)),
    ]);
  }

  // ── Hero (авторизован) ────────────────────────────────────────────────────

  Widget _buildHeroSection(BuildContext context, AppPalette palette) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is! Authenticated) return const SizedBox.shrink();
        final username = state.user['username'] as String? ??
            state.user['email'] as String? ??
            'друг';

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          height: 200,
          decoration: BoxDecoration(
            gradient: AppPalette.heroGradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: palette.primaryBtn.withOpacity(0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -30,
                right: -20,
                child: _DecorCircle(
                    size: 130, color: Colors.white.withOpacity(0.08)),
              ),
              Positioned(
                bottom: -40,
                right: 50,
                child: _DecorCircle(
                    size: 100, color: Colors.white.withOpacity(0.06)),
              ),
              Positioned(
                top: 20,
                right: 30,
                child: _DecorCircle(
                    size: 40, color: Colors.white.withOpacity(0.12)),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Привет, $username 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Готов прокачать soft skills?\nВыбери кейс и начни тренировку.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => context.push('/cases'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Начать тренировку',
                              style: TextStyle(
                                color: palette.primaryBtn,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: palette.primaryBtn.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.arrow_forward,
                                  color: palette.primaryBtn, size: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Welcome (не авторизован) ──────────────────────────────────────────────

  Widget _buildWelcomeBanner(BuildContext context, AppPalette palette) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is Authenticated) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppPalette.heroGradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: palette.primaryBtn.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -20,
                right: -15,
                child: _DecorCircle(
                    size: 110, color: Colors.white.withOpacity(0.07)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '✨ Добро пожаловать',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Case Go',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Тренажёр мягких навыков',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => context.push('/auth'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Начать бесплатно',
                            style: TextStyle(
                              color: palette.primaryBtn,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward,
                              color: palette.primaryBtn, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Action grid ───────────────────────────────────────────────────────────

  Widget _buildActionGrid(BuildContext context, AppPalette palette) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: _GradientActionCard(
              gradient: AppPalette.primaryGradient,
              shadowColor: palette.primaryBtn,
              icon: Icons.rocket_launch_rounded,
              label: 'Начать\nтренировку',
              onTap: () => context.push('/cases'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _GradientActionCard(
              gradient: AppPalette.warmGradient,
              shadowColor: palette.altBtn,
              icon: Icons.bar_chart_rounded,
              label: 'Мой\nпрофиль',
              onTap: () => context.push('/profile'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick actions ─────────────────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context, AppPalette palette) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Быстрые действия',
            style: TextStyle(
              color: palette.contrastBg,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          _QuickActionTile(
            palette: palette,
            gradient: AppPalette.primaryGradient,
            icon: Icons.work_rounded,
            title: 'Все кейсы',
            subtitle: 'Выберите кейс для тренировки',
            onTap: () => context.push('/cases'),
          ),
          _QuickActionTile(
            palette: palette,
            gradient: AppPalette.warmGradient,
            icon: Icons.history_rounded,
            title: 'История',
            subtitle: 'Посмотреть прошлые сессии',
            onTap: () => context.push('/history'),
          ),
          _QuickActionTile(
            palette: palette,
            gradient: AppPalette.accentGradient,
            icon: Icons.lightbulb_rounded,
            title: 'Инструкция',
            subtitle: 'Как правильно проходить кейсы',
            onTap: () => context.push('/instructions'),
          ),
        ],
      ),
    );
  }

  // ── Floating bottom bar ───────────────────────────────────────────────────

  Widget _buildFloatingBottomBar(BuildContext context, AppPalette palette) {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: palette.contrastBg,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: palette.contrastBg.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _BottomBarItem(
              icon: Icons.bar_chart_rounded,
              label: 'Профиль',
              onTap: () => context.push('/profile'),
            ),
            GestureDetector(
              onTap: () => context.push('/cases'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: AppPalette.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: palette.primaryBtn.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.work_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Тренажёр',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _BottomBarItem(
              icon: Icons.history_rounded,
              label: 'История',
              onTap: () => context.push('/history'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable Widgets ──────────────────────────────────────────────────────────

class _DecorCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _DecorCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _GradientActionCard extends StatelessWidget {
  final LinearGradient gradient;
  final Color shadowColor;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GradientActionCard({
    required this.gradient,
    required this.shadowColor,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: shadowColor.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -15,
                right: -15,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      height: 1.3,
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

class _QuickActionTile extends StatelessWidget {
  final AppPalette palette;
  final LinearGradient gradient;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.palette,
    required this.gradient,
    required this.icon,
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: palette.contrastBg,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: palette.contrastBg.withOpacity(0.45),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.chevron_right,
                  color: palette.primaryBtn, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomBarItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.7), size: 22),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
