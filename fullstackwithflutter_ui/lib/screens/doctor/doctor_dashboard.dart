import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../models/appointment_model.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../widgets/admin/stats_card.dart';
import '../../routes/app_routes.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  DoctorDashboardState createState() => DoctorDashboardState();
}

class DoctorDashboardState extends State<DoctorDashboard> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic> _dashboardData = {};
  User? _currentDoctor;
  List<Appointment> _doctorAppointments = [];

  @override
  void initState() {
    super.initState();
    _loadDoctorData();
  }

  Future<void> _loadDoctorData() async {
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
      final appointments = await _apiService.getAllAppointments();

      // Doktorun randevularını filtrele
      _doctorAppointments = appointments.where((appointment) {
        // Doktor adı ile eşleşen randevuları bul
        if (appointment.doctorName.toLowerCase() ==
            _currentDoctor!.fullName.toLowerCase()) {
          return true;
        }

        // Doktor ID'si ile eşleşen randevuları bul
        if (appointment.doctorId != null &&
            appointment.doctorId == _currentDoctor!.id) {
          return true;
        }

        // DoctorId alanı ile eşleşen randevuları bul
        if (_currentDoctor!.doctorId != null &&
            _currentDoctor!.doctorId! > 0 &&
            appointment.doctorId != null &&
            appointment.doctorId == _currentDoctor!.doctorId) {
          return true;
        }

        return false;
      }).toList();

      // Debug bilgileri
      // Doktor: ${_currentDoctor!.fullName}, ID: ${_currentDoctor!.id}
      // Toplam randevu sayısı: ${appointments.length}
      // Doktora ait randevu sayısı: ${_doctorAppointments.length}

      // Dashboard verilerini hazırla
      final todayAppointments = _getTodayAppointments(_doctorAppointments);
      final pendingAppointments = _getPendingAppointments(_doctorAppointments);
      final completedAppointments = _doctorAppointments
          .where((a) => a.status.toLowerCase() == 'tamamlandı')
          .length;

      // Hasta sayısını hesapla (benzersiz hasta e-postaları)
      final uniquePatientEmails = _doctorAppointments
          .map((appointment) => appointment.patientEmail)
          .toSet();
      final patientCount = uniquePatientEmails.length;

      // Son 7 gündeki randevuları hesapla
      final now = DateTime.now();
      final lastWeek = now.subtract(const Duration(days: 7));
      final lastWeekAppointments = _doctorAppointments
          .where((appointment) => appointment.date.isAfter(lastWeek))
          .length;

      // Artış oranlarını hesapla
      String calculateIncrease(int current, int previous) {
        if (previous == 0) return '+0%';
        final increase = ((current - previous) / previous * 100).toInt();
        return increase >= 0 ? '+$increase%' : '$increase%';
      }

      // Önceki hafta ile karşılaştırma için varsayılan değerler
      // Gerçek uygulamada bu veriler veritabanından alınabilir
      final previousWeekAppointments =
          lastWeekAppointments > 0 ? (lastWeekAppointments * 0.8).toInt() : 0;
      final previousPatientCount =
          patientCount > 0 ? (patientCount * 0.9).toInt() : 0;

      setState(() {
        _dashboardData = {
          'totalAppointments': _doctorAppointments.length,
          'todayAppointments': todayAppointments.length,
          'pendingAppointments': pendingAppointments.length,
          'completedAppointments': completedAppointments,
          'patientCount': patientCount,
          'totalAppointmentsIncrease': calculateIncrease(
              _doctorAppointments.length, previousWeekAppointments),
          'patientCountIncrease':
              calculateIncrease(patientCount, previousPatientCount),
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Veri yüklenirken bir hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  // Bugünkü randevuları getir
  List<Appointment> _getTodayAppointments(List<Appointment> appointments) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return appointments.where((appointment) {
      final appointmentDate = DateTime(
          appointment.date.year, appointment.date.month, appointment.date.day);
      return appointmentDate.isAtSameMomentAs(today);
    }).toList();
  }

  // Bekleyen randevuları getir
  List<Appointment> _getPendingAppointments(List<Appointment> appointments) {
    return appointments
        .where((appointment) => appointment.status.toLowerCase() == 'bekleyen')
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dr. ${_currentDoctor?.fullName ?? 'Doktor'} Paneli'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.pushReplacementNamed(context, AppRoutes.home);
            },
            tooltip: 'Kullanıcı Paneli',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDoctorData,
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
              : _buildDashboardContent(),
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
            selected: true,
            onTap: () {
              Navigator.pop(context);
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

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hoş Geldiniz, Dr. ${_currentDoctor?.fullName ?? 'Doktor'}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
          ),
          Text(
            'Randevularınıza genel bir bakış',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.secondaryTextColor,
                ),
          ),
          const SizedBox(height: 24),

          // İstatistik Kartları
          Row(
            children: [
              Expanded(
                child: StatsCard(
                  title: 'Toplam Randevu',
                  value: _dashboardData['totalAppointments']?.toString() ?? '0',
                  icon: Icons.calendar_month,
                  color: AppTheme.primaryColor,
                  increase:
                      _dashboardData['totalAppointmentsIncrease']?.toString() ??
                          '+0%',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatsCard(
                  title: 'Bugünkü Randevular',
                  value: _dashboardData['todayAppointments']?.toString() ?? '0',
                  icon: Icons.today,
                  color: AppTheme.accentColor,
                  increase: '+0%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatsCard(
                  title: 'Bekleyen Randevular',
                  value:
                      _dashboardData['pendingAppointments']?.toString() ?? '0',
                  icon: Icons.pending_actions,
                  color: AppTheme.warningColor,
                  increase: '+0%',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatsCard(
                  title: 'Tamamlanan Randevular',
                  value: _dashboardData['completedAppointments']?.toString() ??
                      '0',
                  icon: Icons.check_circle,
                  color: AppTheme.successColor,
                  increase: '+0%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatsCard(
                  title: 'Toplam Hasta',
                  value: _dashboardData['patientCount']?.toString() ?? '0',
                  icon: Icons.people,
                  color: Colors.purple,
                  increase:
                      _dashboardData['patientCountIncrease']?.toString() ??
                          '+0%',
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
          Text(
            'Bugünkü Randevular',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
          ),
          const SizedBox(height: 16),

          // Bugünkü randevular listesi
          _buildTodayAppointmentsList(),

          const SizedBox(height: 32),
          Text(
            'Son Aktiviteler',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
          ),
          const SizedBox(height: 16),

          // Son aktiviteler listesi
          _buildRecentActivitiesList(),
        ],
      ),
    );
  }

  Widget _buildTodayAppointmentsList() {
    final todayAppointments = _getTodayAppointments(_doctorAppointments);

    if (todayAppointments.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'Bugün için randevunuz bulunmamaktadır',
              style: TextStyle(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: todayAppointments
          .map((appointment) => _buildAppointmentCard(appointment))
          .toList(),
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
                    children: [
                      Icon(
                        statusIcon,
                        color: statusColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        appointment.status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
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
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  appointment.time,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.medical_services,
                    size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  appointment.type,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (appointment.status.toLowerCase() == 'bekleyen')
                  TextButton.icon(
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Onayla'),
                    onPressed: () =>
                        _updateAppointmentStatus(appointment, 'Onaylandı'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.successColor,
                    ),
                  ),
                const SizedBox(width: 8),
                if (appointment.status.toLowerCase() == 'bekleyen' ||
                    appointment.status.toLowerCase() == 'onaylandı')
                  TextButton.icon(
                    icon: const Icon(Icons.cancel, size: 16),
                    label: const Text('İptal Et'),
                    onPressed: () =>
                        _updateAppointmentStatus(appointment, 'İptal Edildi'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                const SizedBox(width: 8),
                if (appointment.status.toLowerCase() == 'onaylandı')
                  TextButton.icon(
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: const Text('Tamamlandı'),
                    onPressed: () =>
                        _updateAppointmentStatus(appointment, 'Tamamlandı'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.successColor,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitiesList() {
    // Son 5 randevuyu göster (en yeniden en eskiye)
    final recentAppointments = List<Appointment>.from(_doctorAppointments)
      ..sort((a, b) =>
          b.date.compareTo(a.date)); // Tarihe göre sırala (en yeni en üstte)

    final activities = recentAppointments.take(5).toList();

    if (activities.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'Henüz aktivite bulunmamaktadır',
              style: TextStyle(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: activities.map((activity) {
        // Aktivite tipi ve rengi
        IconData activityIcon;
        Color activityColor;
        String activityText;

        // Randevu durumuna göre aktivite bilgilerini belirle
        switch (activity.status.toLowerCase()) {
          case 'bekleyen':
            activityIcon = Icons.pending_actions;
            activityColor = AppTheme.warningColor;
            activityText =
                '${activity.patientName} için yeni randevu oluşturuldu';
            break;
          case 'onaylandı':
            activityIcon = Icons.check_circle;
            activityColor = Colors.green;
            activityText = '${activity.patientName} için randevu onaylandı';
            break;
          case 'iptal edildi':
            activityIcon = Icons.cancel;
            activityColor = Colors.red;
            activityText = '${activity.patientName} için randevu iptal edildi';
            break;
          case 'tamamlandı':
            activityIcon = Icons.done_all;
            activityColor = AppTheme.successColor;
            activityText = '${activity.patientName} için randevu tamamlandı';
            break;
          default:
            activityIcon = Icons.event_note;
            activityColor = Colors.blue;
            activityText = '${activity.patientName} için randevu güncellendi';
        }

        // Tarih formatı
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final activityDate = DateTime(
            activity.date.year, activity.date.month, activity.date.day);

        String dateText;
        if (activityDate.isAtSameMomentAs(today)) {
          dateText = 'Bugün, ${activity.time}';
        } else if (activityDate
            .isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
          dateText = 'Dün, ${activity.time}';
        } else {
          dateText =
              '${activity.date.day}/${activity.date.month}/${activity.date.year}, ${activity.time}';
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Color.fromRGBO(activityColor.red & 0xFF,
                  activityColor.green & 0xFF, activityColor.blue & 0xFF, 0.2),
              child: Icon(activityIcon, color: activityColor, size: 20),
            ),
            title: Text(activityText),
            subtitle: Text(dateText),
            trailing: Text(
              activity.type,
              style: TextStyle(
                color: activityColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _updateAppointmentStatus(
      Appointment appointment, String newStatus) async {
    try {
      // Yükleniyor göstergesi
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Randevu güncelleme işlemi
      final result =
          await _apiService.updateAppointmentStatus(appointment.id, newStatus);

      // Yükleniyor göstergesini kapat
      if (mounted) Navigator.pop(context);

      if (!mounted) return;

      if (result['success']) {
        // Başarılı mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Randevu durumu güncellendi: $newStatus'),
            backgroundColor: Colors.green,
          ),
        );

        // Verileri yeniden yükle
        _loadDoctorData();
      } else {
        // Hata mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Yükleniyor göstergesini kapat
      if (mounted) Navigator.pop(context);

      if (!mounted) return;

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
