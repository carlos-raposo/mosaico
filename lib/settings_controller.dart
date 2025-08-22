import 'package:flutter/material.dart';

class SettingsController extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _soundEnabled = true;
  Locale _locale = const Locale('pt', 'BR');

  bool get isDarkMode => _isDarkMode;
  bool get soundEnabled => _soundEnabled;
  Locale get locale => _locale;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void toggleSound() {
    _soundEnabled = !_soundEnabled;
    notifyListeners();
  }

  void setLanguage(Locale locale) {
    _locale = locale;
    notifyListeners();
  }
}
