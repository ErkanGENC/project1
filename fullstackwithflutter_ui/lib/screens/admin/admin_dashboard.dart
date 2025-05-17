import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../models/activity.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../widgets/admin/dashboard_card.dart';
import '../../widgets/admin/recent_activity_card.dart';
import '../../widgets/admin/stats_card.dart';
import 'patients_management.dart';
import 'appointments_management.dart';
import 'doctors_management.dart';
import 'reports_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  AdminDashboardState createState() => AdminDashboardState();
}

class AdminDashboardState extends State<AdminDashboard> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic> _dashboardData = {};
  List<Activity> _activities = [];
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  // Admin erişim kontrolü
  Future<void> _checkAdminAccess() async {
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

      if (userRole != 'admin') {
        // Admin değilse, uygun sayfaya yönlendir
        if (!mounted) return;

        String redirectRoute = '/';
        String message = 'Admin paneline erişim yetkiniz yok';

        // Doktor kullanıcısı ise doktor paneline yönlendir
        if (userRole == 'doctor') {
          redirectRoute = '/doctor/dashboard';
          message = 'Doktor paneline yönlendiriliyorsunuz';
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

      // Admin kullanıcısı, verileri yükle
      setState(() {
        _currentUser = currentUser;
      });

      // Dashboard verilerini yükle
      _loadDashboardData();
      _loadActivities();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Kullanıcı bilgileri alınırken bir hata oluştu: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // API'den dashboard verilerini al
      final dashboardData = await _apiService.getDashboardData();

      setState(() {
        _dashboardData = dashboardData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Veri yüklenirken bir hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadActivities() async {
    try {
      // API'den aktivite verilerini al
      final activities = await _apiService.getRecentActivities(10);

      setState(() {
        _activities = activities;
      });
    } catch (e) {
      print('Aktiviteler yüklenirken bir hata oluştu: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.home),
            label: const Text('Kullanıcı Paneli'),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Bildirimler sayfasına git
            },
            tooltip: 'Bildirimler',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadDashboardData();
              _loadActivities();
            },
            tooltip: 'Yenile',
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppTheme.errorColor,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Bir hata oluştu',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          _loadDashboardData();
                          _loadActivities();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : _buildDashboardContent(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          const UserAccountsDrawerHeader(
            accountName: Text('Admin Kullanıcı'),
            accountEmail: Text('admin@example.com'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                'A',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Kullanıcı Paneli'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/');
            },
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
            leading: const Icon(Icons.people),
            title: const Text('Hasta Yönetimi'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PatientsManagement(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Randevu Yönetimi'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AppointmentsManagement(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.medical_services),
            title: const Text('Doktor Yönetimi'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DoctorsManagement(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Raporlar ve İstatistikler'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReportsPage(),
                ),
              );
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
          ListTile(
            leading: const Icon(Icons.cleaning_services),
            title: const Text('Doktor Kullanıcılarını Temizle'),
            onTap: () {
              Navigator.pop(context);
              _showCleanupDoctorUsersDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings),
            title: const Text('Admin Kullanıcısı Oluştur'),
            onTap: () {
              Navigator.pop(context);
              _showCreateAdminUserDialog();
            },
          ),
          const SizedBox(height: 40), // Spacer yerine SizedBox kullanıldı
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
            onTap: () async {
              // Çıkış işlemi
              await _apiService.logout();
              if (!mounted) return;
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Doktor kullanıcılarını temizleme dialog'u
  Future<void> _showCleanupDoctorUsersDialog() async {
    bool isLoading = false;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Doktor Kullanıcılarını Temizle'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    const Text(
                      'Bu işlem, doktor kullanıcılarını appUsers tablosundan temizleyecek ve sadece doctors tablosunda tutacaktır.',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Bu işlem, doktor kullanıcılarının kimlik doğrulama ve yönlendirme sorunlarını çözmek için gereklidir.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Devam etmek istiyor musunuz?',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 16.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          Navigator.of(dialogContext).pop();
                        },
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          // Yükleniyor durumunu güncelle
                          setState(() {
                            isLoading = true;
                          });

                          try {
                            // API isteğini yap
                            final result =
                                await _apiService.cleanupDoctorUsers();

                            // Sonuç mesajını hazırla
                            final String message =
                                result['message'] ?? 'İşlem tamamlandı';
                            final bool success = result['success'] ?? false;

                            // Dialog'u kapat ve sonucu göster
                            if (dialogContext.mounted) {
                              _showResultAndCloseDialog(
                                dialogContext: dialogContext,
                                message: message,
                                success: success,
                              );
                            }
                          } catch (error) {
                            // Yükleniyor durumunu güncelle
                            setState(() {
                              isLoading = false;
                            });

                            // Dialog'u kapat ve hatayı göster
                            if (dialogContext.mounted) {
                              _showResultAndCloseDialog(
                                dialogContext: dialogContext,
                                message: 'Bir hata oluştu: $error',
                                success: false,
                              );
                            }
                          }
                        },
                  child: const Text('Temizle'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Admin kullanıcısı oluşturma dialog'u
  Future<void> _showCreateAdminUserDialog() async {
    bool isLoading = false;
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController fullNameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Admin Kullanıcısı Oluştur'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: ListBody(
                    children: <Widget>[
                      const Text(
                        'Bu işlem, yeni bir admin kullanıcısı oluşturacaktır.',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: fullNameController,
                        decoration: const InputDecoration(
                          labelText: 'Ad Soyad',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen ad soyad girin';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'E-posta',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen e-posta girin';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return 'Geçerli bir e-posta adresi girin';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Şifre',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen şifre girin';
                          }
                          if (value.length < 6) {
                            return 'Şifre en az 6 karakter olmalıdır';
                          }
                          return null;
                        },
                      ),
                      if (isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 16.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop();
                        },
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          // Form doğrulama
                          if (formKey.currentState!.validate()) {
                            // Yükleniyor durumunu güncelle
                            setState(() {
                              isLoading = true;
                            });

                            // Admin kullanıcı verilerini hazırla
                            final adminData = {
                              'email': emailController.text,
                              'password': passwordController.text,
                              'fullName': fullNameController.text,
                              'role': 'admin',
                            };

                            try {
                              // API isteğini yap
                              final result =
                                  await _apiService.createAdminUser(adminData);

                              // Sonuç mesajını hazırla
                              final String message =
                                  result['message'] ?? 'İşlem tamamlandı';
                              final bool success = result['success'] ?? false;

                              // Dialog'u kapat ve sonucu göster
                              if (dialogContext.mounted) {
                                _showResultAndCloseDialog(
                                  dialogContext: dialogContext,
                                  message: message,
                                  success: success,
                                );
                              }
                            } catch (error) {
                              // Yükleniyor durumunu güncelle
                              setState(() {
                                isLoading = false;
                              });

                              // Dialog'u kapat ve hatayı göster
                              if (dialogContext.mounted) {
                                _showResultAndCloseDialog(
                                  dialogContext: dialogContext,
                                  message: 'Bir hata oluştu: $error',
                                  success: false,
                                );
                              }
                            }
                          }
                        },
                  child: const Text('Oluştur'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Dialog'u kapat ve sonucu göster
  void _showResultAndCloseDialog({
    required BuildContext dialogContext,
    required String message,
    required bool success,
  }) {
    // Dialog'u kapat
    Navigator.of(dialogContext).pop();

    // Sonucu göster
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: Duration(seconds: success ? 5 : 3),
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
            'Hoş Geldiniz, Admin',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Klinik durumunuza genel bir bakış',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.secondaryTextColor,
                ),
          ),
          const SizedBox(height: 24),

          // İstatistik Kartları
          Row(
            children: [
              Expanded(
                child: StatsCard(
                  title: 'Toplam Hasta',
                  value: _dashboardData['totalPatients']?.toString() ?? '0',
                  icon: Icons.people,
                  color: AppTheme.primaryColor,
                  increase: _dashboardData['totalPatientsChange'] ?? '+0%',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatsCard(
                  title: 'Bugünkü Randevular',
                  value: _dashboardData['todayAppointments']?.toString() ?? '0',
                  icon: Icons.calendar_today,
                  color: AppTheme.accentColor,
                  increase: _dashboardData['todayAppointmentsChange'] ?? '+0%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatsCard(
                  title: 'Aktif Hastalar',
                  value: _dashboardData['activePatients']?.toString() ?? '0',
                  icon: Icons.person,
                  color: AppTheme.successColor,
                  increase: _dashboardData['activePatientsChange'] ?? '+0%',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatsCard(
                  title: 'Bekleyen Randevular',
                  value:
                      _dashboardData['pendingAppointments']?.toString() ?? '0',
                  icon: Icons.pending_actions,
                  color: AppTheme.warningColor,
                  increase:
                      _dashboardData['pendingAppointmentsChange'] ?? '+0%',
                  isNegative:
                      (_dashboardData['pendingAppointmentsChange'] ?? '+0%')
                          .startsWith('-'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
          Text(
            'Hızlı Erişim',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
          ),
          const SizedBox(height: 16),

          // Hızlı Erişim Kartları
          Row(
            children: [
              Expanded(
                child: DashboardCard(
                  title: 'Hasta Ekle',
                  icon: Icons.person_add,
                  color: AppTheme.primaryColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PatientsManagement(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DashboardCard(
                  title: 'Randevu Oluştur',
                  icon: Icons.calendar_today,
                  color: AppTheme.accentColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AppointmentsManagement(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DashboardCard(
                  title: 'Doktor Ekle',
                  icon: Icons.medical_services,
                  color: Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DoctorsManagement(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DashboardCard(
                  title: 'Raporlar',
                  icon: Icons.bar_chart,
                  color: Colors.teal,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReportsPage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
          Text(
            'Son Aktiviteler',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
          ),
          const SizedBox(height: 16),

          // Son Aktiviteler
          RecentActivityCard(activities: _activities),
        ],
      ),
    );
  }
}
