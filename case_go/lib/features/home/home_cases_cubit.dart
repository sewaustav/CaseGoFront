import 'package:case_go/core/api/cases/cases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── State ─────────────────────────────────────────────────────────────────────

abstract class HomeCasesState {}

class HomeCasesLoading extends HomeCasesState {}

class HomeCasesLoaded extends HomeCasesState {
  /// Кейс дня — выбирается детерминировано по дате
  final Map<String, dynamic>? featuredCase;

  /// Все загруженные кейсы (первая страница, до 100 шт.)
  final List<Map<String, dynamic>> cases;

  /// Количество кейсов по значению category
  /// ключ — то, что вернул бэк (String или int)
  final Map<dynamic, int> categoryCounts;

  HomeCasesLoaded({
    required this.featuredCase,
    required this.cases,
    required this.categoryCounts,
  });
}

class HomeCasesError extends HomeCasesState {}

// ── Cubit ─────────────────────────────────────────────────────────────────────

class HomeCasesCubit extends Cubit<HomeCasesState> {
  final CaseGoApi _api;

  HomeCasesCubit(this._api) : super(HomeCasesLoading());

  /// Загружает данные только если ещё не загружались (или была ошибка).
  /// Вызывай при повторных попаданиях на экран — не перезагрузит, если уже OK.
  Future<void> loadIfNeeded() async {
    if (state is! HomeCasesLoaded) await load();
  }

  Future<void> load() async {
    emit(HomeCasesLoading());
    try {
      final cases = await _api.getCases(limit: 100, page: 1);

      // Подсчёт кейсов по категории
      final counts = <dynamic, int>{};
      for (final c in cases) {
        final cat = c['category'];
        if (cat != null) {
          counts[cat] = (counts[cat] ?? 0) + 1;
        }
      }

      // Выбираем «кейс дня» детерминировано по порядковому номеру дня в году
      Map<String, dynamic>? featured;
      if (cases.isNotEmpty) {
        final now = DateTime.now();
        final dayOfYear = now.difference(DateTime(now.year)).inDays;
        featured = cases[dayOfYear % cases.length];
      }

      emit(HomeCasesLoaded(
        featuredCase: featured,
        cases: cases,
        categoryCounts: counts,
      ));
    } catch (_) {
      emit(HomeCasesError());
    }
  }
}
