import 'package:case_go/core/api/cases/cases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── State ─────────────────────────────────────────────────────────────────────

abstract class CasesState {}

class CasesLoading extends CasesState {}

class CasesLoaded extends CasesState {
  final List<Map<String, dynamic>> cases;
  final bool hasMore;
  final int page;
  final String? topicFilter;
  final bool loadingMore;

  CasesLoaded({
    required this.cases,
    required this.hasMore,
    required this.page,
    this.topicFilter,
    this.loadingMore = false,
  });

  CasesLoaded copyWith({
    List<Map<String, dynamic>>? cases,
    bool? hasMore,
    int? page,
    String? topicFilter,
    bool clearTopic = false,
    bool? loadingMore,
  }) =>
      CasesLoaded(
        cases: cases ?? this.cases,
        hasMore: hasMore ?? this.hasMore,
        page: page ?? this.page,
        topicFilter: clearTopic ? null : (topicFilter ?? this.topicFilter),
        loadingMore: loadingMore ?? this.loadingMore,
      );
}

class CasesError extends CasesState {
  final String message;
  CasesError(this.message);
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

class CasesCubit extends Cubit<CasesState> {
  final CaseGoApi _api;
  static const _pageSize = 20;

  CasesCubit(this._api) : super(CasesLoading());

  Future<void> load({String? topic}) async {
    emit(CasesLoading());
    try {
      final list = await _api.getCases(
          limit: _pageSize, page: 1, topic: topic);
      emit(CasesLoaded(
        cases: list,
        hasMore: list.length >= _pageSize,
        page: 1,
        topicFilter: topic,
      ));
    } catch (e) {
      emit(CasesError(e.toString()));
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! CasesLoaded || !current.hasMore || current.loadingMore) {
      return;
    }
    emit(current.copyWith(loadingMore: true));
    try {
      final nextPage = current.page + 1;
      final list = await _api.getCases(
        limit: _pageSize,
        page: nextPage,
        topic: current.topicFilter,
      );
      emit(current.copyWith(
        cases: [...current.cases, ...list],
        hasMore: list.length >= _pageSize,
        page: nextPage,
        loadingMore: false,
      ));
    } catch (_) {
      emit(current.copyWith(loadingMore: false));
    }
  }

  Future<void> applyTopicFilter(String? topic) async {
    await load(topic: topic?.isEmpty == true ? null : topic);
  }
}
