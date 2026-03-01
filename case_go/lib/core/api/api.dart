/// Корневой barrel-файл — один импорт для всего API-слоя.
///
/// ```dart
/// import 'package:your_app/api/api.dart';
/// ```
///
/// ─────────────────────────────────────────────────────────────
/// БЛОК 1 — AUTH  (auth/)
/// ─────────────────────────────────────────────────────────────
///
/// [AuthApi]
///   Абстрактный класс. Описывает контракт аутентификации:
///   регистрация, получение и обновление токена, профиль /me.
///   Используй как тип в зависимостях (DI / тесты).
///
/// [AuthApiImpl]
///   Конкретная реализация [AuthApi] поверх package:http.
///   Принимает [baseUrl]. Не требует токена — все методы публичные.
///   Создай один раз и передавай через DI.
///
///   ```dart
///   final auth = AuthApiImpl(baseUrl: 'https://api.example.com');
///   final tokens = await auth.obtainToken({'email': '...', 'password': '...'});
///   ```
///
/// [ApiException]
///   Выбрасывается при HTTP-ошибках (4xx / 5xx).
///   Содержит [statusCode] и [message]. Лови везде, где делаешь await.
///
/// ─────────────────────────────────────────────────────────────
/// БЛОК 2 — PROFILE  (profile/)
/// ─────────────────────────────────────────────────────────────
///
/// [ProfileApi]
///   Абстрактный класс. Описывает контракт управления профилем:
///   CRUD профиля, социальных ссылок, целей, профессий,
///   категорий профессий и поиска пользователей.
///
/// [ProfileApiImpl]
///   Конкретная реализация [ProfileApi].
///   Требует [baseUrl] и [accessTokenProvider] — callback,
///   возвращающий актуальный access-токен (строку).
///   Токен подставляется в каждый запрос автоматически.
///
///   ```dart
///   final profile = ProfileApiImpl(
///     baseUrl: 'https://api.example.com',
///     accessTokenProvider: () => storage.accessToken,
///   );
///   final me = await profile.getProfile();
///   await profile.createSocialLink({'url': 'https://github.com/...'});
///   ```
///
/// ─────────────────────────────────────────────────────────────
/// БЛОК 3 — TRAINER  (trainer/)
/// ─────────────────────────────────────────────────────────────
///
/// [TrainerApi]
///   Абстрактный класс. Описывает контракт тренажёра:
///   CRUD кейсов, отправка результатов, история ответов, аналитика.
///   Ролевые ограничения (creator / admin) проверяются на бэкенде.
///
/// [TrainerApiImpl]
///   Конкретная реализация [TrainerApi].
///   Так же как [ProfileApiImpl], требует [accessTokenProvider].
///   Пагинация в [getCases] передаётся query-параметрами page / page_size.
///
///   ```dart
///   final trainer = TrainerApiImpl(
///     baseUrl: 'https://api.example.com',
///     accessTokenProvider: () => storage.accessToken,
///   );
///   final page = await trainer.getCases(page: 1, pageSize: 20);
///   await trainer.submitCaseResult(42, {'answers': [...]});
///   final history = await trainer.getHistory(caseId: 42);
///   ```
///
export 'auth/auth.dart';
export 'profile/profile.dart';
export 'cases/cases.dart';