import 'package:case_go/features/home/home_logic.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// --- События ---
abstract class HomeEvent {}
class AppStarted extends HomeEvent {}

// --- Состояния ---
abstract class HomeState {}
class HomeLoading extends HomeState {}
class Authenticated extends HomeState {
  final Map<String, dynamic> user;
  Authenticated(this.user);
}
class Unauthenticated extends HomeState {}

// --- Сам Блок ---
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository repository;

  HomeBloc(this.repository) : super(HomeLoading()) {
    on<AppStarted>((event, emit) async {
      try {
        final user = await repository.checkAuth();
        if (user != null) {
          emit(Authenticated(user));
        } else {
          emit(Unauthenticated());
        }
      } catch (e) {
        emit(Unauthenticated());
      }
    });
  }
}