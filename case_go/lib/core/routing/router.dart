import 'package:case_go/features/auth/bloc/auth_bloc.dart';
import 'package:case_go/features/auth/repository/auth_repo.dart';
import 'package:case_go/features/auth/ui/auth_screen.dart';
import 'package:case_go/features/home/home_bloc.dart';
import 'package:case_go/features/home/home_screen.dart';
import 'package:case_go/core/api/auth/auth.dart';
import 'package:case_go/core/storage/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  // Ключ для навигатора — нужен для redirect
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    
    // Редирект: если не авторизован — на /auth, если авторизован и идёт на /auth — на /
    redirect: (context, state) {
      final homeBloc = context.read<HomeBloc>();
      final isAuthenticated = homeBloc.state is Authenticated;
      final isLoading = homeBloc.state is HomeLoading;
      final goingToAuth = state.matchedLocation == '/auth';

      // Пока грузимся — не редиректим
      if (isLoading) return null;

      // Не авторизован и не идёт на /auth — отправляем на /auth
      if (!isAuthenticated && !goingToAuth) return '/auth';

      // Авторизован и идёт на /auth — отправляем на /
      if (isAuthenticated && goingToAuth) return '/';

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
    ],
  );
}