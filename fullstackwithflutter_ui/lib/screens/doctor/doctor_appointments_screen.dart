import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../models/appointment_model.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../routes/app_routes.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  DoctorAppointmentsScreenState createState() =>
      DoctorAppointmentsScreenState();
}

class DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _errorMessage = '';
  List<Appointment> _appointments = [];
  String _filterStatus = 'Tümü';
  User? _currentDoctor;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Mevcut kullanıcıyı al
      final currentUser = await _apiService.getCurrentUser();

      if (currentUser == null) {
        // Kullanıcı oturum açmamış, giriş sayfasına yönlendir
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/login');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lütfen önce giriş yapın'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Kullanıcı rolünü kontrol et
      final userRole = currentUser.role.toLowerCase();

      if (userRole != 'doctor') {
        // Doktor değilse, uygun sayfaya yönlendir
        if (!mounted) return;

        String redirectRoute = '/';
        String message = 'Doktor paneline erişim yetkiniz yok';

        // Admin kullanıcısı ise admin paneline yönlendir
        if (userRole == 'admin') {
          redirectRoute = '/admin/dashboard';
          message = 'Admin paneline yönlendiriliyorsunuz';
        }

        Navigator.of(context).pushReplacementNamed(redirectRoute);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      _currentDoctor = currentUser;

      // Tüm randevuları al
      final allAppointments = await _apiService.getAllAppointments();

      // Doktorun randevularını filtrele
      _appointments = allAppointments.where((appointment) {
        // Doktor adı ile eşleşen randevuları bul
        if (_currentDoctor?.fullName != null &&
            appointment.doctorName.toLowerCase() ==
                _currentDoctor!.fullName.toLowerCase()) {
          return true;
        }

        // Doktor ID'si ile eşleşen randevuları bul
        if (_currentDoctor?.id != null &&
            appointment.doctorId != null &&
            appointment.doctorId == _currentDoctor!.id) {
          return true;
        }

        // DoctorId alanı ile eşleşen randevuları bul
        if (_currentDoctor?.doctorId != null &&
            _currentDoctor!.doctorId! > 0 &&
            appointment.doctorId != null &&
            appointment.doctorId == _currentDoctor!.doctorId) {
          return true;
        }

        return false;
      }).toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Veri yüklenirken bir hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  List<Appointment> _getFilteredAppointments() {
    if (_filterStatus == 'Tümü') {
      return _appointments;
    } else {
      return _appointments
          .where((appointment) =>
              appointment.status.toLowerCase() == _filterStatus.toLowerCase())
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('Dr. ${_currentDoctor?.fullName ?? 'Doktor'} - Randevularım'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAppointments,
          ),
        ],
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
              : Column(
                  children: [
                    // Filtre seçenekleri
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Text('Durum: ',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: _filterStatus,
                            items: const [
                              DropdownMenuItem(
                                  value: 'Tümü', child: Text('Tümü')),
                              DropdownMenuItem(
                                  value: 'Bekleyen', child: Text('Bekleyen')),
                              DropdownMenuItem(
                                  value: 'Onaylandı', child: Text('Onaylandı')),
                              DropdownMenuItem(
                                  value: 'Tamamlandı',
                                  child: Text('Tamamlandı')),
                              DropdownMenuItem(
                                  value: 'İptal Edildi',
                                  child: Text('İptal Edildi')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _filterStatus = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    // Randevu listesi
                    Expanded(
                      child: _getFilteredAppointments().isEmpty
                          ? const Center(
                              child: Text(
                                'Randevu bulunamadı',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _getFilteredAppointments().length,
                              itemBuilder: (context, index) {
                                final appointment =
                                    _getFilteredAppointments()[index];
                                return _buildAppointmentCard(appointment);
                              },
                            ),
                    ),
                  ],
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
                Text(
                  'Dr. ${_currentDoctor?.fullName ?? 'Doktor'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _currentDoctor?.specialization ?? 'Uzman',
                  style: const TextStyle(
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
            selected: true,
            onTap: () {
              Navigator.pop(context);
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
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Ayarlar'),
            onTap: () {
              Navigator.pop(context);
              // Ayarlar sayfasına git
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

  Widget _buildAppointmentCard(Appointment appointment) {
    Color statusColor;
    IconData statusIcon;

    switch (appointment.status.toLowerCase()) {
      case 'tamamlandı':
        statusColor = AppTheme.successColor;
        statusIcon = Icons.check_circle;
        break;
      case 'iptal edildi':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'bekleyen':
        statusColor = AppTheme.warningColor;
        statusIcon = Icons.pending_actions;
        break;
      case 'onaylandı':
        statusColor = Colors.blue;
        statusIcon = Icons.check;
        break;
      default:
        statusColor = Colors.blue;
        statusIcon = Icons.info;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  appointment.patientName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        appointment.status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.medical_services,
                    color: AppTheme.secondaryTextColor, size: 16),
                const SizedBox(width: 4),
                Text(appointment.type),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    color: AppTheme.secondaryTextColor, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${appointment.date.day}/${appointment.date.month}/${appointment.date.year} - ${appointment.time}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    // Randevu durumunu güncelle
                    _showChangeStatusDialog(appointment);
                  },
                  child: const Text('Durum Değiştir'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeStatusDialog(Appointment appointment) {
    String newStatus = appointment.status;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Randevu Durumunu Değiştir'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text('Bekleyen'),
                  value: 'Bekleyen',
                  groupValue: newStatus,
                  onChanged: (value) {
                    setState(() {
                      newStatus = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Onaylandı'),
                  value: 'Onaylandı',
                  groupValue: newStatus,
                  onChanged: (value) {
                    setState(() {
                      newStatus = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Tamamlandı'),
                  value: 'Tamamlandı',
                  groupValue: newStatus,
                  onChanged: (value) {
                    setState(() {
                      newStatus = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('İptal Edildi'),
                  value: 'İptal Edildi',
                  groupValue: newStatus,
                  onChanged: (value) {
                    setState(() {
                      newStatus = value!;
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              // Yükleme göstergesi
              _updateStatus(appointment, newStatus);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  // Randevu durumunu güncelleme metodu
  Future<void> _updateStatus(Appointment appointment, String newStatus) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // API çağrısı yap
      final result =
          await _apiService.updateAppointmentStatus(appointment.id, newStatus);

      if (!mounted) return;

      // Sonucu işle
      if (result['success']) {
        // Verileri yenile
        await _loadAppointments();

        if (!mounted) return;

        // Başarılı mesaj göster
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Randevu durumu güncellendi'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
        });

        if (!mounted) return;

        // Hata mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Hata mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bir hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
