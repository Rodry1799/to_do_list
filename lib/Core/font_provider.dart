import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider مسؤول فقط عن حجم الخط.
/// مستقل تمامًا عن ThemeProvider لضمان عدم تداخل الحالتين.
class FontProvider extends ChangeNotifier {
  static const String _keyFontSize = 'font_size_index';

  int _fontSizeIndex = 1; // 0=Small, 1=Medium, 2=Large

  int get fontSizeIndex => _fontSizeIndex;

  static const List<Map<String, dynamic>> fontSizeOptions = [
    {'label': 'Small', 'scale': 0.85},
    {'label': 'Medium', 'scale': 1.0},
    {'label': 'Large', 'scale': 1.2},
  ];

  double get textScaleFactor =>
      fontSizeOptions[_fontSizeIndex]['scale'] as double;

  FontProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _fontSizeIndex = prefs.getInt(_keyFontSize) ?? 1;
    notifyListeners();
  }

  Future<void> setFontSize(int index) async {
    _fontSizeIndex = index;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyFontSize, index);
    notifyListeners();
  }
}
