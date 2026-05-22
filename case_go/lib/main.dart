import 'package:case_go/core/api/admin/admin.dart';
import 'package:case_go/core/api/admin/admin_api.dart';
import 'package:case_go/core/api/auth/auth.dart';
import 'package:case_go/core/api/auth/auth_api.dart';
import 'package:case_go/core/api/case_profile/case_profile.dart';
import 'package:case_go/core/api/case_profile/case_profile_impl.dart';
import 'package:case_go/core/api/cases/cases.dart';
import 'package:case_go/core/api/cases/cases_api.dart';
import 'package:case_go/core/api/profile/profile.dart';
import 'package:case_go/core/api/profile/profile_api.dart';
import 'package:case_go/core/config.dart';
import 'package:case_go/core/routing/router.dart';
import 'package:case_go/core/theme/app_palete.dart';
import 'package:case_go/features/auth/repository/auth_repo.dart';
import 'package:case_go/features/home/home_bloc.dart';
import 'package:case_go/core/storage/storage.dart';
import 'package:case_go/features/home/home_logic.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = StorageService();
  await storage.init();

  final getIt = GetIt.I;

  getIt.registerSingleton<StorageService>(storage);

  getIt.registerSingleton<AuthApi>(
    AuthApiImpl(
      baseUrl: AppConfig.authUrl,
      accessTokenProvider: () => storage.accessTokenSync,
    ),
  );

  getIt.registerSingleton<ProfileApi>(
    ProfileApiImpl(
      baseUrl: AppConfig.profileUrl,
      accessTokenProvider: () => storage.accessTokenSync ?? '',
    ),
  );

  getIt.registerSingleton<CaseGoApi>(
    CaseGoApiImpl(
      baseUrl: AppConfig.caseGoUrl,
      accessTokenProvider: () => storage.accessTokenSync ?? '',
    ),
  );

  getIt.registerSingleton<CaseProfileApi>(
    CaseProfileApiImpl(
      baseUrl: AppConfig.caseProfileUrl,
      accessTokenProvider: () => storage.accessTokenSync ?? '',
    ),
  );

  getIt.registerSingleton<AdminApi>(
    AdminApiImpl(
      usersBaseUrl: '${AppConfig.authUrl.replaceFirst('/auth', '/users')}',
      accessTokenProvider: () => storage.accessTokenSync ?? '',
    ),
  );

  getIt.registerSingleton<AuthRepository>(
    AuthRepository(
      api: getIt<AuthApi>(),
      profileApi: getIt<ProfileApi>(),
      storage: getIt<StorageService>(),
    ),
  );

  getIt.registerSingleton<HomeRepository>(
    HomeRepository(getIt<AuthRepository>()),
  );

  final homeBloc = HomeBloc(getIt<HomeRepository>())..add(AppStarted());

  runApp(CaseGo(homeBloc: homeBloc));
}

class CaseGo extends StatelessWidget {
  final HomeBloc homeBloc;

  const CaseGo({super.key, required this.homeBloc});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: homeBloc,
      child: MaterialApp.router(
        title: 'CaseGo',
        debugShowCheckedModeBanner: false,
        routerConfig: AppRouter.createRouter(homeBloc),
        theme: ThemeData(
          useMaterial3: true,
          // ── Sage palette ────────────────────────────────────────────
          scaffoldBackgroundColor: AppPalette.defaultPalette.background,
          extensions: const [AppPalette.defaultPalette],
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppPalette.primary,
            primary: AppPalette.primary,
            secondary: AppPalette.accentWarm,
            tertiary: AppPalette.accentYellow,
            surface: AppPalette.defaultPalette.surface,
            onPrimary: const Color(0xFFFAF6EC),
            onSurface: AppPalette.ink,
          ),
          // ── Базовый шрифт UI ────────────────────────────────────────
          fontFamily: 'Onest',
          textTheme: const TextTheme(
            displayLarge: TextStyle(
              fontFamily: 'Unbounded',
              fontWeight: FontWeight.w700,
              letterSpacing: -1.0,
              color: AppPalette.ink,
            ),
            headlineMedium: TextStyle(
              fontFamily: 'Unbounded',
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: AppPalette.ink,
            ),
            titleLarge: TextStyle(
              fontFamily: 'Unbounded',
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: AppPalette.ink,
            ),
            bodyLarge: TextStyle(
              fontWeight: FontWeight.w500,
              color: AppPalette.ink,
            ),
            bodyMedium: TextStyle(
              fontWeight: FontWeight.w500,
              color: AppPalette.ink2,
            ),
          ),
          // ── Кнопки ──────────────────────────────────────────────────
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: AppPalette.primary,
              foregroundColor: const Color(0xFFFAF6EC),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
          // ── Поля ввода ───────────────────────────────────────────────
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Color(0xFFE2DCCB), // AppPalette.bg2
          ),
          // ── AppBar ───────────────────────────────────────────────────
          appBarTheme: AppBarTheme(
            backgroundColor: AppPalette.defaultPalette.background,
            foregroundColor: AppPalette.ink,
            elevation: 0,
            centerTitle: false,
            titleTextStyle: const TextStyle(
              fontFamily: 'Unbounded',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppPalette.ink,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}
