import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/user.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/v1/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': event.email,
          'password': event.password,
        }),
      );
      print('Login API response: \\nStatus: \\${response.statusCode}\\nBody: \\${response.body}');

      if (response.statusCode == 200) {
        emit(AuthSuccess(User(
          username: event.email,
          password: event.password,
        )));
      } else {
        emit(const AuthFailure('Sai tài khoản hoặc mật khẩu'));
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