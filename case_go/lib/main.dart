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

  // 1. Инициализируем хранилище
  final storage = StorageService();
  await storage.init();

  // 2. Регистрируем зависимости в GetIt (Service Locator)
  final getIt = GetIt.I;
  
  getIt.registerSingleton<StorageService>(storage);
  
  // Регистрируем реализацию API
  getIt.registerSingleton<AuthApi>(
    AuthApiImpl(baseUrl: 'https://api.your-server.com'),
  );

  // Регистрируем репозиторий, прокидывая в него API и Storage из GetIt
  getIt.registerSingleton<HomeRepository>(
    HomeRepository(getIt<AuthApi>(), getIt<StorageService>()),
  );

  runApp(const CaseGo());
}

class CaseGo extends StatelessWidget {
  const CaseGo({super.key});

  @override
  Widget build(BuildContext context) {
    // 3. Оборачиваем всё приложение в BlocProvider, 
    // чтобы HomeBloc был доступен глобально для роутинга и проверки сессии.
    return BlocProvider(
      create: (context) => HomeBloc(
        GetIt.I<HomeRepository>(),
      )..add(AppStarted()), // Сразу запускаем проверку логина
      child: MaterialApp.router(
        title: 'CaseGo',
        debugShowCheckedModeBanner: false,
        routerConfig: AppRouter.router,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppPalette.defaultPalette.background,
          extensions: [
            AppPalette.defaultPalette, // Регистрируем наши кастомные цвета
          ],
        ),
      ),
    );
  }
}