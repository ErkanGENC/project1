import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

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
              child: isPieChart ? _buildPieChart() : _buildBarChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    // fl_chart kütüphanesini kullanarak bar chart oluştur

    // Veri noktalarını hazırla
    final List<BarChartGroupData> barGroups = [];

    // Renk tonları oluştur
    final List<Color> barColors = List.generate(
      data.length,
      (index) => HSLColor.fromColor(color)
          .withLightness(0.3 + (0.4 * index / data.length))
          .toColor(),
    );

    // Bar gruplarını oluştur
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final double value = (item[yKey] as num).toDouble();

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: value,
              color: barColors[i % barColors.length],
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, right: 16, bottom: 24),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: data.isEmpty
              ? 10.0
              : data
                      .map<double>((item) => (item[yKey] as num).toDouble())
                      .reduce((double a, double b) => a > b ? a : b) *
                  1.2,
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value < 0 || value >= data.length) {
                    return const SizedBox.shrink();
                  }

                  final String title = data[value.toInt()][xKey] as String;

                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  String text = value.toInt().toString();
                  if (isCurrency) {
                    text = '$text ₺';
                  }

                  return Text(
                    text,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  );
                },
                reservedSize: 40,
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: const FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
          ),
          borderData: FlBorderData(
            show: false,
          ),
          barGroups: barGroups,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 8,
              getTooltipItem: (BarChartGroupData group, int groupIndex,
                  BarChartRodData rod, int rodIndex) {
                final value = rod.toY;
                return BarTooltipItem(
                  isCurrency
                      ? '${value.toStringAsFixed(0)} ₺'
                      : value.toStringAsFixed(0),
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    // fl_chart kütüphanesini kullanarak pie chart oluştur

    // Toplam değeri hesapla
    final double total = data.isEmpty
        ? 0.0
        : data
            .map<double>((item) => (item[yKey] as num).toDouble())
            .reduce((double a, double b) => a + b);

    // Renk listesi oluştur
    final List<Color> colors = List.generate(
      data.length,
      (index) => HSLColor.fromColor(color)
          .withHue((HSLColor.fromColor(color).hue + (index * 30) % 360))
          .withLightness(0.4 + (0.1 * index % 4))
          .toColor(),
    );

    // Pie chart sektörlerini oluştur
    final List<PieChartSectionData> sections = [];

    if (data.isEmpty || total <= 0) {
      // Veri yoksa veya toplam sıfırsa boş bir daire göster
      sections.add(
        PieChartSectionData(
          color: Colors.grey.shade300,
          value: 100,
          title: 'Veri Yok',
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
      );
    } else {
      for (int i = 0; i < data.length; i++) {
        final item = data[i];
        final double value = (item[yKey] as num).toDouble();
        final double percentage = (value / total) * 100;

        sections.add(
          PieChartSectionData(
            color: colors[i % colors.length],
            value: value,
            title: '${percentage.toStringAsFixed(1)}%',
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      }
    }

    return Row(
      children: [
        // Pie chart
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 0,
              sectionsSpace: 2,
              pieTouchData: PieTouchData(
                enabled: true,
                touchCallback:
                    (FlTouchEvent event, PieTouchResponse? pieTouchResponse) {
                  // Dokunma işlemleri için gerekirse burada kod eklenebilir
                },
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
            children: data.isEmpty || total <= 0
                ? [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'Veri bulunamadı',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  ]
                : List.generate(data.length, (index) {
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
                              color: colors[index % colors.length],
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
