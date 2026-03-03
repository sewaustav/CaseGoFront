import 'package:case_go/features/home/home_screen.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: "/",
    routes: [
      GoRoute(
        path: "/",
        name: "home",
        builder: (context, state) => const HomeScreen(),
      ),
      
      // Сюда потом будешь добавлять остальные страницы (профиль, настройки и т.д.)
      // GoRoute(
      //   path: "/login",
      //   builder: (context, state) => const LoginScreen(),
      // ),
    ],
  );
}