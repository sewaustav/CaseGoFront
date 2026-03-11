import 'package:case_go/core/api/auth/auth.dart';
import 'package:case_go/core/api/auth/auth_api.dart';
import 'package:case_go/core/routing/router.dart';
import 'package:case_go/core/theme/app_palete.dart';
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

  // ИСПРАВЛЕНО: передаём accessTokenProvider чтобы getMe() работал с токеном
  getIt.registerSingleton<AuthApi>(
    AuthApiImpl(
      baseUrl: 'http://localhost:8000/api/v1/auth',
      accessTokenProvider: () => storage.accessTokenSync, // ← синхронный геттер
    ),
  );

  getIt.registerSingleton<HomeRepository>(
    HomeRepository(getIt<AuthApi>(), getIt<StorageService>()),
  );

  runApp(const CaseGo());
}



class CaseGo extends StatelessWidget {
  const CaseGo({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc(
        GetIt.I<HomeRepository>(),
      )..add(AppStarted()),
      child: MaterialApp.router(
        title: 'CaseGo',
        debugShowCheckedModeBanner: false,
        routerConfig: AppRouter.router,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppPalette.defaultPalette.background,
          extensions: [
            AppPalette.defaultPalette,
          ],
        ),
      ),
    );
  }
}