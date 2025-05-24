import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_theme.dart';
import '../../services/theme_service.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _isLoading = false;
  
  
  bool _newAppointmentNotifications = true;
  bool _appointmentChangeNotifications = true;
  bool _newUserNotifications = true;
  bool _systemNotifications = true;
  
  
  final List<Map<String, dynamic>> _fontSizeOptions = [
    {'label': 'Küçük', 'value': 0.8},
    {'label': 'Normal', 'value': 1.0},
    {'label': 'Büyük', 'value': 1.2},
    {'label': 'Çok Büyük', 'value': 1.4},
  ];

  
  final List<Map<String, dynamic>> _fontFamilyOptions = [
    {'label': 'Varsayılan', 'value': 'Default'},
    {'label': 'Roboto', 'value': 'Roboto'},
    {'label': 'Open Sans', 'value': 'OpenSans'},
    {'label': 'Montserrat', 'value': 'Montserrat'},
  ];

  
  final List<Map<String, dynamic>> _languageOptions = [
    {'label': 'Türkçe', 'value': 'tr'},
    {'label': 'English', 'value': 'en'},
  ];

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }
  
  
  Future<void> _loadNotificationSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _newAppointmentNotifications = prefs.getBool('admin_new_appointment_notifications') ?? true;
        _appointmentChangeNotifications = prefs.getBool('admin_appointment_change_notifications') ?? true;
        _newUserNotifications = prefs.getBool('admin_new_user_notifications') ?? true;
        _systemNotifications = prefs.getBool('admin_system_notifications') ?? true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ayarlar yüklenirken bir hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  
  Future<void> _saveNotificationSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('admin_new_appointment_notifications', _newAppointmentNotifications);
      await prefs.setBool('admin_appointment_change_notifications', _appointmentChangeNotifications);
      await prefs.setBool('admin_new_user_notifications', _newUserNotifications);
      await prefs.setBool('admin_system_notifications', _systemNotifications);
      
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bildirim ayarları kaydedildi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ayarlar kaydedilirken bir hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Ayarları'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  _buildSectionTitle('Tema Ayarları'),
                  _buildThemeSettings(themeService),
                  const Divider(height: 32),

                  
                  _buildSectionTitle('Font Ayarları'),
                  _buildFontSettings(themeService),
                  const Divider(height: 32),

                  
                  _buildSectionTitle('Dil Ayarları'),
                  _buildLanguageSettings(themeService),
                  const Divider(height: 32),
                  
                  
                  _buildSectionTitle('Bildirim Ayarları'),
                  _buildNotificationSettings(),
                  const Divider(height: 32),
                  
                  
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _saveNotificationSettings,
                      icon: const Icon(Icons.save),
                      label: const Text('Bildirim Ayarlarını Kaydet'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
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
  
  
  Widget _buildNotificationSettings() {
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
              'Bildirim Tercihleri',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            
            
            SwitchListTile(
              title: const Text('Yeni Randevu Bildirimleri'),
              subtitle: const Text('Yeni bir randevu oluşturulduğunda bildirim al'),
              value: _newAppointmentNotifications,
              onChanged: (value) {
                setState(() {
                  _newAppointmentNotifications = value;
                });
              },
              secondary: const Icon(Icons.calendar_today),
            ),
            
            
            SwitchListTile(
              title: const Text('Randevu Değişiklik Bildirimleri'),
              subtitle: const Text('Randevu durumu değiştiğinde bildirim al'),
              value: _appointmentChangeNotifications,
              onChanged: (value) {
                setState(() {
                  _appointmentChangeNotifications = value;
                });
              },
              secondary: const Icon(Icons.update),
            ),
            
            
            SwitchListTile(
              title: const Text('Yeni Kullanıcı Bildirimleri'),
              subtitle: const Text('Yeni bir kullanıcı kaydolduğunda bildirim al'),
              value: _newUserNotifications,
              onChanged: (value) {
                setState(() {
                  _newUserNotifications = value;
                });
              },
              secondary: const Icon(Icons.person_add),
            ),
            
            
            SwitchListTile(
              title: const Text('Sistem Bildirimleri'),
              subtitle: const Text('Sistem güncellemeleri ve önemli bilgiler için bildirim al'),
              value: _systemNotifications,
              onChanged: (value) {
                setState(() {
                  _systemNotifications = value;
                });
              },
              secondary: const Icon(Icons.system_update),
            ),
          ],
        ),
      ),
    );
  }
}
