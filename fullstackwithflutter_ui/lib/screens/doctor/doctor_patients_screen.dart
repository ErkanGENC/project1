import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../models/user_model.dart';
import '../../models/appointment_model.dart';
import '../../services/api_service.dart';
import '../../routes/app_routes.dart';

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
  User? _currentDoctor;
  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'Tümü'; // Randevu durumuna göre filtreleme

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
      final isDoctorUser = userRole == 'doctor';

      if (!isDoctorUser) {
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

      // Tüm hastaları al
      final allUsers = await _apiService.getAllUsers();

      // Sadece hastaları filtrele (doktor ve admin olmayanlar)
      final patients =
          allUsers.where((user) => user.role.toLowerCase() == 'user').toList();

      // Doktorun hastalarını bul (randevusu olan hastalar)
      final patientEmails =
          _appointments.map((appointment) => appointment.patientEmail).toSet();

      // Doktorun hastalarını filtrele
      _allPatients = patients
          .where((patient) => patientEmails.contains(patient.email))
          .toList();

      _filteredPatients = List.from(_allPatients);

      // Hastaları randevu tarihine göre sırala
      _filteredPatients.sort((a, b) {
        // a hastasının en son randevusu
        final aAppointments = _appointments
            .where((appointment) => appointment.patientEmail == a.email)
            .toList();
        final bAppointments = _appointments
            .where((appointment) => appointment.patientEmail == b.email)
            .toList();

        if (aAppointments.isEmpty) {
          return 1; // a'nın randevusu yoksa sonda olsun
        }
        if (bAppointments.isEmpty) {
          return -1; // b'nin randevusu yoksa sonda olsun
        }

        // En son randevuları bul
        final lastAppointmentA = aAppointments
            .reduce((curr, next) => curr.date.isAfter(next.date) ? curr : next);
        final lastAppointmentB = bAppointments
            .reduce((curr, next) => curr.date.isAfter(next.date) ? curr : next);

        // Tarihleri karşılaştır (en yeni önce)
        return lastAppointmentB.date.compareTo(lastAppointmentA.date);
      });

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

  void _filterPatients() {
    final query = _searchController.text.toLowerCase();

    // Önce arama sorgusuna göre filtrele
    List<User> filteredBySearch;
    if (query.isEmpty) {
      filteredBySearch = List.from(_allPatients);
    } else {
      filteredBySearch = _allPatients
          .where((patient) =>
              patient.fullName.toLowerCase().contains(query) ||
              patient.email.toLowerCase().contains(query) ||
              patient.phoneNumber.toLowerCase().contains(query))
          .toList();
    }

    // Sonra randevu durumuna göre filtrele
    setState(() {
      if (_filterStatus == 'Tümü') {
        _filteredPatients = filteredBySearch;
      } else {
        _filteredPatients = filteredBySearch.where((patient) {
          // Hastanın randevularını bul
          final patientAppointments = _appointments
              .where((appointment) => appointment.patientEmail == patient.email)
              .toList();

          // Duruma göre filtrele
          switch (_filterStatus) {
            case 'Tamamlanan Tedaviler':
              // En az bir tamamlanmış randevusu olan hastalar
              return patientAppointments.any((appointment) =>
                  appointment.status.toLowerCase() == 'tamamlandı');
            case 'Devam Eden Tedaviler':
              // Bekleyen veya onaylanmış randevusu olan hastalar
              return patientAppointments.any((appointment) =>
                  appointment.status.toLowerCase() == 'bekleyen' ||
                  appointment.status.toLowerCase() == 'onaylandı');
            default:
              return true;
          }
        }).toList();
      }

      // Randevu tarihine göre sırala (en yeni randevusu olan hastalar önce)
      _filteredPatients.sort((a, b) {
        // a hastasının en son randevusu
        final aAppointments = _appointments
            .where((appointment) => appointment.patientEmail == a.email)
            .toList();
        final bAppointments = _appointments
            .where((appointment) => appointment.patientEmail == b.email)
            .toList();

        if (aAppointments.isEmpty) {
          return 1; // a'nın randevusu yoksa sonda olsun
        }
        if (bAppointments.isEmpty) {
          return -1; // b'nin randevusu yoksa sonda olsun
        }

        // En son randevuları bul
        final lastAppointmentA = aAppointments
            .reduce((curr, next) => curr.date.isAfter(next.date) ? curr : next);
        final lastAppointmentB = bAppointments
            .reduce((curr, next) => curr.date.isAfter(next.date) ? curr : next);

        // Tarihleri karşılaştır (en yeni önce)
        return lastAppointmentB.date.compareTo(lastAppointmentA.date);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dr. ${_currentDoctor?.fullName ?? 'Doktor'} - Hastalarım'),
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
              : Column(
                  children: [
                    // Arama ve filtreleme alanı
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Arama alanı
                          TextField(
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

                          const SizedBox(height: 16),

                          // Filtreleme seçenekleri
                          Row(
                            children: [
                              const Text('Filtrele: ',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _filterStatus,
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'Tümü',
                                        child: Text('Tüm Hastalar')),
                                    DropdownMenuItem(
                                        value: 'Tamamlanan Tedaviler',
                                        child: Text('Tamamlanan Tedaviler')),
                                    DropdownMenuItem(
                                        value: 'Devam Eden Tedaviler',
                                        child: Text('Devam Eden Tedaviler')),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _filterStatus = value!;
                                      _filterPatients();
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Hasta sayısı
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Toplam ${_filteredPatients.length} hasta',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const Text(
                            'Randevu tarihine göre sıralandı',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              fontSize: 12,
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
            selected: true,
            onTap: () {
              Navigator.pop(context);
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
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.doctorSettings);
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
}
