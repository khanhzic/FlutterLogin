abstract class AuthEvent {
  const AuthEvent();
}

class LoginButtonPressed extends AuthEvent {
  final String username;
  final String password;

  const LoginButtonPressed({
    required this.username,
    required this.password,
  });
}

class LogoutButtonPressed extends AuthEvent {} 