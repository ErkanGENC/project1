import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';

/// Ağız ve diş sağlığı takip ekranı
class DentalHealthScreen extends StatefulWidget {
  const DentalHealthScreen({Key? key}) : super(key: key);

  @override
  _DentalHealthScreenState createState() => _DentalHealthScreenState();
}

class _DentalHealthScreenState extends State<DentalHealthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Diş fırçalama takibi için değişkenler
  int _brushingCount = 0;
  bool _morningBrushing = false;
  bool _eveningBrushing = false;
  
  // Diş ipi kullanımı için değişkenler
  bool _usedFloss = false;
  
  // Ağız gargarası kullanımı için değişkenler
  bool _usedMouthwash = false;
  
  // Günlük hedefler
  final int _brushingTarget = 2;
  final bool _flossTarget = true;
  final bool _mouthwashTarget = true;
  
  // Haftalık istatistikler (örnek veriler)
  final List<int> _weeklyBrushing = [2, 2, 1, 2, 2, 1, 0];
  final List<bool> _weeklyFloss = [true, true, false, true, false, false, false];
  final List<bool> _weeklyMouthwash = [true, true, true, false, true, false, false];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _updateBrushingStatus(String time, bool value) {
    setState(() {
      if (time == 'morning') {
        _morningBrushing = value;
      } else {
        _eveningBrushing = value;
      }
      
      _brushingCount = (_morningBrushing ? 1 : 0) + (_eveningBrushing ? 1 : 0);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ağız ve Diş Sağlığı'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Günlük Takip'),
            Tab(text: 'İstatistikler'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDailyTrackingTab(),
          _buildStatisticsTab(),
        ],
      ),
    );
  }
  
  Widget _buildDailyTrackingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarih gösterimi
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Günlük ilerleme özeti
          _buildProgressSummary(),
          const SizedBox(height: 32),
          
          // Diş fırçalama takibi
          const Text(
            'Diş Fırçalama',
            style: AppTheme.subheadingStyle,
          ),
          const SizedBox(height: 8),
          _buildTrackingCard(
            icon: Icons.brush,
            title: 'Sabah Diş Fırçalama',
            isCompleted: _morningBrushing,
            onChanged: (value) => _updateBrushingStatus('morning', value ?? false),
          ),
          const SizedBox(height: 8),
          _buildTrackingCard(
            icon: Icons.brush,
            title: 'Akşam Diş Fırçalama',
            isCompleted: _eveningBrushing,
            onChanged: (value) => _updateBrushingStatus('evening', value ?? false),
          ),
          const SizedBox(height: 24),
          
          // Diş ipi kullanımı
          const Text(
            'Diş İpi Kullanımı',
            style: AppTheme.subheadingStyle,
          ),
          const SizedBox(height: 8),
          _buildTrackingCard(
            icon: Icons.linear_scale,
            title: 'Günlük Diş İpi Kullanımı',
            isCompleted: _usedFloss,
            onChanged: (value) {
              setState(() {
                _usedFloss = value ?? false;
              });
            },
          ),
          const SizedBox(height: 24),
          
          // Ağız gargarası kullanımı
          const Text(
            'Ağız Gargarası',
            style: AppTheme.subheadingStyle,
          ),
          const SizedBox(height: 8),
          _buildTrackingCard(
            icon: Icons.local_drink,
            title: 'Günlük Ağız Gargarası Kullanımı',
            isCompleted: _usedMouthwash,
            onChanged: (value) {
              setState(() {
                _usedMouthwash = value ?? false;
              });
            },
          ),
          const SizedBox(height: 24),
          
          // Notlar
          const Text(
            'Notlar',
            style: AppTheme.subheadingStyle,
          ),
          const SizedBox(height: 8),
          TextField(
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Bugün için notlarınızı buraya ekleyin...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          // Kaydet butonu
          Center(
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Günlük takip kaydedildi!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(
                'Günü Kaydet',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProgressSummary() {
    // Günlük hedeflerin tamamlanma durumu
    final int completedGoals = (_brushingCount >= _brushingTarget ? 1 : 0) +
        (_usedFloss == _flossTarget ? 1 : 0) +
        (_usedMouthwash == _mouthwashTarget ? 1 : 0);
    
    final double progressPercentage = completedGoals / 3;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Günlük İlerleme',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildProgressIndicator(
                  'Diş Fırçalama',
                  _brushingCount,
                  _brushingTarget,
                  Icons.brush,
                ),
                _buildProgressIndicator(
                  'Diş İpi',
                  _usedFloss ? 1 : 0,
                  1,
                  Icons.linear_scale,
                ),
                _buildProgressIndicator(
                  'Gargara',
                  _usedMouthwash ? 1 : 0,
                  1,
                  Icons.local_drink,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progressPercentage,
              minHeight: 10,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                progressPercentage == 1.0 ? Colors.green : AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progressPercentage * 100).toInt()}% tamamlandı',
              style: TextStyle(
                color: progressPercentage == 1.0 ? Colors.green : AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProgressIndicator(String title, int current, int target, IconData icon) {
    final bool isCompleted = current >= target;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isCompleted ? Colors.green : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isCompleted ? Colors.white : Colors.grey[600],
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '$current/$target',
          style: TextStyle(
            fontSize: 12,
            color: isCompleted ? Colors.green : Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  Widget _buildTrackingCard({
    required IconData icon,
    required String title,
    required bool isCompleted,
    required Function(bool?) onChanged,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCompleted ? Colors.green : Colors.grey.shade300,
          width: isCompleted ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isCompleted ? Colors.green : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            Checkbox(
              value: isCompleted,
              onChanged: onChanged,
              activeColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatisticsTab() {
    // Haftalık istatistikleri hesapla
    final int totalBrushing = _weeklyBrushing.reduce((a, b) => a + b);
    final int totalFloss = _weeklyFloss.where((day) => day).length;
    final int totalMouthwash = _weeklyMouthwash.where((day) => day).length;
    
    // Haftanın günleri
    final List<String> weekdays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Haftalık özet
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Haftalık Özet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatisticItem(
                        'Diş Fırçalama',
                        '$totalBrushing/14',
                        Icons.brush,
                        totalBrushing / 14,
                      ),
                      _buildStatisticItem(
                        'Diş İpi',
                        '$totalFloss/7',
                        Icons.linear_scale,
                        totalFloss / 7,
                      ),
                      _buildStatisticItem(
                        'Gargara',
                        '$totalMouthwash/7',
                        Icons.local_drink,
                        totalMouthwash / 7,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Diş fırçalama grafiği
          const Text(
            'Diş Fırçalama',
            style: AppTheme.subheadingStyle,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (index) {
                    return _buildBarChartItem(
                      weekdays[index],
                      _weeklyBrushing[index],
                      2,
                    );
                  }),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Diş ipi ve gargara grafiği
          const Text(
            'Diş İpi ve Gargara Kullanımı',
            style: AppTheme.subheadingStyle,
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: List.generate(7, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 40,
                          child: Text(
                            weekdays[index],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Row(
                            children: [
                              _buildStatusIndicator(
                                'Diş İpi',
                                _weeklyFloss[index],
                              ),
                              const SizedBox(width: 16),
                              _buildStatusIndicator(
                                'Gargara',
                                _weeklyMouthwash[index],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // İpuçları
          const Text(
            'Ağız Sağlığı İpuçları',
            style: AppTheme.subheadingStyle,
          ),
          const SizedBox(height: 8),
          _buildTipCard(
            'Diş fırçalarken en az 2 dakika boyunca fırçalamaya özen gösterin.',
            Icons.timer,
          ),
          const SizedBox(height: 8),
          _buildTipCard(
            'Diş ipi kullanırken her diş arasına C şeklinde hareket ettirin.',
            Icons.linear_scale,
          ),
          const SizedBox(height: 8),
          _buildTipCard(
            'Diş fırçanızı 3 ayda bir değiştirmeyi unutmayın.',
            Icons.change_circle_outlined,
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatisticItem(String title, String value, IconData icon, double progress) {
    final Color color = progress >= 0.7 ? Colors.green : AppTheme.primaryColor;
    
    return Column(
      children: [
        SizedBox(
          height: 60,
          width: 60,
          child: Stack(
            children: [
              Center(
                child: SizedBox(
                  height: 60,
                  width: 60,
                  child: CircularProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    strokeWidth: 6,
                  ),
                ),
              ),
              Center(
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }
  
  Widget _buildBarChartItem(String day, int value, int target) {
    final double percentage = value / target;
    final Color color = percentage >= 1 ? Colors.green : AppTheme.primaryColor;
    final double height = 120 * percentage;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '$value/$target',
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 24,
          height: height > 0 ? height : 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatusIndicator(String title, bool isCompleted) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: isCompleted ? Colors.green : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: isCompleted
                ? const Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.white,
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
    );
  }
  
  Widget _buildTipCard(String tip, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(tip),
            ),
          ],
        ),
      ),
    );
  }
}
