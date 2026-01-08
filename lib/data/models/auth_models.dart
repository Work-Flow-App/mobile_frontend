class LoginRequest {
  final String userName;
  final String password;

  LoginRequest(this.userName, this.password);
}

class AuthToken {
  final String accessToken;
  final String refreshToken;

  AuthToken(this.accessToken, this.refreshToken);
}
