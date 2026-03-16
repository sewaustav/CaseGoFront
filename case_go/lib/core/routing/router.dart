import 'package:case_go/core/api/auth/auth.dart';
import 'package:case_go/core/api/profile/profile.dart';
import 'package:case_go/core/storage/storage.dart';
import 'package:case_go/features/auth/bloc/auth_bloc.dart';
import 'package:case_go/features/auth/repository/auth_repo.dart';
import 'package:case_go/features/auth/ui/auth_screen.dart';
import 'package:case_go/features/home/home_bloc.dart';
import 'package:case_go/features/home/home_screen.dart';
import 'package:case_go/features/profile_setup/profile_setup_bloc.dart';
import 'package:case_go/features/profile_setup/profile_setup_extra.dart';
import 'package:case_go/features/profile_setup/profile_setup_repository.dart';
import 'package:case_go/features/profile_setup/screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',

    // ── Редиректы ──────────────────────────────────────────
    //
    // Логика:
    // 1. Главная страница доступна всем — редиректа на /auth нет.
    // 2. /auth недоступен авторизованным — редирект на /.
    // 3. /profile/setup недоступен неавторизованным — редирект на /auth.
    //
    redirect: (context, state) {
      final homeBloc = context.read<HomeBloc>();
      final isAuthenticated = homeBloc.state is Authenticated;
      final isLoading = homeBloc.state is HomeLoading;

      // Пока определяем состояние — не редиректим
      if (isLoading) return null;

      final location = state.matchedLocation;

      // Авторизованный пытается попасть на /auth — отправляем на главную
      if (isAuthenticated && location == '/auth') return '/';

      // Неавторизованный пытается попасть на /profile/setup — отправляем на /auth
      if (!isAuthenticated && location.startsWith('/profile/setup')) {
        return '/auth';
      }

      return null;
    },

    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => BlocProvider(
          create: (_) => AuthBloc(
            AuthRepository(
              api: GetIt.I<AuthApi>(),
              storage: GetIt.I<StorageService>(),
            ),
          ),
          child: const AuthScreen(),
        ),
      ),

      GoRoute(
        path: '/profile/setup',
        name: 'profileSetup',
        builder: (context, state) {
          // Достаём extra — если не передан, по умолчанию режим создания
          final extra = state.extra;
          final mode = extra is ProfileSetupExtra
              ? extra.mode
              : ProfileSetupMode.create;

          return BlocProvider(
            create: (_) => ProfileSetupBloc(
              ProfileSetupRepository(GetIt.I<ProfileApi>()),
            ),
            child: ProfileSetupScreen(mode: mode),
          );
        },
      ),
    ],
  );
}