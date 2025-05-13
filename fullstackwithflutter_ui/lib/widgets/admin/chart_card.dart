import 'package:flutter/material.dart';

class ChartCard extends StatelessWidget {
  final String title;
  final List<dynamic> data;
  final String xKey;
  final String yKey;
  final Color color;
  final bool isPieChart;
  final bool isCurrency;

  const ChartCard({
    super.key,
    required this.title,
    required this.data,
    required this.xKey,
    required this.yKey,
    required this.color,
    this.isPieChart = false,
    this.isCurrency = false,
  });

  @override
  Widget build(BuildContext context) {
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
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: isPieChart
                  ? _buildPieChart()
                  : _buildBarChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    // Gerçek uygulamada, burada fl_chart veya charts_flutter gibi bir kütüphane kullanabilirsiniz
    // Şimdilik basit bir görselleştirme yapıyoruz
    
    // Y eksenindeki maksimum değeri bul
    final double maxValue = data.map<double>((item) => (item[yKey] as num).toDouble()).reduce((a, b) => a > b ? a : b);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.map((item) {
              final double value = (item[yKey] as num).toDouble();
              final double percentage = value / maxValue;
              
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        isCurrency ? '${value.toInt()} ₺' : value.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 150 * percentage,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: data.map((item) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  item[xKey] as String,
                  style: const TextStyle(
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPieChart() {
    // Gerçek uygulamada, burada fl_chart veya charts_flutter gibi bir kütüphane kullanabilirsiniz
    // Şimdilik basit bir görselleştirme yapıyoruz
    
    // Toplam değeri hesapla
    final double total = data.map<double>((item) => (item[yKey] as num).toDouble()).reduce((a, b) => a + b);
    
    // Renk listesi
    final List<Color> colors = [
      color,
      color.withOpacity(0.8),
      color.withOpacity(0.6),
      color.withOpacity(0.4),
      color.withOpacity(0.2),
      Colors.grey,
    ];
    
    return Row(
      children: [
        // Pasta grafiği (basit bir temsil)
        Expanded(
          flex: 2,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: colors.take(data.length).toList(),
                stops: List.generate(data.length, (index) {
                  final double value = (data[index][yKey] as num).toDouble();
                  return value / total;
                }),
              ),
            ),
          ),
        ),
        
        // Açıklama
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(data.length, (index) {
              final item = data[index];
              final double value = (item[yKey] as num).toDouble();
              final double percentage = (value / total) * 100;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: index < colors.length ? colors[index] : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item[xKey] as String,
                        style: const TextStyle(
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isCurrency
                          ? '${value.toInt()} ₺ (${percentage.toStringAsFixed(1)}%)'
                          : '${value.toInt()} (${percentage.toStringAsFixed(1)}%)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
