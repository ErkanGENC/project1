import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../models/user_settings_model.dart';
import '../services/api_service.dart';

class ThemeService extends ChangeNotifier {
  // Tema modu (açık/koyu)
  bool _isDarkMode = false;

  // Font boyutu (1.0 = normal boyut)
  double _fontSize = 1.0;

  // Font ailesi
  String _fontFamily = 'Default';

  // Dil
  String _language = 'tr';

  // API servisi
  final ApiService _apiService = ApiService();

  // Getter'lar
  bool get isDarkMode => _isDarkMode;
  double get fontSize => _fontSize;
  String get fontFamily => _fontFamily;
  String get language => _language;

  // Tema
  ThemeData get theme =>
      _isDarkMode ? _getCustomDarkTheme() : _getCustomLightTheme();

  // Başlangıç ayarlarını yükle
  Future<void> loadSettings() async {
    try {
      final settings = await _apiService.getUserSettings();

      if (settings != null) {
        _isDarkMode = settings.isDarkMode;
        _fontSize = settings.fontSize;
        _fontFamily = settings.fontFamily;
        _language = settings.language;
        notifyListeners();
      }
    } catch (e) {
      // Hata durumunda varsayılan ayarları kullan
      _isDarkMode = false;
      _fontSize = 1.0;
      _fontFamily = 'Default';
      _language = 'tr';
    }
  }

  // Tema modunu değiştir
  Future<void> toggleThemeMode() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    await _saveSettings();
  }

  // Tema modunu ayarla
  Future<void> setThemeMode(bool isDarkMode) async {
    if (_isDarkMode != isDarkMode) {
      _isDarkMode = isDarkMode;
      notifyListeners();
      await _saveSettings();
    }
  }

  // Font boyutunu ayarla
  Future<void> setFontSize(double fontSize) async {
    if (_fontSize != fontSize) {
      _fontSize = fontSize;
      notifyListeners();
      await _saveSettings();
    }
  }

  // Font ailesini ayarla
  Future<void> setFontFamily(String fontFamily) async {
    if (_fontFamily != fontFamily) {
      _fontFamily = fontFamily;
      notifyListeners();
      await _saveSettings();
    }
  }

  // Dili ayarla
  Future<void> setLanguage(String language) async {
    if (_language != language) {
      _language = language;
      notifyListeners();
      await _saveSettings();
    }
  }

  // Ayarları kaydet
  Future<void> _saveSettings() async {
    try {
      final userData = await _apiService.getUserData();

      if (userData != null && userData.containsKey('id')) {
        final settings = UserSettings(
          userId: userData['id'],
          isDarkMode: _isDarkMode,
          fontFamily: _fontFamily,
          fontSize: _fontSize,
          language: _language,
        );

        await _apiService.updateUserSettings(settings);
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  // Özel açık tema
  ThemeData _getCustomLightTheme() {
    final baseTheme = AppTheme.lightTheme;

    // Font boyutunu ayarla
    final textTheme = baseTheme.textTheme;
    final adjustedTextTheme = textTheme.copyWith(
      displayLarge: textTheme.displayLarge?.copyWith(fontSize: 24 * _fontSize),
      titleLarge: textTheme.titleLarge?.copyWith(fontSize: 18 * _fontSize),
      bodyLarge: textTheme.bodyLarge?.copyWith(fontSize: 16 * _fontSize),
      bodySmall: textTheme.bodySmall?.copyWith(fontSize: 14 * _fontSize),
    );

    return baseTheme.copyWith(
      textTheme: adjustedTextTheme,
    );
  }

  // Özel koyu tema
  ThemeData _getCustomDarkTheme() {
    // Koyu tema renkleri
    const darkPrimaryColor = Color(0xFF0277BD); // Daha koyu mavi
    const darkBackgroundColor = Color(0xFF121212); // Koyu arka plan
    const darkCardColor = Color(0xFF1E1E1E); // Koyu kart rengi
    const darkTextColor = Color(0xFFECEFF1); // Açık metin rengi
    const darkSecondaryTextColor = Color(0xFFB0BEC5); // Gri metin rengi

    // Koyu tema oluştur
    final darkTheme = ThemeData.dark().copyWith(
      primaryColor: darkPrimaryColor,
      scaffoldBackgroundColor: darkBackgroundColor,
      cardColor: darkCardColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkPrimaryColor,
        foregroundColor: darkTextColor,
        elevation: 0,
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: darkTextColor,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: darkTextColor,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: darkTextColor,
        ),
        bodySmall: TextStyle(
          fontSize: 14,
          color: darkSecondaryTextColor,
        ),
      ),
    );

    // Font boyutunu ayarla
    final textTheme = darkTheme.textTheme;
    final adjustedTextTheme = textTheme.copyWith(
      displayLarge: textTheme.displayLarge?.copyWith(fontSize: 24 * _fontSize),
      titleLarge: textTheme.titleLarge?.copyWith(fontSize: 18 * _fontSize),
      bodyLarge: textTheme.bodyLarge?.copyWith(fontSize: 16 * _fontSize),
      bodySmall: textTheme.bodySmall?.copyWith(fontSize: 14 * _fontSize),
    );

    return darkTheme.copyWith(
      textTheme: adjustedTextTheme,
    );
  }
}
