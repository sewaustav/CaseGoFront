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
        // Если при восстановлении сессии обнаружили что профиль не заполнен —
        // роутер сам сделает редирект через redirect callback, но на всякий случай
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
                  child: _buildActionGrid(context, palette),
                ),
                // ── Приветствие ────────────────────────────────────
                SliverToBoxAdapter(
                  child: _buildWelcomeBanner(context, palette),
                ),
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildArticleCard(palette),
                      childCount: 5,
                    ),
                  ),
                ),
              ],
            ),
            _buildFloatingBottomBar(palette),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(BuildContext context, AppPalette palette) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        // Показываем только авторизованным
        if (state is! Authenticated) return const SizedBox.shrink();

        final username = state.user['username'] as String? ??
            state.user['email'] as String? ??
            'друг';

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
              children: [
                const TextSpan(text: 'Добро пожаловать,\n'),
                TextSpan(
                  text: username,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: palette.contrastBg,
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
                itemBuilder: (context) => isAuth
                    ? [
                        const PopupMenuItem(
                          value: 'profile',
                          child: Text('Профиль'),
                        ),
                        const PopupMenuItem(
                          value: 'logout',
                          child: Text('Выйти'),
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
                      ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionGrid(BuildContext context, AppPalette palette) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: palette.altBtn,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.arrow_upward,
                        color: palette.contrastBg, size: 32),
                    Text(
                      'Начать\nтренировку',
                      style: TextStyle(
                        color: palette.contrastBg,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: palette.contrastBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.tune, color: palette.background, size: 32),
                    Text(
                      'Подобрать по\nпараметрам',
                      style: TextStyle(
                        color: palette.background,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(AppPalette palette) {
    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: palette.contrastBg.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Container(
              height: 150,
              color: Colors.grey[300],
              child: const Center(child: Icon(Icons.image)),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Либо работа мечты, либо правда о друге',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingBottomBar(AppPalette palette) {
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
              onPressed: () {},
            ),
            Container(
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
                    'Тренажер',
                    style: TextStyle(
                      color: palette.contrastBg,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.question_answer_outlined,
                  color: palette.background),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}