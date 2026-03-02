import 'package:flutter/material.dart';
import 'package:cthree/core/models/user_model.dart';
import 'package:cthree/core/api/auth_repository.dart';

enum AuthStatus { initial, authenticating, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();

  UserModel? _user;
  AuthStatus _status = AuthStatus.initial;

  UserModel? get user => _user;
  AuthStatus get status => _status;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> initialize() async {
    _status = AuthStatus.authenticating;
    notifyListeners();

    final user = await _repository.bootstrapAuth();

    if (user != null) {
      _user = user;
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.authenticating;
    notifyListeners();

    final user = await _repository.pwdLogin(email, password);

    if (user != null) {
      _status = AuthStatus.authenticated;
      _user = user;
      notifyListeners();
      return true;
    }
    _status = AuthStatus.unauthenticated;
    notifyListeners();
    return false;
  }

  Future<bool> signup(String email, String password, String username, String description) async {
    _status = AuthStatus.authenticating;
    notifyListeners();

    final user = await _repository.signUp(email: email, password: password, username: username, description: description);

    if (user != null) {
      _status = AuthStatus.authenticated;
      _user = user;
      notifyListeners();
      return true;
    }
    _status = AuthStatus.unauthenticated;
    notifyListeners();
    return false;
  }
}