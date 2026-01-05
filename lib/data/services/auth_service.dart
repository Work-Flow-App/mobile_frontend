import 'package:mobile_frontend/data/models/auth_models.dart';

class AuthService {
  Future<AuthToken> login(String username, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // In a real app, call your API here
    // You can throw exceptions if login fails
    if (username == 'worker' && password == '123') {
      return AuthToken('dummy-access', 'dummy-refresh');
    } else {
      throw Exception('Invalid credentials');
    }
  }
}
