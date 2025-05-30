import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/user.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<LoginButtonPressed>(_onLoginButtonPressed);
    on<LogoutButtonPressed>(_onLogoutButtonPressed);
  }

  void _onLoginButtonPressed(
    LoginButtonPressed event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Check credentials (hardcoded for demo)
      if (event.username == 'admin' && event.password == '123456') {
        final user = User(
          username: event.username,
          password: event.password,
        );
        emit(AuthSuccess(user));
      } else {
        emit(const AuthFailure('Invalid username or password'));
      }
    } catch (error) {
      emit(AuthFailure(error.toString()));
    }
  }

  void _onLogoutButtonPressed(
    LogoutButtonPressed event,
    Emitter<AuthState> emit,
  ) {
    emit(AuthInitial());
  }
} 