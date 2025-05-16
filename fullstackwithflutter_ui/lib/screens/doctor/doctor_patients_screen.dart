import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../models/user_model.dart';
import '../../models/appointment_model.dart';
import '../../services/api_service.dart';

class DoctorPatientsScreen extends StatefulWidget {
  const DoctorPatientsScreen({super.key});

  @override
  DoctorPatientsScreenState createState() => DoctorPatientsScreenState();
}

class DoctorPatientsScreenState extends State<DoctorPatientsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _errorMessage = '';
  List<User> _allPatients = [];
  List<User> _filteredPatients = [];
  List<Appointment> _appointments = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterPatients);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Mevcut kullanıcı bilgilerini al
      final userResult = await _apiService.getCurrentUser();
      if (userResult['success'] && userResult['data'] != null) {
        // Doktor ID'sini al
        final doctorId = userResult['data']['doctorId'];
        final doctorName =
            userResult['data']['fullName'] ?? userResult['data']['doctorName'];

        if (doctorId == null || doctorId == 0) {
          setState(() {
            _errorMessage =
                'Doktor bilgileriniz eksik. Lütfen yönetici ile iletişime geçin.';
            _isLoading = false;
          });
          return;
        }

        // Tüm randevuları al
        final allAppointments = await _apiService.getAllAppointments();

        // Doktorun randevularını filtrele
        _appointments = allAppointments
            .where((appointment) =>
                appointment.doctorId == doctorId ||
                appointment.doctorName == doctorName)
            .toList();

        // Tüm hastaları al
        final allUsers = await _apiService.getAllUsers();

        // Sadece hastaları filtrele (doktor ve admin olmayanlar)
        final patients = allUsers
            .where((user) => user.role.toLowerCase() == 'user')
            .toList();

        // Doktorun hastalarını bul (randevusu olan hastalar)
        final patientEmails = _appointments
            .map((appointment) => appointment.patientEmail)
            .toSet();

        // Doktorun hastalarını filtrele
        _allPatients = patients
            .where((patient) => patientEmails.contains(patient.email))
            .toList();

        _filteredPatients = List.from(_allPatients);

        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Kullanıcı bilgileri alınamadı.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Veri yüklenirken bir hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  void _filterPatients() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredPatients = List.from(_allPatients);
      } else {
        _filteredPatients = _allPatients
            .where((patient) =>
                patient.fullName.toLowerCase().contains(query) ||
                patient.email.toLowerCase().contains(query) ||
                patient.phoneNumber.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hastalarım'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
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
                    // Arama alanı
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Hasta ara...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 0),
                        ),
                      ),
                    ),

                    // Hasta sayısı
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Text(
                            'Toplam ${_filteredPatients.length} hasta',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Hasta listesi
                    Expanded(
                      child: _filteredPatients.isEmpty
                          ? const Center(
                              child: Text(
                                'Hasta bulunamadı',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredPatients.length,
                              itemBuilder: (context, index) {
                                final patient = _filteredPatients[index];
                                return _buildPatientCard(patient);
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildPatientCard(User patient) {
    // Hastanın randevularını bul
    final patientAppointments = _appointments
        .where((appointment) => appointment.patientEmail == patient.email)
        .toList();

    // Son randevu
    final lastAppointment = patientAppointments.isNotEmpty
        ? patientAppointments.reduce((a, b) => a.date.isAfter(b.date) ? a : b)
        : null;

    // Tamamlanan randevu sayısı
    final completedAppointments = patientAppointments
        .where(
            (appointment) => appointment.status.toLowerCase() == 'tamamlandı')
        .length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withAlpha(25),
                  child: Text(
                    patient.fullName.isNotEmpty
                        ? patient.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
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
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        patient.email,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.phone, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  patient.phoneNumber,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Toplam Randevu: ${patientAppointments.length}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.check_circle, size: 16, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  'Tamamlanan: $completedAppointments',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            if (lastAppointment != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Son Randevu: ${lastAppointment.date.day}/${lastAppointment.date.month}/${lastAppointment.date.year} - ${lastAppointment.time}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('Detaylar'),
                  onPressed: () {
                    // Hasta detaylarını göster
                    _showPatientDetails(patient, patientAppointments);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPatientDetails(User patient, List<Appointment> appointments) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(patient.fullName),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('E-posta'),
                subtitle: Text(patient.email),
              ),
              ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('Telefon'),
                subtitle: Text(patient.phoneNumber),
              ),
              // Doğum tarihi bilgisi (şu an User modelinde yok)
              const ListTile(
                leading: Icon(Icons.cake),
                title: Text('Doğum Tarihi'),
                subtitle: Text('Bilgi yok'),
              ),
              const Divider(),
              const Text(
                'Randevular',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              if (appointments.isEmpty)
                const Text(
                  'Randevu bulunamadı',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
                ...appointments.map((appointment) => ListTile(
                      leading: Icon(
                        appointment.status.toLowerCase() == 'tamamlandı'
                            ? Icons.check_circle
                            : appointment.status.toLowerCase() == 'iptal edildi'
                                ? Icons.cancel
                                : Icons.pending_actions,
                        color: appointment.status.toLowerCase() == 'tamamlandı'
                            ? Colors.green
                            : appointment.status.toLowerCase() == 'iptal edildi'
                                ? Colors.red
                                : Colors.orange,
                      ),
                      title: Text(
                          '${appointment.date.day}/${appointment.date.month}/${appointment.date.year} - ${appointment.time}'),
                      subtitle:
                          Text('${appointment.type} - ${appointment.status}'),
                    )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }
}
