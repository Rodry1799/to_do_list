import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider مسؤول عن حالة الثيم (وضع، نسق ألوان).
/// منفصل تمامًا عن FontProvider لضمان عدم التداخل.
class ThemeProvider extends ChangeNotifier {
  static const String _keyDarkMode = 'is_dark_mode';
  static const String _keyColorScheme = 'color_scheme_index';

  bool _isDarkMode = false;
  int _colorSchemeIndex = 0;

  bool get isDarkMode => _isDarkMode;
  int get colorSchemeIndex => _colorSchemeIndex;

  // قائمة أنسقة الألوان المتاحة
  static const List<Map<String, dynamic>> colorOptions = [
    {'name': 'Indigo', 'seed': Color(0xFF5C6BC0)},
    {'name': 'Teal', 'seed': Color(0xFF009688)},
    {'name': 'Amber', 'seed': Color(0xFFFFC107)},
    {'name': 'Rose', 'seed': Color(0xFFE91E63)},
    {'name': 'Emerald', 'seed': Color(0xFF4CAF50)},
    {'name': 'Violet', 'seed': Color(0xFF7C3AED)},
  ];

  Color get seedColor => colorOptions[_colorSchemeIndex]['seed'] as Color;

  ThemeProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_keyDarkMode) ?? false;
    _colorSchemeIndex = prefs.getInt(_keyColorScheme) ?? 0;
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
    notifyListeners();
  }

  Future<void> setColorScheme(int index) async {
    _colorSchemeIndex = index;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyColorScheme, index);
    notifyListeners();
  }

  ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        fontFamily: 'Inter',
      );

  ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        fontFamily: 'Inter',
      );
}
