import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _soundEnabled = true;
  Locale _locale = const Locale('pt', 'BR');
  bool _isInitialized = false;

  bool get isDarkMode => _isDarkMode;
  bool get soundEnabled => _soundEnabled;
  Locale get locale => _locale;
  bool get isInitialized => _isInitialized;

  static const String _themeKey = 'theme_mode';
  static const String _soundKey = 'sound_enabled';
  static const String _localeKey = 'locale';

  /// Inicializa as configurações carregando do SharedPreferences
  /// Na primeira vez, usa o tema do sistema
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Verifica se é a primeira vez
    final bool hasThemePreference = prefs.containsKey(_themeKey);
    
    if (hasThemePreference) {
      // Carrega preferências salvas
      _isDarkMode = prefs.getBool(_themeKey) ?? false;
    } else {
      // Primeira vez - usa o tema do sistema
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      _isDarkMode = brightness == Brightness.dark;
      // Salva a preferência inicial
      await prefs.setBool(_themeKey, _isDarkMode);
    }
    
    // Carrega outras configurações
    _soundEnabled = prefs.getBool(_soundKey) ?? true;
    
    final localeString = prefs.getString(_localeKey) ?? 'pt_BR';
    final localeParts = localeString.split('_');
    _locale = Locale(localeParts[0], localeParts.length > 1 ? localeParts[1] : '');
    
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _saveTheme();
    notifyListeners();
  }

  Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;
    await _saveSound();
    notifyListeners();
  }

  Future<void> setLanguage(Locale locale) async {
    _locale = locale;
    await _saveLocale();
    notifyListeners();
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
  }

  Future<void> _saveSound() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundKey, _soundEnabled);
  }

  Future<void> _saveLocale() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, '${_locale.languageCode}_${_locale.countryCode ?? ''}');
  }
}
