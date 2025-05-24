import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/admin/chart_card.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  ReportsPageState createState() => ReportsPageState();
}

class ReportsPageState extends State<ReportsPage>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic> _reportData = {};
  late TabController _tabController;

  final List<String> _reportTypes = [
    'Genel Bakış',
    'Hasta İstatistikleri',
    'Randevu İstatistikleri',
    'Doktor-Hasta İlişkileri',
    'Gelir Raporu'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _reportTypes.length, vsync: this);
    _loadReportData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReportData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      
      final reportData = await _apiService.getReportData();

      
      if (reportData.isEmpty) {
        throw Exception('Rapor verileri alınamadı');
      }

      
      if (!reportData.containsKey('patientStats')) {
        reportData['patientStats'] = {
          'totalPatients': 0,
          'newPatients': 0,
          'activePatients': 0,
          'inactivePatients': 0,
          'patientsByAge': [],
          'patientsByGender': [],
        };
      }

      if (!reportData.containsKey('appointmentStats')) {
        reportData['appointmentStats'] = {
          'totalAppointments': 0,
          'completedAppointments': 0,
          'pendingAppointments': 0,
          'cancelledAppointments': 0,
          'appointmentsByMonth': [],
          'appointmentsByType': [],
        };
      }

      if (!reportData.containsKey('revenueStats')) {
        reportData['revenueStats'] = {
          'totalRevenue': 0,
          'pendingPayments': 0,
          'revenueByMonth': [],
          'revenueByService': [],
        };
      }

      
      _ensureDataStructure(reportData);

      setState(() {
        _reportData = reportData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  
  void _ensureDataStructure(Map<String, dynamic> data) {
    
    final patientStats = data['patientStats'];
    if (patientStats['patientsByAge'] == null ||
        patientStats['patientsByAge'].isEmpty) {
      patientStats['patientsByAge'] = [
        {'age': '0-18', 'count': 0},
        {'age': '19-30', 'count': 0},
        {'age': '31-45', 'count': 0},
        {'age': '46-60', 'count': 0},
        {'age': '60+', 'count': 0},
      ];
    }

    if (patientStats['patientsByGender'] == null ||
        patientStats['patientsByGender'].isEmpty) {
      patientStats['patientsByGender'] = [
        {'gender': 'Erkek', 'count': 0},
        {'gender': 'Kadın', 'count': 0},
      ];
    }

    
    final appointmentStats = data['appointmentStats'];
    if (appointmentStats['appointmentsByMonth'] == null ||
        appointmentStats['appointmentsByMonth'].isEmpty) {
      appointmentStats['appointmentsByMonth'] = [
        {'month': 'Ocak', 'count': 0},
        {'month': 'Şubat', 'count': 0},
        {'month': 'Mart', 'count': 0},
        {'month': 'Nisan', 'count': 0},
        {'month': 'Mayıs', 'count': 0},
        {'month': 'Haziran', 'count': 0},
      ];
    }

    if (appointmentStats['appointmentsByType'] == null ||
        appointmentStats['appointmentsByType'].isEmpty) {
      appointmentStats['appointmentsByType'] = [
        {'type': 'Diş Kontrolü', 'count': 0},
        {'type': 'Dolgu', 'count': 0},
        {'type': 'Kanal Tedavisi', 'count': 0},
        {'type': 'Diş Çekimi', 'count': 0},
        {'type': 'Diş Temizliği', 'count': 0},
      ];
    }

    
    final revenueStats = data['revenueStats'];
    if (revenueStats['revenueByMonth'] == null ||
        revenueStats['revenueByMonth'].isEmpty) {
      revenueStats['revenueByMonth'] = [
        {'month': 'Ocak', 'amount': 0},
        {'month': 'Şubat', 'amount': 0},
        {'month': 'Mart', 'amount': 0},
        {'month': 'Nisan', 'amount': 0},
        {'month': 'Mayıs', 'amount': 0},
        {'month': 'Haziran', 'amount': 0},
      ];
    }

    if (revenueStats['revenueByService'] == null ||
        revenueStats['revenueByService'].isEmpty) {
      revenueStats['revenueByService'] = [
        {'service': 'Diş Kontrolü', 'amount': 0},
        {'service': 'Dolgu', 'amount': 0},
        {'service': 'Kanal Tedavisi', 'amount': 0},
        {'service': 'Diş Çekimi', 'amount': 0},
        {'service': 'Diş Temizliği', 'amount': 0},
      ];
    }

    
    if (!data.containsKey('doctorPatientStats')) {
      data['doctorPatientStats'] = {
        'doctorPatientDistribution': [
          {'doctor': 'Dr. Ahmet Yılmaz', 'patients': 45},
          {'doctor': 'Dr. Ayşe Demir', 'patients': 38},
          {'doctor': 'Dr. Mehmet Kaya', 'patients': 52},
          {'doctor': 'Dr. Zeynep Çelik', 'patients': 31},
          {'doctor': 'Dr. Ali Öztürk', 'patients': 27},
        ],
        'doctorAppointmentDistribution': [
          {'doctor': 'Dr. Ahmet Yılmaz', 'appointments': 78},
          {'doctor': 'Dr. Ayşe Demir', 'appointments': 65},
          {'doctor': 'Dr. Mehmet Kaya', 'appointments': 92},
          {'doctor': 'Dr. Zeynep Çelik', 'appointments': 54},
          {'doctor': 'Dr. Ali Öztürk', 'appointments': 48},
        ],
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raporlar ve İstatistikler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReportData,
            tooltip: 'Yenile',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _reportTypes.map((type) => Tab(text: type)).toList(),
        ),
      ),
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
                        color: Colors.red,
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
                        onPressed: _loadReportData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildPatientStatsTab(),
                    _buildAppointmentStatsTab(),
                    _buildDoctorPatientRelationsTab(),
                    _buildRevenueStatsTab(),
                  ],
                ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Genel Bakış',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
          ),
          const SizedBox(height: 24),

          
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Toplam Hasta',
                  value:
                      _reportData['patientStats']['totalPatients'].toString(),
                  icon: Icons.people,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Toplam Randevu',
                  value: _reportData['appointmentStats']['totalAppointments']
                      .toString(),
                  icon: Icons.calendar_today,
                  color: AppTheme.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Toplam Gelir',
                  value: '${_reportData['revenueStats']['totalRevenue']} ₺',
                  icon: Icons.attach_money,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Bekleyen Ödemeler',
                  value: '${_reportData['revenueStats']['pendingPayments']} ₺',
                  icon: Icons.payment,
                  color: Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
          Text(
            'Hasta Dağılımı',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
          ),
          const SizedBox(height: 16),

          
          ChartCard(
            title: 'Yaş Gruplarına Göre Hastalar',
            data: _reportData['patientStats']['patientsByAge'],
            xKey: 'age',
            yKey: 'count',
            color: AppTheme.primaryColor,
          ),

          const SizedBox(height: 24),
          Text(
            'Randevu Dağılımı',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
          ),
          const SizedBox(height: 16),

          
          ChartCard(
            title: 'Aylara Göre Randevular',
            data: _reportData['appointmentStats']['appointmentsByMonth'],
            xKey: 'month',
            yKey: 'count',
            color: AppTheme.accentColor,
          ),

          const SizedBox(height: 24),
          Text(
            'Gelir Dağılımı',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
          ),
          const SizedBox(height: 16),

          
          ChartCard(
            title: 'Aylara Göre Gelir',
            data: _reportData['revenueStats']['revenueByMonth'],
            xKey: 'month',
            yKey: 'amount',
            color: Colors.green,
            isCurrency: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPatientStatsTab() {
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
          const SizedBox(height: 24),

          
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Toplam Hasta',
                  value:
                      _reportData['patientStats']['totalPatients'].toString(),
                  icon: Icons.people,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Yeni Hastalar',
                  value: _reportData['patientStats']['newPatients'].toString(),
                  icon: Icons.person_add,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Aktif Hastalar',
                  value:
                      _reportData['patientStats']['activePatients'].toString(),
                  icon: Icons.person,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Pasif Hastalar',
                  value: _reportData['patientStats']['inactivePatients']
                      .toString(),
                  icon: Icons.person_off,
                  color: Colors.grey,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
          Text(
            'Hasta Dağılımı',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
          ),
          const SizedBox(height: 16),

          
          ChartCard(
            title: 'Yaş Gruplarına Göre Hastalar',
            data: _reportData['patientStats']['patientsByAge'],
            xKey: 'age',
            yKey: 'count',
            color: AppTheme.primaryColor,
          ),

          const SizedBox(height: 24),

          
          ChartCard(
            title: 'Cinsiyete Göre Hastalar',
            data: _reportData['patientStats']['patientsByGender'],
            xKey: 'gender',
            yKey: 'count',
            color: Colors.purple,
            isPieChart: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Randevu İstatistikleri',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
          ),
          const SizedBox(height: 24),

          
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Toplam Randevu',
                  value: _reportData['appointmentStats']['totalAppointments']
                      .toString(),
                  icon: Icons.calendar_today,
                  color: AppTheme.accentColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Tamamlanan',
                  value: _reportData['appointmentStats']
                          ['completedAppointments']
                      .toString(),
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'İptal Edilen',
                  value: _reportData['appointmentStats']
                          ['cancelledAppointments']
                      .toString(),
                  icon: Icons.cancel,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Bekleyen',
                  value: _reportData['appointmentStats']['pendingAppointments']
                      .toString(),
                  icon: Icons.pending_actions,
                  color: Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
          Text(
            'Randevu Dağılımı',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
          ),
          const SizedBox(height: 16),

          
          ChartCard(
            title: 'Aylara Göre Randevular',
            data: _reportData['appointmentStats']['appointmentsByMonth'],
            xKey: 'month',
            yKey: 'count',
            color: AppTheme.accentColor,
          ),

          const SizedBox(height: 24),

          
          ChartCard(
            title: 'Türlere Göre Randevular',
            data: _reportData['appointmentStats']['appointmentsByType'],
            xKey: 'type',
            yKey: 'count',
            color: Colors.teal,
            isPieChart: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorPatientRelationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Doktor-Hasta İlişkileri',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
          ),
          const SizedBox(height: 24),

          
          ChartCard(
            title: 'Doktor Başına Hasta Dağılımı',
            data: _reportData['doctorPatientStats']
                ['doctorPatientDistribution'],
            xKey: 'doctor',
            yKey: 'patients',
            color: Colors.blue,
          ),

          const SizedBox(height: 24),

          
          ChartCard(
            title: 'Doktor Başına Randevu Dağılımı',
            data: _reportData['doctorPatientStats']
                ['doctorAppointmentDistribution'],
            xKey: 'doctor',
            yKey: 'appointments',
            color: Colors.purple,
          ),

          const SizedBox(height: 24),

          
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Doktor-Hasta İlişkileri Analizi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bu bölüm, her doktorun kaç hastaya hizmet verdiğini ve toplam randevu sayılarını göstermektedir. '
                    'Bu veriler, doktor iş yükü dağılımını analiz etmek ve kapasite planlaması yapmak için kullanılabilir.',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          title: 'En Yüksek Hasta Sayısı',
                          value: _getMaxPatientCount().toString(),
                          icon: Icons.people,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoCard(
                          title: 'En Yüksek Randevu Sayısı',
                          value: _getMaxAppointmentCount().toString(),
                          icon: Icons.calendar_today,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  
  int _getMaxPatientCount() {
    final doctorPatientDistribution =
        _reportData['doctorPatientStats']['doctorPatientDistribution'];
    if (doctorPatientDistribution == null ||
        doctorPatientDistribution.isEmpty) {
      return 0;
    }

    return doctorPatientDistribution
        .map<int>((item) => item['patients'] as int)
        .reduce((a, b) => a > b ? a : b);
  }

  
  int _getMaxAppointmentCount() {
    final doctorAppointmentDistribution =
        _reportData['doctorPatientStats']['doctorAppointmentDistribution'];
    if (doctorAppointmentDistribution == null ||
        doctorAppointmentDistribution.isEmpty) {
      return 0;
    }

    return doctorAppointmentDistribution
        .map<int>((item) => item['appointments'] as int)
        .reduce((a, b) => a > b ? a : b);
  }

  
  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gelir Raporu',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
          ),
          const SizedBox(height: 24),

          
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Toplam Gelir',
                  value: '${_reportData['revenueStats']['totalRevenue']} ₺',
                  icon: Icons.attach_money,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Bekleyen Ödemeler',
                  value: '${_reportData['revenueStats']['pendingPayments']} ₺',
                  icon: Icons.payment,
                  color: Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
          Text(
            'Gelir Dağılımı',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
          ),
          const SizedBox(height: 16),

          
          ChartCard(
            title: 'Aylara Göre Gelir',
            data: _reportData['revenueStats']['revenueByMonth'],
            xKey: 'month',
            yKey: 'amount',
            color: Colors.green,
            isCurrency: true,
          ),

          const SizedBox(height: 24),

          
          ChartCard(
            title: 'Hizmetlere Göre Gelir',
            data: _reportData['revenueStats']['revenueByService'],
            xKey: 'service',
            yKey: 'amount',
            color: Colors.indigo,
            isPieChart: true,
            isCurrency: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
