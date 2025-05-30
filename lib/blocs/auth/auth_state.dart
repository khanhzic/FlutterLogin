import '../../models/user.dart';

abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final User user;

  const AuthSuccess(this.user);
}

class AuthFailure extends AuthState {
  final String error;

  const AuthFailure(this.error);
} 