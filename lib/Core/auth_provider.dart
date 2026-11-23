import 'package:flutter/material.dart';
import '../Models/user_model.dart';
import '../Service/auth_service.dart';

enum AuthStatus { checking, authenticated, unauthenticated }

/// Provider مسؤول عن حالة المصادقة عبر كامل التطبيق.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.checking;
  UserModel? _user;
  String _errorMessage = '';

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    checkAuthStatus();
  }

  /// يُفحص عند إطلاق التطبيق — هل يوجد token محفوظ؟
  Future<void> checkAuthStatus() async {
    _status = AuthStatus.checking;
    notifyListeners();

    final savedUser = await _authService.getLoggedInUser();
    if (savedUser != null) {
      _user = savedUser;
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// تسجيل الدخول
  Future<bool> login(String email, String password) async {
    _errorMessage = '';
    notifyListeners();

    final result = await _authService.login(email, password);

    if (result['success'] == true) {
      _user = result['user'] as UserModel;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'] ?? 'Login failed';
      notifyListeners();
      return false;
    }
  }

  /// تسجيل الخروج
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
