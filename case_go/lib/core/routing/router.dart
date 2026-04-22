import 'package:case_go/core/api/admin/admin.dart';
import 'package:case_go/core/api/case_profile/case_profile.dart';
import 'package:case_go/core/api/cases/cases.dart';
import 'package:case_go/core/api/profile/profile.dart';
import 'package:case_go/features/admin/admin_cubit.dart';
import 'package:case_go/features/admin/admin_screen.dart';
import 'package:case_go/features/auth/bloc/auth_bloc.dart';
import 'package:case_go/features/auth/repository/auth_repo.dart';
import 'package:case_go/features/auth/ui/auth_screen.dart';
import 'package:case_go/features/cases/cases_cubit.dart';
import 'package:case_go/features/cases/cases_screen.dart';
import 'package:case_go/features/dialog/dialog_cubit.dart';
import 'package:case_go/features/dialog/dialog_screen.dart';
import 'package:case_go/features/history/history_cubit.dart';
import 'package:case_go/features/history/history_screen.dart';
import 'package:case_go/features/home/home_bloc.dart';
import 'package:case_go/features/home/home_screen.dart';
import 'package:case_go/features/instructions/instructions_screen.dart';
import 'package:case_go/features/profile/profile_cubit.dart';
import 'package:case_go/features/profile/profile_screen.dart';
import 'package:case_go/features/profile_setup/profile_setup_bloc.dart';
import 'package:case_go/features/profile_setup/profile_setup_extra.dart';
import 'package:case_go/features/profile_setup/profile_setup_repository.dart';
import 'package:case_go/features/profile_setup/screen.dart';
import 'package:case_go/features/result/result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'dart:developer' as dev;

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
  static _BlocRefreshListenable? _refreshListenable;

  static GoRouter createRouter(HomeBloc homeBloc) {
    _refreshListenable = _BlocRefreshListenable(homeBloc);

    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/',
      refreshListenable: _refreshListenable,

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

        // Admin route requires role=0
        if (location.startsWith('/admin')) {
          if (!isAuthenticated) return '/auth';
          final role = (homeBlocState as Authenticated).user['role'] as int? ?? 1;
          if (role != 0) return '/';
          return null;
        }

        // Protected routes require auth
        final protectedRoutes = [
          '/profile',
          '/cases',
          '/dialog',
          '/result',
          '/history',
        ];
        final isProtected = protectedRoutes.any((r) => location.startsWith(r));
        if (!isAuthenticated && isProtected) return '/auth';

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

        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => BlocProvider(
            create: (_) => ProfileCubit(
              GetIt.I<ProfileApi>(),
              GetIt.I<CaseProfileApi>(),
            )..load(),
            child: const ProfileScreen(),
          ),
        ),

        GoRoute(
          path: '/cases',
          name: 'cases',
          builder: (context, state) => BlocProvider(
            create: (_) => CasesCubit(GetIt.I<CaseGoApi>()),
            child: const CasesScreen(),
          ),
        ),

        GoRoute(
          path: '/cases/:caseId',
          name: 'caseDialog',
          builder: (context, state) {
            final caseId = int.parse(state.pathParameters['caseId']!);
            final extra = state.extra as Map<String, dynamic>?;
            final topic = extra?['topic'] as String? ?? 'Кейс #$caseId';
            return BlocProvider(
              create: (_) => DialogCubit(GetIt.I<CaseGoApi>()),
              child: DialogScreen(caseId: caseId, caseTopic: topic),
            );
          },
        ),

        GoRoute(
          path: '/result',
          name: 'result',
          builder: (context, state) {
            final result = state.extra as Map<String, dynamic>? ?? {};
            return ResultScreen(result: result);
          },
        ),

        GoRoute(
          path: '/history',
          name: 'history',
          builder: (context, state) => BlocProvider(
            create: (_) => HistoryCubit(GetIt.I<CaseProfileApi>()),
            child: const HistoryScreen(),
          ),
        ),

        GoRoute(
          path: '/instructions',
          name: 'instructions',
          builder: (context, state) => const InstructionsScreen(),
        ),

        GoRoute(
          path: '/admin',
          name: 'admin',
          builder: (context, state) => BlocProvider(
            create: (_) => AdminCubit(
              GetIt.I<CaseGoApi>(),
              GetIt.I<AdminApi>(),
            ),
            child: const AdminScreen(),
          ),
        ),
      ],
    );
  }
}
