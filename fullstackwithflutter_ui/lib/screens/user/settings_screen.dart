import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../services/theme_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  // Font boyutu seçenekleri
  final List<Map<String, dynamic>> _fontSizeOptions = [
    {'label': 'Küçük', 'value': 0.8},
    {'label': 'Normal', 'value': 1.0},
    {'label': 'Büyük', 'value': 1.2},
    {'label': 'Çok Büyük', 'value': 1.4},
  ];

  // Font ailesi seçenekleri
  final List<Map<String, dynamic>> _fontFamilyOptions = [
    {'label': 'Varsayılan', 'value': 'Default'},
    {'label': 'Roboto', 'value': 'Roboto'},
    {'label': 'Open Sans', 'value': 'OpenSans'},
    {'label': 'Montserrat', 'value': 'Montserrat'},
  ];

  // Dil seçenekleri
  final List<Map<String, dynamic>> _languageOptions = [
    {'label': 'Türkçe', 'value': 'tr'},
    {'label': 'English', 'value': 'en'},
  ];

  @override
  Widget build(BuildContext context) {
    // ThemeService'e erişim
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tema Ayarları
            _buildSectionTitle('Tema Ayarları'),
            _buildThemeSettings(themeService),
            const Divider(height: 32),

            // Font Ayarları
            _buildSectionTitle('Font Ayarları'),
            _buildFontSettings(themeService),
            const Divider(height: 32),

            // Dil Ayarları
            _buildSectionTitle('Dil Ayarları'),
            _buildLanguageSettings(themeService),
          ],
        ),
      ),
    );
  }

  // Bölüm başlığı
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  // Tema ayarları bölümü
  Widget _buildThemeSettings(ThemeService themeService) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tema Modu',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Karanlık Tema'),
                Switch(
                  value: themeService.isDarkMode,
                  onChanged: (value) {
                    themeService.setThemeMode(value);
                  },
                  activeColor: AppTheme.primaryColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Font ayarları bölümü
  Widget _buildFontSettings(ThemeService themeService) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Font Boyutu
            const Text(
              'Font Boyutu',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<double>(
              value: themeService.fontSize,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              items: _fontSizeOptions.map((option) {
                return DropdownMenuItem<double>(
                  value: option['value'],
                  child: Text(option['label']),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  themeService.setFontSize(value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Font Ailesi
            const Text(
              'Font Ailesi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: themeService.fontFamily,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              items: _fontFamilyOptions.map((option) {
                return DropdownMenuItem<String>(
                  value: option['value'],
                  child: Text(option['label']),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  themeService.setFontFamily(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // Dil ayarları bölümü
  Widget _buildLanguageSettings(ThemeService themeService) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Uygulama Dili',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: themeService.language,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              items: _languageOptions.map((option) {
                return DropdownMenuItem<String>(
                  value: option['value'],
                  child: Text(option['label']),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  themeService.setLanguage(value);
                }
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'Not: Dil değişikliği uygulamayı yeniden başlattığınızda tam olarak uygulanacaktır.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.secondaryTextColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
