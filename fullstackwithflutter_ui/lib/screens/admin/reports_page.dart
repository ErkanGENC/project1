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
      // API'den rapor verilerini al
      final reportData = await _apiService.getReportData();

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

          // Özet kartları
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

          // Hasta dağılımı grafiği
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

          // Randevu dağılımı grafiği
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

          // Gelir dağılımı grafiği
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

          // Özet kartları
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

          // Yaş gruplarına göre hasta dağılımı
          ChartCard(
            title: 'Yaş Gruplarına Göre Hastalar',
            data: _reportData['patientStats']['patientsByAge'],
            xKey: 'age',
            yKey: 'count',
            color: AppTheme.primaryColor,
          ),

          const SizedBox(height: 24),

          // Cinsiyete göre hasta dağılımı
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

          // Özet kartları
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

          // Aylara göre randevu dağılımı
          ChartCard(
            title: 'Aylara Göre Randevular',
            data: _reportData['appointmentStats']['appointmentsByMonth'],
            xKey: 'month',
            yKey: 'count',
            color: AppTheme.accentColor,
          ),

          const SizedBox(height: 24),

          // Türlere göre randevu dağılımı
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

          // Özet kartları
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

          // Aylara göre gelir dağılımı
          ChartCard(
            title: 'Aylara Göre Gelir',
            data: _reportData['revenueStats']['revenueByMonth'],
            xKey: 'month',
            yKey: 'amount',
            color: Colors.green,
            isCurrency: true,
          ),

          const SizedBox(height: 24),

          // Hizmetlere göre gelir dağılımı
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
