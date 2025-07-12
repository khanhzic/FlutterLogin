import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/user.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';
import '../../services/api_common.dart';
import '../../services/master_data_service.dart';

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
      final data = await ApiCommon.login(event.email, event.password);
      if (data.containsKey('user') && data.containsKey('access_token')) {
        final userJson = data['user'];
        final user = User.fromJson(userJson);
        final accessToken = data['access_token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', accessToken);
        await prefs.setString('user', jsonEncode(userJson));
        
        // Call master data API after successful login
        try {
          // Cần truyền context từ widget xuống bloc khi gọi hàm này
          // await MasterDataService.getMasterData(context);
        } catch (e) {
          print('Error fetching master data after login: $e');
          // Don't fail login if master data fails
        }
        
        emit(AuthSuccess(user));
      } else {
        emit(AuthFailure(data['message'] ?? 'Sai tài khoản hoặc mật khẩu'));
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
    
    // Clear token from API cache
    await ApiCommon.clearToken();
    
    emit(AuthInitial());
  }
} 