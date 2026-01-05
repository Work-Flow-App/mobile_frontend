import 'package:flutter/material.dart';
import 'package:mobile_frontend/data/models/auth_models.dart';
import 'package:mobile_frontend/data/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final _service = AuthService();
  AuthToken? token;

  Future<void> login(String u, String p) async {
    token = await _service.login(u, p);
    notifyListeners();
  }

  bool get isLoggedIn => token != null;
}
