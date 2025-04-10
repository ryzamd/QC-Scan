import 'package:architecture_scan_app/features/auth/logout/domain/usecases/logout_usecase.dart';
import 'package:architecture_scan_app/features/auth/logout/presentation/bloc/logout_event.dart';
import 'package:architecture_scan_app/features/auth/logout/presentation/bloc/logout_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LogoutBloc extends Bloc<LogoutEvent, LogoutState> {
  final LogoutUseCase logoutUseCase;

  LogoutBloc({required this.logoutUseCase}) : super(LogoutInitial()) {
    on<LogoutButtonPressed>(_onLogoutButtonPressedAsync);
  }

  Future<void> _onLogoutButtonPressedAsync(
    LogoutButtonPressed event,
    Emitter<LogoutState> emit,
  ) async {
    emit(LogoutLoading());

    final result = await logoutUseCase(NoParams());

    result.fold(
      (failure) => emit(LogoutFailure(message: failure.message)),
      (success) => emit(LogoutSuccess()),
    );
  }
}