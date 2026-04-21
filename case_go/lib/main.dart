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
          scaffoldBackgroundColor: AppPalette.defaultPalette.background,
          extensions: const [AppPalette.defaultPalette],
        ),
      ),
    );
  }
}
