import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:case_go/core/theme/app_palete.dart';
import 'package:case_go/core/widgets/casey_mascot.dart';
import 'package:case_go/core/widgets/clay_button.dart';
import 'package:case_go/features/auth/bloc/auth_bloc.dart';
import 'package:case_go/features/auth/ui/google_button.dart';
import 'package:case_go/features/home/home_bloc.dart';
import 'package:case_go/features/profile_setup/profile_setup_extra.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) => const _AuthView();
}

class _AuthView extends StatefulWidget {
  const _AuthView();

  @override
  State<_AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<_AuthView> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl     = TextEditingController();
  bool _showPassword  = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.read<HomeBloc>().add(AppStarted());
          if (state.needsProfileSetup) {
            context.go('/profile/setup',
                extra: const ProfileSetupExtra(
                    mode: ProfileSetupMode.create));
          } else {
            context.go('/');
          }
        }
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppPalette.accentWarm,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              margin:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          );
        }
      },
      builder: (context, state) {
        final isLogin = switch (state) {
          AuthIdle(:final mode)    => mode == AuthMode.login,
          AuthLoading(:final mode) => mode == AuthMode.login,
          AuthError(:final mode)   => mode == AuthMode.login,
          _                        => true,
        };
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: AppPalette.defaultPalette.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 80, 22, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Маскот Кейси с float-анимацией ─────────────────────
                  Center(
                    child: CaseyMascot(
                      size: 132,
                      expression: 'happy',
                      animate: true,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Лого ────────────────────────────────────────────────
                  const Center(child: _CaseGoLogo(size: 28)),
                  const SizedBox(height: 22),

                  // ── Заголовок ────────────────────────────────────────────
                  Text(
                    isLogin ? 'С возвращением!' : 'Создать аккаунт',
                    textAlign: TextAlign.center,
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
                  const SizedBox(height: 6),
                  Text(
                    isLogin
                        ? 'Кейси соскучился. Войдите чтобы продолжить.'
                        : 'Регистрация займёт меньше минуты.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Onest',
                      fontFamilyFallback: ['Roboto'],
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppPalette.ink2,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Clay-карточка с формой ───────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: AppPalette.clay(
                      color: AppPalette.defaultPalette.surface,
                      radius: 28,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Поле Имя (только при регистрации)
                        if (!isLogin) ...[
                          _ClayTextField(
                            controller: _nameCtrl,
                            placeholder: 'Ваше имя',
                            icon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Email
                        _ClayTextField(
                          controller: _emailCtrl,
                          placeholder: 'email@example.com',
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),

                        // Пароль
                        _ClayTextField(
                          controller: _passwordCtrl,
                          placeholder: 'Пароль',
                          icon: Icons.lock_outline_rounded,
                          obscureText: !_showPassword,
                          trailing: GestureDetector(
                            onTap: () =>
                                setState(() => _showPassword = !_showPassword),
                            child: Icon(
                              _showPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppPalette.ink3,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Кнопка Войти / Зарегистрироваться
                        ClayButton(
                          colorScheme: 'primary',
                          size: ClayButtonSize.lg,
                          fullWidth: true,
                          leadingIcon: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFFAF6EC),
                                  ),
                                )
                              : const Icon(Icons.arrow_forward_rounded,
                                  color: Color(0xFFFAF6EC), size: 20),
                          onTap:
                              isLoading ? null : () => _submit(context, isLogin),
                          child: Text(isLogin ? 'Войти' : 'Зарегистрироваться'),
                        ),

                        // Забыли пароль
                        if (isLogin) ...[
                          const SizedBox(height: 14),
                          Center(
                            child: Text(
                              'Забыли пароль?',
                              style: TextStyle(
                                fontFamily: 'Onest',
                                fontFamilyFallback: const ['Roboto'],
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppPalette.ink3,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // ── Разделитель «или» ────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 22),
                    child: Row(
                      children: [
                        Expanded(
                            child: Container(
                                height: 1.5,
                                color: AppPalette.line)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'или',
                            style: TextStyle(
                              fontFamily: 'Onest',
                              fontFamilyFallback: const ['Roboto'],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppPalette.ink3,
                            ),
                          ),
                        ),
                        Expanded(
                            child: Container(
                                height: 1.5,
                                color: AppPalette.line)),
                      ],
                    ),
                  ),

                  // ── Google ───────────────────────────────────────────────
                  if (kIsWeb)
                    Center(child: buildGoogleSignInButton())
                  else
                    ClayButton(
                      colorScheme: 'surface',
                      size: ClayButtonSize.md,
                      fullWidth: true,
                      leadingIcon: _GoogleIcon(),
                      onTap: isLoading
                          ? null
                          : () => context
                              .read<AuthBloc>()
                              .add(const GoogleSignInRequested()),
                      child: const Text('Продолжить с Google'),
                    ),

                  const SizedBox(height: 28),

                  // ── Переключение режима ──────────────────────────────────
                  GestureDetector(
                    onTap: isLoading
                        ? null
                        : () => context
                            .read<AuthBloc>()
                            .add(const AuthModeToggled()),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: 'Onest',
                          fontFamilyFallback: ['Roboto'],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppPalette.ink2,
                        ),
                        children: [
                          TextSpan(
                              text: isLogin
                                  ? 'Нет аккаунта? '
                                  : 'Уже есть аккаунт? '),
                          TextSpan(
                            text: isLogin ? 'Регистрация' : 'Войти',
                            style: const TextStyle(
                              color: AppPalette.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _submit(BuildContext context, bool isLogin) {
    if (isLogin) {
      context.read<AuthBloc>().add(LoginSubmitted(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          ));
    } else {
      context.read<AuthBloc>().add(RegisterSubmitted(
            name: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          ));
    }
  }
}

// ── Вспомогательные виджеты ───────────────────────────────────────────────────

/// Clay-style поле ввода (inset-эффект)
class _ClayTextField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? trailing;

  const _ClayTextField({
    required this.controller,
    required this.placeholder,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ClayInset(
      child: Row(
        children: [
          Icon(icon, color: AppPalette.ink3, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              style: const TextStyle(
                fontFamily: 'Onest',
                fontFamilyFallback: ['Roboto'],
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppPalette.ink,
              ),
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: const TextStyle(
                  color: AppPalette.ink3,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Лого «caseGO» — знак + wordmark
class _CaseGoLogo extends StatelessWidget {
  final double size;
  const _CaseGoLogo({this.size = 28});

  @override
  Widget build(BuildContext context) {
    final markSize = size * 1.1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Знак: зелёный квадрат с иконкой портфеля
        Container(
          width: markSize,
          height: markSize,
          decoration: BoxDecoration(
            color: AppPalette.primary,
            borderRadius: BorderRadius.circular(markSize * 0.32),
          ),
          child: Icon(
            Icons.work_rounded,
            color: Colors.white,
            size: markSize * 0.6,
          ),
        ),
        SizedBox(width: size * 0.35),
        // Wordmark: «case» dark + «go» primary
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontFamilyFallback: const ['Roboto'],
              fontSize: size,
              letterSpacing: -0.3,
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

/// Google-иконка для кнопки «Продолжить с Google»
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    canvas.scale(s, s);
    // Blue
    canvas.drawPath(
      Path()
        ..moveTo(22.5, 12.3)
        ..cubicTo(22.5, 11.5, 22.4, 10.8, 22.3, 10.1)
        ..lineTo(12, 10.1)
        ..lineTo(12, 14.3)
        ..lineTo(17.9, 14.3)
        ..cubicTo(17.6, 15.7, 16.9, 16.9, 15.7, 17.7)
        ..lineTo(15.7, 20.5)
        ..lineTo(19.3, 20.5)
        ..cubicTo(21.4, 18.6, 22.5, 15.7, 22.5, 12.3)
        ..close(),
      Paint()..color = const Color(0xFF4285F4),
    );
    // Green
    canvas.drawPath(
      Path()
        ..moveTo(12, 23)
        ..cubicTo(14.9, 23, 17.4, 22, 19.2, 20.4)
        ..lineTo(15.6, 17.6)
        ..cubicTo(14.6, 18.3, 13.3, 18.7, 12, 18.7)
        ..cubicTo(9.2, 18.7, 6.9, 16.8, 6, 14.3)
        ..lineTo(2.3, 14.3)
        ..lineTo(2.3, 17.1)
        ..cubicTo(4.1, 20.6, 7.8, 23, 12, 23)
        ..close(),
      Paint()..color = const Color(0xFF34A853),
    );
    // Yellow
    canvas.drawPath(
      Path()
        ..moveTo(6, 14.3)
        ..cubicTo(5.8, 13.6, 5.6, 12.8, 5.6, 12)
        ..cubicTo(5.6, 11.2, 5.7, 10.4, 6, 9.7)
        ..lineTo(6, 6.9)
        ..lineTo(2.3, 6.9)
        ..cubicTo(1.5, 8.4, 1, 10.2, 1, 12)
        ..cubicTo(1, 13.8, 1.5, 15.6, 2.3, 17.1)
        ..close(),
      Paint()..color = const Color(0xFFFBBC04),
    );
    // Red
    canvas.drawPath(
      Path()
        ..moveTo(12, 5.3)
        ..cubicTo(13.6, 5.3, 15, 5.8, 16.2, 6.9)
        ..lineTo(19.4, 4)
        ..cubicTo(17.4, 2.1, 14.9, 1, 12, 1)
        ..cubicTo(7.8, 1, 4.1, 3.4, 2.3, 6.9)
        ..lineTo(6, 9.7)
        ..cubicTo(6.9, 7.2, 9.2, 5.3, 12, 5.3)
        ..close(),
      Paint()..color = const Color(0xFFEA4335),
    );
  }

  @override
  bool shouldRepaint(_GooglePainter _) => false;
}
