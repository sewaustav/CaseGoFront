import 'package:case_go/core/theme/app_palete.dart';
import 'package:flutter/material.dart';

class InstructionsScreen extends StatelessWidget {
  const InstructionsScreen({super.key});

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
          'Как проходить кейсы',
          style: TextStyle(
              color: palette.contrastBg,
              fontWeight: FontWeight.bold,
              fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _IntroBanner(palette: palette),
          const SizedBox(height: 24),
          _SectionHeader(palette: palette, title: 'Что такое кейс-интервью?'),
          const SizedBox(height: 12),
          _TextBlock(
            palette: palette,
            text:
                'Кейс-интервью — это формат собеседования, в котором кандидату предлагают реальную бизнес-задачу и просят её решить. '
                'Интервьюер оценивает не только правильность ответа, но и структуру мышления, умение задавать вопросы, '
                'логику рассуждений и навыки коммуникации.',
          ),
          const SizedBox(height: 24),
          _SectionHeader(palette: palette, title: 'Как работает тренажёр'),
          const SizedBox(height: 12),
          ..._steps.asMap().entries.map((e) => _StepCard(
                palette: palette,
                number: e.key + 1,
                title: e.value.$1,
                description: e.value.$2,
              )),
          const SizedBox(height: 24),
          _SectionHeader(palette: palette, title: 'Оцениваемые навыки'),
          const SizedBox(height: 12),
          ..._skills.map((s) => _SkillRow(
                palette: palette,
                name: s.$1,
                description: s.$2,
              )),
          const SizedBox(height: 24),
          _SectionHeader(palette: palette, title: 'Советы для успеха'),
          const SizedBox(height: 12),
          ..._tips.map((t) => _TipItem(palette: palette, text: t)),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  static const _steps = [
    (
      'Выберите кейс',
      'Перейдите в раздел "Тренажёр" и выберите кейс по теме, которая вас интересует. '
          'Вы можете фильтровать кейсы по теме.',
    ),
    (
      'Начните диалог',
      'После нажатия "Начать" вам будет задан первый вопрос. '
          'Внимательно прочитайте его — это отправная точка вашего решения.',
    ),
    (
      'Отвечайте развёрнуто',
      'Пишите ответы так, как говорили бы на реальном интервью. '
          'AI-собеседник задаёт уточняющие вопросы и оценивает качество ваших ответов.',
    ),
    (
      'Завершите сессию',
      'После нескольких шагов вы можете нажать "Завершить". '
          'Вы получите детальную оценку по шести навыкам.',
    ),
    (
      'Анализируйте результаты',
      'Изучайте свои сильные и слабые стороны в разделе "Профиль". '
          'Отслеживайте прогресс через историю кейсов.',
    ),
  ];

  static const _skills = [
    (
      'Настойчивость',
      'Умение отстаивать свою точку зрения, не сдаваясь под давлением.'
    ),
    (
      'Эмпатия',
      'Способность понимать и учитывать интересы других сторон в решении.'
    ),
    (
      'Ясность коммуникации',
      'Чёткость и структурированность изложения мыслей.'
    ),
    (
      'Стрессоустойчивость',
      'Способность сохранять качество ответов в условиях давления.'
    ),
    (
      'Красноречие',
      'Богатство речи, использование аргументов и примеров.'
    ),
    (
      'Инициатива',
      'Проактивность: задаёте ли вы уточняющие вопросы, предлагаете ли альтернативы.'
    ),
  ];

  static const _tips = [
    'Структурируйте ответы: используйте фреймворки (MECE, дерево проблем, матрица BCG).',
    'Не бойтесь просить уточнений — это показывает глубину мышления.',
    'Думайте вслух: интервьюер оценивает процесс, а не только результат.',
    'Подкрепляйте слова числами и конкретными примерами.',
    'Будьте кратким там, где это уместно, и развёрнутым — где важна глубина.',
    'Практикуйтесь регулярно — прогресс виден уже через несколько сессий.',
  ];
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _IntroBanner extends StatelessWidget {
  final AppPalette palette;
  const _IntroBanner({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.contrastBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(Icons.psychology, color: palette.altBtn, size: 48),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Case Go',
                  style: TextStyle(
                      color: palette.background,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  'Тренажёр soft skills через кейс-интервью с AI',
                  style: TextStyle(
                      color: palette.background.withOpacity(0.75),
                      fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final AppPalette palette;
  final String title;
  const _SectionHeader({required this.palette, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
          color: palette.contrastBg,
          fontSize: 18,
          fontWeight: FontWeight.bold),
    );
  }
}

class _TextBlock extends StatelessWidget {
  final AppPalette palette;
  final String text;
  const _TextBlock({required this.palette, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
          color: palette.contrastBg.withOpacity(0.75),
          fontSize: 14,
          height: 1.6),
    );
  }
}

class _StepCard extends StatelessWidget {
  final AppPalette palette;
  final int number;
  final String title;
  final String description;
  const _StepCard(
      {required this.palette,
      required this.number,
      required this.title,
      required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: palette.primaryBtn,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                    color: palette.background,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      color: palette.contrastBg,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                      color: palette.contrastBg.withOpacity(0.65),
                      fontSize: 13,
                      height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillRow extends StatelessWidget {
  final AppPalette palette;
  final String name;
  final String description;
  const _SkillRow(
      {required this.palette,
      required this.name,
      required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: palette.primaryBtn,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                    color: palette.contrastBg.withOpacity(0.75),
                    fontSize: 14,
                    height: 1.4),
                children: [
                  TextSpan(
                    text: '$name — ',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: palette.contrastBg),
                  ),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final AppPalette palette;
  final String text;
  const _TipItem({required this.palette, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline,
              size: 18, color: palette.primaryBtn),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  color: palette.contrastBg.withOpacity(0.75),
                  fontSize: 13,
                  height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
