import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/user.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
      ).timeout(const Duration(seconds: 60), onTimeout: () {
        throw Exception('Kết nối quá lâu, vui lòng thử lại.');
      });
      print('Login API response: \nStatus: \${response.statusCode}\nBody: \${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userJson = data['user'];
        final user = User.fromJson(userJson);
        final accessToken = data['access_token'];
        // Lưu token và user vào SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', accessToken);
        await prefs.setString('user', jsonEncode(userJson));
        emit(AuthSuccess(user));
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
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user');
    emit(AuthInitial());
  }
} 