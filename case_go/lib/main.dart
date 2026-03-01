import 'package:case_go/core/routing/router.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const CaseGo());
}

class CaseGo extends StatelessWidget {
  const CaseGo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter App',
      debugShowCheckedModeBanner: false,
      // Подключаем наш роутер
      routerConfig: AppRouter.router,
      theme: ThemeData(useMaterial3: true),
    );
  }
}