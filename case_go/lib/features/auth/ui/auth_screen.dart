import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:case_go/core/theme/app_palete.dart';
import 'package:case_go/features/auth/bloc/auth_bloc.dart';
import 'package:case_go/features/auth/ui/google_button.dart';
import 'package:case_go/features/home/home_bloc.dart';
import 'package:case_go/features/profile_setup/profile_setup_extra.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AuthView();
  }
}

class _AuthView extends StatefulWidget {
  const _AuthView();

  @override
  State<_AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<_AuthView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette =
        Theme.of(context).extension<AppPalette>() ?? AppPalette.defaultPalette;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.read<HomeBloc>().add(AppStarted());
          if (state.needsProfileSetup) {
            context.go(
              '/profile/setup',
              extra: const ProfileSetupExtra(mode: ProfileSetupMode.create),
            );
          } else {
            context.go('/');
          }
        }
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
      builder: (context, state) {
        final isLogin = switch (state) {
          AuthIdle(:final mode) => mode == AuthMode.login,
          AuthLoading(:final mode) => mode == AuthMode.login,
          AuthError(:final mode) => mode == AuthMode.login,
          _ => true,
        };
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: palette.background,
          body: Stack(
            children: [
              // ── Декоративный фон ────────────────────────────────────────
              _buildBackground(palette),

              // ── Контент ─────────────────────────────────────────────────
              SafeArea(
                child: Column(
                  children: [
                    // Кнопка назад
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: GestureDetector(
                          onTap: () => context.go('/'),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(Icons.arrow_back,
                                color: palette.contrastBg, size: 20),
                          ),
                        ),
                      ),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 20),

                            // ── Лого ────────────────────────────────────
                            Center(
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  gradient: AppPalette.primaryGradient,
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          palette.primaryBtn.withOpacity(0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.work_rounded,
                                    color: Colors.white, size: 36),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ShaderMask(
                              shaderCallback: (bounds) =>
                                  AppPalette.primaryGradient
                                      .createShader(bounds),
                              child: const Text(
                                'Case Go',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isLogin ? 'Вход в аккаунт' : 'Создать аккаунт',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: palette.contrastBg.withOpacity(0.5),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 36),

                            // ── Форма ────────────────────────────────────
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  if (!isLogin) ...[
                                    _buildTextField(
                                      controller: _nameController,
                                      label: 'Имя',
                                      icon: Icons.person_outline_rounded,
                                      palette: palette,
                                    ),
                                    const SizedBox(height: 14),
                                  ],
                                  _buildTextField(
                                    controller: _emailController,
                                    label: 'Email',
                                    icon: Icons.email_outlined,
                                    palette: palette,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 14),
                                  _buildTextField(
                                    controller: _passwordController,
                                    label: 'Пароль',
                                    icon: Icons.lock_outline_rounded,
                                    palette: palette,
                                    obscureText: true,
                                  ),
                                  const SizedBox(height: 24),

                                  // ── Кнопка входа/регистрации ──────────
                                  SizedBox(
                                    width: double.infinity,
                                    height: 54,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: isLoading
                                            ? null
                                            : AppPalette.primaryGradient,
                                        color: isLoading
                                            ? palette.surface
                                            : null,
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        boxShadow: isLoading
                                            ? null
                                            : [
                                                BoxShadow(
                                                  color: palette.primaryBtn
                                                      .withOpacity(0.4),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: isLoading
                                            ? null
                                            : () =>
                                                _submit(context, isLogin),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: isLoading
                                            ? SizedBox(
                                                height: 20,
                                                width: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: palette.primaryBtn,
                                                ),
                                              )
                                            : Text(
                                                isLogin
                                                    ? 'Войти'
                                                    : 'Зарегистрироваться',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // ── Разделитель ───────────────────────
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Divider(
                                            color: palette.contrastBg
                                                .withOpacity(0.1)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                        child: Text(
                                          'или',
                                          style: TextStyle(
                                            color: palette.contrastBg
                                                .withOpacity(0.4),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(
                                            color: palette.contrastBg
                                                .withOpacity(0.1)),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // ── Google ────────────────────────────
                                  if (kIsWeb)
                                    Center(child: buildGoogleSignInButton())
                                  else
                                    SizedBox(
                                      width: double.infinity,
                                      height: 54,
                                      child: OutlinedButton.icon(
                                        onPressed: isLoading
                                            ? null
                                            : () => context
                                                .read<AuthBloc>()
                                                .add(const GoogleSignInRequested()),
                                        icon: const Icon(Icons.g_mobiledata,
                                            size: 28),
                                        label:
                                            const Text('Войти через Google'),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            color: palette.contrastBg
                                                .withOpacity(0.15),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // ── Переключение режима ───────────────────────
                            Center(
                              child: GestureDetector(
                                onTap: isLoading
                                    ? null
                                    : () => context
                                        .read<AuthBloc>()
                                        .add(const AuthModeToggled()),
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          palette.contrastBg.withOpacity(0.5),
                                    ),
                                    children: [
                                      TextSpan(
                                        text: isLogin
                                            ? 'Нет аккаунта? '
                                            : 'Уже есть аккаунт? ',
                                      ),
                                      TextSpan(
                                        text: isLogin
                                            ? 'Зарегистрироваться'
                                            : 'Войти',
                                        style: TextStyle(
                                          color: palette.primaryBtn,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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

  // ── Декоративный фон ────────────────────────────────────────────────────

  Widget _buildBackground(AppPalette palette) {
    return Stack(
      children: [
        Positioned(
          top: -80,
          right: -60,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  palette.primaryBtn.withOpacity(0.18),
                  Colors.transparent,
                ],
              ),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          top: 60,
          left: -80,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  palette.accent.withOpacity(0.12),
                  Colors.transparent,
                ],
              ),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          right: -50,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  palette.altBtn.withOpacity(0.14),
                  Colors.transparent,
                ],
              ),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  // ── Submit ──────────────────────────────────────────────────────────────

  void _submit(BuildContext context, bool isLogin) {
    if (isLogin) {
      context.read<AuthBloc>().add(LoginSubmitted(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ));
    } else {
      context.read<AuthBloc>().add(RegisterSubmitted(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ));
    }
  }

  // ── Text field ──────────────────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required AppPalette palette,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(
        color: palette.contrastBg,
        fontWeight: FontWeight.w500,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: palette.contrastBg.withOpacity(0.4),
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, color: palette.primaryBtn.withOpacity(0.6), size: 20),
        filled: true,
        fillColor: palette.surface.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: palette.contrastBg.withOpacity(0.08), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.primaryBtn, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
