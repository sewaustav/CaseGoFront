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

  // 1. Создаём и инициализируем storage ПЕРВЫМ
  final storage = StorageService();
  await storage.init();

  final getIt = GetIt.I;

  // 2. Регистрируем ОДИН инстанс storage
  getIt.registerSingleton<StorageService>(storage);

  // 3. AuthApiImpl получает замыкание на ТОТ ЖЕ объект storage
  //    () => storage.accessTokenSync — читает _cachedAccessToken напрямую
  //    После _saveTokens() кеш уже обновлён → getMe() получит свежий токен
  getIt.registerSingleton<AuthApi>(
    AuthApiImpl(
      baseUrl: 'http://localhost:8000/api/v1/auth', // 10.0.2.2 для Android эмулятора
      // baseUrl: 'http://localhost:8000/api/v1/auth', // для iOS симулятора / веба
      accessTokenProvider: () => storage.accessTokenSync,
      // usersBaseUrl автоматически = 'http://10.0.2.2:8000/api/v1/users'
    ),
  );

  getIt.registerSingleton<HomeRepository>(
    HomeRepository(
      getIt<AuthApi>(),
      getIt<StorageService>(), // тот же инстанс что и выше
    ),
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
          extensions: const [
            AppPalette.defaultPalette,
          ],
        ),
      ),
    );
  }
}