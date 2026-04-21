import 'package:case_go/core/api/case_profile/case_profile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class HistoryState {}

class HistoryLoading extends HistoryState {}

class HistoryLoaded extends HistoryState {
  final List<Map<String, dynamic>> items;
  HistoryLoaded(this.items);
}

class HistoryError extends HistoryState {
  final String message;
  HistoryError(this.message);
}

class HistoryCubit extends Cubit<HistoryState> {
  final CaseProfileApi _api;
  HistoryCubit(this._api) : super(HistoryLoading());

  Future<void> load() async {
    emit(HistoryLoading());
    try {
      final items = await _api.getHistory();
      emit(HistoryLoaded(items));
    } catch (e) {
      emit(HistoryError(e.toString()));
    }
  }
}
