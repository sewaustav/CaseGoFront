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
                SliverToBoxAdapter(
                  child: _buildHeroSection(context, palette),
                ),
                SliverToBoxAdapter(
                  child: _buildActionGrid(context, palette),
                ),
                SliverToBoxAdapter(
                  child: _buildWelcomeBanner(context, palette),
                ),
                SliverToBoxAdapter(
                  child: _buildQuickActions(context, palette),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
            _buildFloatingBottomBar(context, palette),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, AppPalette palette) {
    return SliverAppBar(
      backgroundColor: palette.background,
      floating: true,
      elevation: 0,
      centerTitle: false,
      title: const Text(
        'Case Go',
        style: TextStyle(
          color: Colors.black,
          fontSize: 28,
          fontWeight: FontWeight.bold,
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
                child: CircleAvatar(
                  backgroundColor: palette.contrastBg,
                  child: Icon(
                    isAuth ? Icons.person : Icons.person_outline,
                    color: isAuth ? palette.altBtn : palette.background,
                  ),
                ),
                itemBuilder: (context) {
                  final role = isAuth
                      ? (state as Authenticated).user['role'] as int? ?? 1
                      : 1;
                  return isAuth
                    ? [
                        const PopupMenuItem(
                          value: 'profile',
                          child: Row(children: [
                            Icon(Icons.person, size: 18),
                            SizedBox(width: 8),
                            Text('Профиль'),
                          ]),
                        ),
                        const PopupMenuItem(
                          value: 'history',
                          child: Row(children: [
                            Icon(Icons.history, size: 18),
                            SizedBox(width: 8),
                            Text('История'),
                          ]),
                        ),
                        if (role == 0)
                          const PopupMenuItem(
                            value: 'admin',
                            child: Row(children: [
                              Icon(Icons.admin_panel_settings, size: 18),
                              SizedBox(width: 8),
                              Text('Админка'),
                            ]),
                          ),
                        const PopupMenuItem(
                          value: 'logout',
                          child: Row(children: [
                            Icon(Icons.logout, size: 18),
                            SizedBox(width: 8),
                            Text('Выйти'),
                          ]),
                        ),
                      ]
                    : [
                        const PopupMenuItem(
                          value: 'login',
                          child: Text('Войти'),
                        ),
                        const PopupMenuItem(
                          value: 'reg',
                          child: Text('Регистрация'),
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

  Widget _buildHeroSection(BuildContext context, AppPalette palette) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is! Authenticated) return const SizedBox.shrink();
        final username = state.user['username'] as String? ??
            state.user['email'] as String? ??
            'друг';
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: palette.contrastBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Привет, $username 👋',
                style: TextStyle(
                  color: palette.background,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Готов прокачать soft skills?\nВыбери кейс и начни тренировку.',
                style: TextStyle(
                  color: palette.background.withOpacity(0.7),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => context.push('/cases'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: palette.altBtn,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Начать тренировку',
                        style: TextStyle(
                          color: palette.contrastBg,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward,
                          color: palette.contrastBg, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeBanner(BuildContext context, AppPalette palette) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is Authenticated) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w300,
                color: palette.contrastBg.withOpacity(0.55),
                height: 1.3,
              ),
              children: const [
                TextSpan(text: 'Добро пожаловать в\n'),
                TextSpan(
                  text: 'Case Go',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D2323),
                    fontSize: 26,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionGrid(BuildContext context, AppPalette palette) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: _ActionCard(
              color: palette.altBtn,
              icon: Icons.arrow_upward,
              iconColor: palette.contrastBg,
              label: 'Начать\nтренировку',
              labelColor: palette.contrastBg,
              onTap: () => context.push('/cases'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionCard(
              color: palette.contrastBg,
              icon: Icons.bar_chart,
              iconColor: palette.background,
              label: 'Мой\nпрофиль',
              labelColor: palette.background,
              onTap: () => context.push('/profile'),
            ),
          ),
        ],
      ),
    );
  }

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
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _QuickActionTile(
            palette: palette,
            icon: Icons.work_outline,
            title: 'Все кейсы',
            subtitle: 'Выберите кейс для тренировки',
            onTap: () => context.push('/cases'),
          ),
          _QuickActionTile(
            palette: palette,
            icon: Icons.history,
            title: 'История',
            subtitle: 'Посмотреть прошлые сессии',
            onTap: () => context.push('/history'),
          ),
          _QuickActionTile(
            palette: palette,
            icon: Icons.info_outline,
            title: 'Инструкция',
            subtitle: 'Как правильно проходить кейсы',
            onTap: () => context.push('/instructions'),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingBottomBar(BuildContext context, AppPalette palette) {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: palette.contrastBg,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(Icons.bar_chart, color: palette.background),
              onPressed: () => context.push('/profile'),
              tooltip: 'Профиль',
            ),
            GestureDetector(
              onTap: () => context.push('/cases'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: palette.altBtn,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.work, color: palette.contrastBg),
                    const SizedBox(width: 8),
                    Text(
                      'Тренажёр',
                      style: TextStyle(
                        color: palette.contrastBg,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.history, color: palette.background),
              onPressed: () => context.push('/history'),
              tooltip: 'История',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable Widgets ──────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color labelColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.color,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.labelColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 32),
              Text(
                label,
                style: TextStyle(
                  color: labelColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
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
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.palette,
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: palette.contrastBg.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: palette.primaryBtn.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: palette.primaryBtn, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: palette.contrastBg,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  Text(subtitle,
                      style: TextStyle(
                          color: palette.contrastBg.withOpacity(0.5),
                          fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: palette.contrastBg.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }
}
