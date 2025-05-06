import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_theme.dart';

/// Bildirim ayarları ekranı
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  _NotificationSettingsScreenState createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _isLoading = true;
  
  // Bildirim ayarları
  bool _appointmentReminders = true;
  bool _treatmentReminders = true;
  bool _dentalTipsNotifications = true;
  bool _promotionalNotifications = false;
  
  // Bildirim zamanlaması
  String _reminderTime = '09:00';
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _appointmentReminders = prefs.getBool('appointment_reminders') ?? true;
        _treatmentReminders = prefs.getBool('treatment_reminders') ?? true;
        _dentalTipsNotifications = prefs.getBool('dental_tips_notifications') ?? true;
        _promotionalNotifications = prefs.getBool('promotional_notifications') ?? false;
        _reminderTime = prefs.getString('reminder_time') ?? '09:00';
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
  
  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('appointment_reminders', _appointmentReminders);
      await prefs.setBool('treatment_reminders', _treatmentReminders);
      await prefs.setBool('dental_tips_notifications', _dentalTipsNotifications);
      await prefs.setBool('promotional_notifications', _promotionalNotifications);
      await prefs.setString('reminder_time', _reminderTime);
      
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
  
  Future<void> _selectReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(_reminderTime.split(':')[0]),
        minute: int.parse(_reminderTime.split(':')[1]),
      ),
    );
    
    if (picked != null) {
      setState(() {
        _reminderTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirim Ayarları'),
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
                  // Bildirim türleri
                  const Text(
                    'Bildirim Türleri',
                    style: AppTheme.subheadingStyle,
                  ),
                  const SizedBox(height: 8),
                  
                  // Randevu hatırlatıcıları
                  SwitchListTile(
                    title: const Text('Randevu Hatırlatıcıları'),
                    subtitle: const Text('Yaklaşan randevularınız için bildirimler alın'),
                    value: _appointmentReminders,
                    onChanged: (value) {
                      setState(() {
                        _appointmentReminders = value;
                      });
                    },
                    secondary: const Icon(Icons.calendar_today),
                  ),
                  
                  // Tedavi hatırlatıcıları
                  SwitchListTile(
                    title: const Text('Tedavi Hatırlatıcıları'),
                    subtitle: const Text('Devam eden tedavileriniz için bildirimler alın'),
                    value: _treatmentReminders,
                    onChanged: (value) {
                      setState(() {
                        _treatmentReminders = value;
                      });
                    },
                    secondary: const Icon(Icons.medical_services_outlined),
                  ),
                  
                  // Diş sağlığı ipuçları
                  SwitchListTile(
                    title: const Text('Diş Sağlığı İpuçları'),
                    subtitle: const Text('Diş sağlığınızı korumak için faydalı bilgiler alın'),
                    value: _dentalTipsNotifications,
                    onChanged: (value) {
                      setState(() {
                        _dentalTipsNotifications = value;
                      });
                    },
                    secondary: const Icon(Icons.lightbulb_outline),
                  ),
                  
                  // Promosyon bildirimleri
                  SwitchListTile(
                    title: const Text('Promosyon Bildirimleri'),
                    subtitle: const Text('Kampanya ve indirimlerden haberdar olun'),
                    value: _promotionalNotifications,
                    onChanged: (value) {
                      setState(() {
                        _promotionalNotifications = value;
                      });
                    },
                    secondary: const Icon(Icons.local_offer_outlined),
                  ),
                  
                  const Divider(),
                  
                  // Bildirim zamanlaması
                  const Text(
                    'Bildirim Zamanlaması',
                    style: AppTheme.subheadingStyle,
                  ),
                  const SizedBox(height: 8),
                  
                  // Hatırlatıcı zamanı
                  ListTile(
                    title: const Text('Günlük Hatırlatıcı Zamanı'),
                    subtitle: Text('Günlük hatırlatıcılar $_reminderTime saatinde gönderilecek'),
                    leading: const Icon(Icons.access_time),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _selectReminderTime,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Kaydet butonu
                  Center(
                    child: ElevatedButton(
                      onPressed: _saveSettings,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        backgroundColor: AppTheme.primaryColor,
                      ),
                      child: const Text(
                        'Ayarları Kaydet',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
