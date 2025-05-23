import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../constants/app_theme.dart';
import '../../models/user_model.dart';
import '../../models/appointment_model.dart';
import '../../services/api_service.dart';
import '../../routes/app_routes.dart';

class DoctorStatisticsScreen extends StatefulWidget {
  const DoctorStatisticsScreen({super.key});

  @override
  DoctorStatisticsScreenState createState() => DoctorStatisticsScreenState();
}

class DoctorStatisticsScreenState extends State<DoctorStatisticsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _errorMessage = '';
  User? _currentDoctor;
  List<User> _patients = [];
  final Map<int, List<dynamic>> _patientRecords = {};
  final Map<int, Map<String, dynamic>> _patientSummaries = {};
  final Map<int, Map<String, dynamic>> _patientTrends = {};
  List<Appointment> _appointments = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Mevcut doktor bilgilerini al
      final currentUser = await _apiService.getCurrentUser();
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Kullanıcı bilgileri alınamadı. Lütfen tekrar giriş yapın.';
        });
        return;
      }

      // Kullanıcı rolünü kontrol et
      final userRole = currentUser.role.toLowerCase();
      final isDoctorUser = userRole == 'doctor';

      if (!isDoctorUser) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Bu sayfaya erişim yetkiniz yok.';
        });
        return;
      }

      _currentDoctor = currentUser;

      // Doktorun hastalarının diş sağlığı verilerini al
      final doctorId = _currentDoctor!.id;

      // Tüm randevuları al
      final allAppointments = await _apiService.getAllAppointments();

      // Doktorun randevularını filtrele
      _appointments = allAppointments.where((appointment) {
        return appointment.doctorId == doctorId ||
            appointment.doctorName.toLowerCase() ==
                _currentDoctor!.fullName.toLowerCase();
      }).toList();

      // Benzersiz hasta ID'lerini al
      final patientIds = _appointments
          .map((appointment) => appointment.patientId)
          .where((id) => id != null)
          .toSet()
          .cast<int>();

      // Tüm hastaları al
      final allUsers = await _apiService.getAllUsers();

      // Doktorun hastalarını filtrele
      _patients =
          allUsers.where((user) => patientIds.contains(user.id)).toList();

      // Doktorun tüm hastaları için diş sağlığı verilerini al
      try {
        // Doktor ID'si ile tüm hastaların diş sağlığı verilerini al
        final doctorId = _currentDoctor!.id;

        // Diş sağlığı kayıtlarını al
        final records = await _apiService.getDentalRecords(doctorId);
        if (records.isNotEmpty) {
          records.forEach((patientId, recordsList) {
            _patientRecords[patientId] = recordsList;
          });
        }

        // Diş sağlığı özetlerini al
        final summaries = await _apiService.getDentalSummaries(doctorId);
        if (summaries.isNotEmpty) {
          summaries.forEach((patientId, summary) {
            _patientSummaries[patientId] = summary;
          });
        }

        // Trend verilerini al (son 30 gün)
        final trends = await _apiService.getDentalTrends(doctorId, 30);
        if (trends.isNotEmpty) {
          trends.forEach((patientId, trend) {
            _patientTrends[patientId] = trend;
          });
        }
      } catch (e) {
        // Hata durumunda sessizce devam et
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Veri yüklenirken bir hata oluştu: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('Dr. ${_currentDoctor?.fullName ?? 'Doktor'} - İstatistikler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
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
              : _buildStatisticsContent(),
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
            selected: true,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Ayarlar'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.doctorSettings);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsContent() {
    if (_patients.isEmpty) {
      return const Center(
        child: Text(
          'Henüz hasta kaydınız bulunmamaktadır.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hasta İstatistikleri',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
          ),
          const SizedBox(height: 16),

          // Hasta listesi
          ..._patients.map((patient) => _buildPatientStatisticsCard(patient)),
        ],
      ),
    );
  }

  Widget _buildPatientStatisticsCard(User patient) {
    final patientSummary = _patientSummaries[patient.id];
    final patientTrends = _patientTrends[patient.id];

    // Hastanın randevularını bul
    final patientAppointments = _appointments
        .where((appointment) => appointment.patientId == patient.id)
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    patient.fullName.isNotEmpty
                        ? patient.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        patient.email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.medical_services),
                  label: const Text('Tedavi Başlat'),
                  onPressed: () => _showStartTreatmentDialog(patient),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Diş sağlığı özeti
            if (patientSummary != null) _buildPatientSummary(patientSummary),

            const SizedBox(height: 16),

            // Randevu geçmişi
            _buildAppointmentHistory(patientAppointments),

            const SizedBox(height: 16),

            // Trend analizi
            if (patientTrends != null) _buildTrendAnalysis(patientTrends),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientSummary(Map<String, dynamic> summary) {
    final brushingPercentage = summary['brushingPercentage'] ?? 0.0;
    final flossPercentage = summary['flossPercentage'] ?? 0.0;
    final mouthwashPercentage = summary['mouthwashPercentage'] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Diş Sağlığı Özeti (Son 7 Gün)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildProgressIndicator(
                'Diş Fırçalama',
                brushingPercentage,
                Colors.blue,
              ),
            ),
            Expanded(
              child: _buildProgressIndicator(
                'Diş İpi',
                flossPercentage,
                Colors.green,
              ),
            ),
            Expanded(
              child: _buildProgressIndicator(
                'Gargara',
                mouthwashPercentage,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(String title, double percentage, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 80,
              width: 80,
              child: CircularProgressIndicator(
                value: percentage,
                backgroundColor: Colors.grey.shade200,
                color: color,
                strokeWidth: 8,
              ),
            ),
            Text(
              '${(percentage * 100).toInt()}%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAppointmentHistory(List<Appointment> appointments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Randevu Geçmişi',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (appointments.isEmpty)
          const Text(
            'Henüz randevu kaydı bulunmamaktadır.',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          )
        else
          Column(
            children: appointments
                .map((appointment) => _buildAppointmentItem(appointment))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildAppointmentItem(Appointment appointment) {
    Color statusColor;
    IconData statusIcon;

    switch (appointment.status.toLowerCase()) {
      case 'tamamlandı':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'iptal edildi':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'onaylandı':
        statusColor = Colors.blue;
        statusIcon = Icons.thumb_up;
        break;
      case 'tedavi başlatıldı':
        statusColor = Colors.orange;
        statusIcon = Icons.medical_services;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.pending;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${appointment.date.day}/${appointment.date.month}/${appointment.date.year} - ${appointment.time}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              appointment.status,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendAnalysis(Map<String, dynamic> trends) {
    final overallTrend = trends['overallTrendPercentage'] ?? 0.0;
    final brushingTrend = trends['brushingTrendPercentage'] ?? 0.0;
    final flossTrend = trends['flossTrendPercentage'] ?? 0.0;
    final mouthwashTrend = trends['mouthwashTrendPercentage'] ?? 0.0;

    // Trend yönünü belirle
    final isPositiveTrend = overallTrend >= 0;
    final trendIcon = isPositiveTrend ? Icons.trending_up : Icons.trending_down;
    final trendColor = isPositiveTrend ? Colors.green : Colors.red;
    final trendText = isPositiveTrend ? 'İyileşme' : 'Kötüleşme';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trend Analizi (Son 30 Gün)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(trendIcon, color: trendColor, size: 24),
            const SizedBox(width: 8),
            Text(
              'Genel Trend: $trendText (${(overallTrend * 100).abs().toStringAsFixed(1)}%)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: trendColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTrendItem('Diş Fırçalama', brushingTrend, Colors.blue),
        const SizedBox(height: 8),
        _buildTrendItem('Diş İpi', flossTrend, Colors.green),
        const SizedBox(height: 8),
        _buildTrendItem('Gargara', mouthwashTrend, Colors.purple),
      ],
    );
  }

  Widget _buildTrendItem(String title, double trendValue, Color color) {
    final isPositive = trendValue >= 0;
    final trendIcon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;
    final trendColor = isPositive ? Colors.green : Colors.red;

    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Icon(trendIcon, color: trendColor, size: 16),
        const SizedBox(width: 4),
        Text(
          '${(trendValue * 100).abs().toStringAsFixed(1)}%',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: trendColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: LinearProgressIndicator(
            value: 0.5 + (trendValue / 2), // 0-1 aralığına dönüştür
            backgroundColor: Colors.grey.shade200,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showStartTreatmentDialog(User patient) {
    final treatmentTypeController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${patient.fullName} için Tedavi Başlat'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: treatmentTypeController,
                decoration: const InputDecoration(
                  labelText: 'Tedavi Türü',
                  hintText: 'Örn: Diş Kontrolü, Dolgu, Kanal Tedavisi',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notlar',
                  hintText: 'Tedavi ile ilgili notlar',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Tedavi başlat
              final treatmentType = treatmentTypeController.text.isNotEmpty
                  ? treatmentTypeController.text
                  : 'Genel Kontrol';

              final notes = notesController.text;

              setState(() {
                _isLoading = true;
              });

              try {
                final result = await _apiService.startTreatment(
                  patient.id,
                  _currentDoctor!.id,
                  treatmentType,
                  notes,
                );

                setState(() {
                  _isLoading = false;
                });

                if (result['success']) {
                  // Verileri yenile
                  await _loadData();

                  if (!mounted) return;

                  // Başarılı mesaj göster
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Tedavi başarıyla başlatıldı'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  if (!mounted) return;

                  // Hata mesajı göster
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Hata: ${result['message']}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                setState(() {
                  _isLoading = false;
                });

                if (!mounted) return;

                // Hata mesajı göster
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Hata: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Tedavi Başlat'),
          ),
        ],
      ),
    );
  }
}
