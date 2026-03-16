import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:case_go/core/theme/app_palete.dart';
import 'package:case_go/features/auth/bloc/auth_bloc.dart';
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
          appBar: AppBar(
            backgroundColor: palette.background,
            elevation: 0,
            // Позволяем вернуться на главную — пользователь мог прийти
            // сюда добровольно (не из принудительного редиректа)
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: palette.contrastBg),
              onPressed: () => context.go('/'),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  Text(
                    'Case Go',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: palette.contrastBg,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isLogin ? 'Вход в аккаунт' : 'Создать аккаунт',
                    style: TextStyle(
                      fontSize: 16,
                      color: palette.contrastBg.withOpacity(0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  if (!isLogin) ...[
                    _buildTextField(
                      controller: _nameController,
                      label: 'Имя',
                      icon: Icons.person_outline,
                      palette: palette,
                    ),
                    const SizedBox(height: 16),
                  ],

                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    palette: palette,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _passwordController,
                    label: 'Пароль',
                    icon: Icons.lock_outline,
                    palette: palette,
                    obscureText: true,
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed:
                          isLoading ? null : () => _submit(context, isLogin),
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
                              isLogin ? 'Войти' : 'Зарегистрироваться',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: isLoading
                          ? null
                          : () => context
                              .read<AuthBloc>()
                              .add(const GoogleSignInRequested()),
                      icon: const Icon(Icons.g_mobiledata, size: 28),
                      label: const Text('Войти через Google'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: palette.contrastBg.withOpacity(0.2)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () => context
                            .read<AuthBloc>()
                            .add(const AuthModeToggled()),
                    child: Text(
                      isLogin
                          ? 'Нет аккаунта? Зарегистрироваться'
                          : 'Уже есть аккаунт? Войти',
                      style:
                          TextStyle(color: palette.contrastBg.withOpacity(0.7)),
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
      decoration: InputDecoration(
        labelText: label,
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
      ),
    );
  }
}