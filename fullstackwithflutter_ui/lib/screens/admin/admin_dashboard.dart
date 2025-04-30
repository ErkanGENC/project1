import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/admin/dashboard_card.dart';
import '../../widgets/admin/recent_activity_card.dart';
import '../../widgets/admin/stats_card.dart';
import 'patients_management.dart';
import 'appointments_management.dart';
import 'doctors_management.dart';
import 'reports_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic> _dashboardData = {};
  
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }
  
  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Gerçek uygulamada, API'den dashboard verilerini alacaksınız
      // Şimdilik örnek veriler kullanıyoruz
      await Future.delayed(const Duration(seconds: 1)); // API çağrısı simülasyonu
      
      setState(() {
        _dashboardData = {
          'totalPatients': 256,
          'activePatients': 187,
          'todayAppointments': 24,
          'pendingAppointments': 12,
          'totalDoctors': 8,
          'totalRevenue': 45750,
          'recentActivities': [
            {
              'id': 1,
              'type': 'appointment',
              'title': 'Yeni Randevu',
              'description': 'Ayşe Yılmaz için diş kontrolü randevusu oluşturuldu',
              'time': '10 dakika önce',
              'icon': Icons.calendar_today,
              'color': AppTheme.primaryColor,
            },
            {
              'id': 2,
              'type': 'patient',
              'title': 'Yeni Hasta',
              'description': 'Mehmet Demir sisteme kaydedildi',
              'time': '45 dakika önce',
              'icon': Icons.person_add,
              'color': AppTheme.accentColor,
            },
            {
              'id': 3,
              'type': 'treatment',
              'title': 'Tedavi Tamamlandı',
              'description': 'Ali Kaya\'nın kanal tedavisi tamamlandı',
              'time': '1 saat önce',
              'icon': Icons.medical_services,
              'color': AppTheme.successColor,
            },
            {
              'id': 4,
              'type': 'payment',
              'title': 'Ödeme Alındı',
              'description': 'Zeynep Şahin\'den 1.250₺ ödeme alındı',
              'time': '3 saat önce',
              'icon': Icons.payment,
              'color': Colors.purple,
            },
          ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Bildirimler sayfasına git
            },
            tooltip: 'Bildirimler',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
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
                        onPressed: _loadDashboardData,
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
          UserAccountsDrawerHeader(
            accountName: const Text('Admin Kullanıcı'),
            accountEmail: const Text('admin@example.com'),
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
          const Spacer(),
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
                  value: _dashboardData['totalPatients'].toString(),
                  icon: Icons.people,
                  color: AppTheme.primaryColor,
                  increase: '+12%',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatsCard(
                  title: 'Bugünkü Randevular',
                  value: _dashboardData['todayAppointments'].toString(),
                  icon: Icons.calendar_today,
                  color: AppTheme.accentColor,
                  increase: '+5%',
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
                  value: _dashboardData['activePatients'].toString(),
                  icon: Icons.person,
                  color: AppTheme.successColor,
                  increase: '+8%',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatsCard(
                  title: 'Bekleyen Randevular',
                  value: _dashboardData['pendingAppointments'].toString(),
                  icon: Icons.pending_actions,
                  color: AppTheme.warningColor,
                  increase: '-3%',
                  isNegative: true,
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
          RecentActivityCard(activities: _dashboardData['recentActivities']),
        ],
      ),
    );
  }
}
