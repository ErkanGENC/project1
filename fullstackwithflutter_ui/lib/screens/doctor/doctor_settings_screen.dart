import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../services/theme_service.dart';
import '../../services/api_service.dart';
import '../../routes/app_routes.dart';

class DoctorSettingsScreen extends StatefulWidget {
  const DoctorSettingsScreen({super.key});

  @override
  DoctorSettingsScreenState createState() => DoctorSettingsScreenState();
}

class DoctorSettingsScreenState extends State<DoctorSettingsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String _errorMessage = '';

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
      drawer: _buildDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : SingleChildScrollView(
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
                      const Divider(height: 32),

                      // Doktor Paneli Ayarları
                      _buildSectionTitle('Doktor Paneli Ayarları'),
                      _buildDoctorPanelSettings(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Doktor Paneli',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Ayarlar',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(
                  context, AppRoutes.doctorDashboard);
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Randevularım'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.doctorAppointments);
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Hastalarım'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.doctorPatients);
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('İstatistikler'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.doctorStatistics);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Ayarlar'),
            selected: true,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
            onTap: () async {
              // Çıkış işlemi
              await _apiService.logout();
              if (!mounted) return;
              Navigator.of(context).pushReplacementNamed(AppRoutes.login);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
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
          ],
        ),
      ),
    );
  }

  // Doktor paneli ayarları bölümü
  Widget _buildDoctorPanelSettings() {
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
              'Bildirim Ayarları',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Yeni Randevu Bildirimleri'),
              subtitle: const Text('Yeni randevu oluşturulduğunda bildirim al'),
              value: true, // Bu değer veritabanından alınabilir
              onChanged: (value) {
                // Bildirim ayarlarını güncelle
              },
            ),
            SwitchListTile(
              title: const Text('Randevu Değişiklik Bildirimleri'),
              subtitle: const Text('Randevu durumu değiştiğinde bildirim al'),
              value: true, // Bu değer veritabanından alınabilir
              onChanged: (value) {
                // Bildirim ayarlarını güncelle
              },
            ),
          ],
        ),
      ),
    );
  }
}
