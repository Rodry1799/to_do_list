import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/user_model.dart';

class AuthService {
  // ملاحظة: استخدم 10.0.2.2 بدلاً من localhost إذا كنت تستخدم محاكي أندرويد
  static const String _baseUrl = "http://localhost/to_do_list_APIs";
  static const String _keyUserId = 'user_id';
  static const String _keyUsername = 'username';
  static const String _keyEmail = 'user_email';
  static const String _keyToken = 'auth_token';

  // ─── تسجيل الدخول ───────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/login.php"),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'success') {
          final user = UserModel.fromJson(result['user']);
          await _saveSession(user);
          return {'success': true, 'user': user};
        } else {
          return {'success': false, 'message': result['message'] ?? 'Login failed'};
        }
      } else {
        return {'success': false, 'message': 'Server error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ─── تسجيل الخروج ───────────────────────────────────────────────────────────
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyToken);
  }

  // ─── التحقق من وجود جلسة محفوظة ─────────────────────────────────────────────
  Future<UserModel?> getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    if (token == null || token.isEmpty) return null;

    return UserModel(
      id: prefs.getInt(_keyUserId) ?? 0,
      username: prefs.getString(_keyUsername) ?? '',
      email: prefs.getString(_keyEmail) ?? '',
      token: token,
    );
  }

  // ─── حفظ الجلسة محليًا ───────────────────────────────────────────────────────
  Future<void> _saveSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, user.id);
    await prefs.setString(_keyUsername, user.username);
    await prefs.setString(_keyEmail, user.email);
    await prefs.setString(_keyToken, user.token);
  }
}
