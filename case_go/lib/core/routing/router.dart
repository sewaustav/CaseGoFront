import 'package:case_go/core/api/profile/profile.dart';
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
import 'dart:developer' as dev;

// ── Listenable-обёртка над HomeBloc ──────────────────────────────────────────
//
// GoRouter.refreshListenable принимает Listenable.
// BlocBase не реализует Listenable из коробки, поэтому оборачиваем.
// Каждый раз когда HomeBloc эмитит новое состояние — нотифицируем роутер,
// и он перезапускает redirect callback с актуальным состоянием.
//
class _BlocRefreshListenable extends ChangeNotifier {
  _BlocRefreshListenable(this._bloc) {
    _bloc.stream.listen((_) {
      dev.log('🔄 HomeBloc state changed → notifying GoRouter', name: 'Router');
      notifyListeners();
    });
  }

  final HomeBloc _bloc;
}

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  // Создаём listenable один раз — он живёт пока живёт роутер
  static _BlocRefreshListenable? _refreshListenable;

  static GoRouter createRouter(HomeBloc homeBloc) {
    _refreshListenable = _BlocRefreshListenable(homeBloc);

    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/',
      refreshListenable: _refreshListenable,

      // ── Редиректы ──────────────────────────────────────────
      redirect: (context, state) {
        final homeBlocState = homeBloc.state;
        final isLoading = homeBlocState is HomeLoading;
        final isAuthenticated = homeBlocState is Authenticated;
        final needsProfile = homeBlocState is AuthenticatedNeedsProfile;
        final location = state.matchedLocation;

        dev.log(
          '🧭 redirect: location=$location | '
          'loading=$isLoading | auth=$isAuthenticated | needsProfile=$needsProfile',
          name: 'Router',
        );

        if (isLoading) return null;

        if (location.startsWith('/profile/setup')) {
          if (!isAuthenticated && !needsProfile) return '/auth';
          return null;
        }

        if (needsProfile) {
          dev.log('🧭 redirect → /profile/setup', name: 'Router');
          return '/profile/setup';
        }

        if (isAuthenticated && location == '/auth') {
          dev.log('🧭 redirect → /', name: 'Router');
          return '/';
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
            create: (_) => AuthBloc(GetIt.I<AuthRepository>()),
            child: const AuthScreen(),
          ),
        ),

        GoRoute(
          path: '/profile/setup',
          name: 'profileSetup',
          builder: (context, state) {
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
}