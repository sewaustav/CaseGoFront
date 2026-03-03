import 'package:case_go/core/theme/app_palete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_bloc.dart';
 // Путь к твоей палитре

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>() ?? AppPalette.defaultPalette;

    return Scaffold(
      backgroundColor: palette.background,
      // Используем Stack, чтобы плавающая панель была поверх контента
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // --- 1. ЗАГОЛОВОК И ПРОФИЛЬ ---
              _buildAppBar(context, palette),

              // --- 2. КВАДРАТНЫЕ КНОПКИ ---
              SliverToBoxAdapter(
                child: _buildActionGrid(context, palette),
              ),

              // --- 3. СТАТЬИ (Заглушки) ---
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 100), // Отступ под панель
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildArticleCard(palette),
                    childCount: 5,
                  ),
                ),
              ),
            ],
          ),

          // --- 4. ПЛАВАЮЩАЯ НИЖНЯЯ ПАНЕЛЬ ---
          _buildFloatingBottomBar(palette),
        ],
      ),
    );
  }

  // --- Компонент: AppBar ---
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
            bool isAuth = state is Authenticated;
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: PopupMenuButton<String>(
                offset: const Offset(0, 50),
                child: CircleAvatar(
                  backgroundColor: palette.contrastBg,
                  child: Icon(
                    isAuth ? Icons.person : Icons.person_outline,
                    color: isAuth ? palette.altBtn : palette.background,
                  ),
                ),
                onSelected: (value) {
                  // Здесь будут ссылки
                },
                itemBuilder: (context) => isAuth
                    ? [
                        const PopupMenuItem(value: 'profile', child: Text('Профиль')),
                        const PopupMenuItem(value: 'logout', child: Text('Выйти')),
                      ]
                    : [
                        const PopupMenuItem(value: 'login', child: Text('Войти')),
                        const PopupMenuItem(value: 'reg', child: Text('Регистрация')),
                      ],
              ),
            );
          },
        ),
      ],
    );
  }

  // --- Компонент: Сетка из двух квадратов ---
  Widget _buildActionGrid(BuildContext context, AppPalette palette) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        children: [
          // Квадрат 1: Начать тренировку
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
                    Icon(Icons.arrow_upward, color: palette.contrastBg, size: 32),
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
          // Квадрат 2: Подобрать по параметрам
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

  // --- Компонент: Карточка статьи (Заглушка) ---
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
            child: Container(height: 150, color: Colors.grey[300], child: const Center(child: Icon(Icons.image))),
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

  // --- Компонент: Плавающая нижняя панель ---
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
            // Левая кнопка: Диаграмма
            IconButton(
              icon: Icon(Icons.bar_chart, color: palette.background),
              onPressed: () {},
            ),
            // Центральная кнопка: Тренажер
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                    style: TextStyle(color: palette.contrastBg, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            // Правая кнопка: Обратная связь
            IconButton(
              icon: Icon(Icons.question_answer_outlined, color: palette.background),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}