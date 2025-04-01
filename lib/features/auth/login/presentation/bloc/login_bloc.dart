// lib/features/auth/login/presentation/bloc/login_bloc.dart
import 'package:architecture_scan_app/core/di/dependencies.dart' as di;
import 'package:architecture_scan_app/core/network/dio_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/user_login.dart';
import '../../domain/usecases/validate_token.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final UserLogin userLogin;
  final ValidateToken validateToken;

  LoginBloc({required this.userLogin, required this.validateToken})
    : super(LoginInitial()) {
    on<LoginButtonPressed>(_onLoginButtonPressed);
    on<CheckToken>(_onCheckToken);
  }

  /// Handle login button press event
  Future<void> _onLoginButtonPressed(
    LoginButtonPressed event,
    Emitter<LoginState> emit,
  ) async {
    // Show loading state
    emit(LoginLoading());

    // Call the login use case
    final result = await userLogin(
      LoginParams(
        userId: event.userId,
        password: event.password,
        name: event.name,
      ),
    );

    // Emit success or failure based on the result
    result.fold((failure) => emit(LoginFailure(message: failure.message)), (
      user,
    ) {
      // Set token immediately after successful login
      di.sl<DioClient>().setAuthToken(user.token);
      emit(LoginSuccess(user: user));
    });
  }

  /// Handle token check event
  Future<void> _onCheckToken(CheckToken event, Emitter<LoginState> emit) async {
    // Show loading state
    emit(TokenChecking());

    // Call the validate token use case
    final result = await validateToken(TokenParams(token: event.token));

    // Emit success or failure based on the result
    result.fold(
      (failure) => emit(LoginInitial()),
      (user) => emit(LoginSuccess(user: user)),
    );
  }
}
