import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';

class DentalHealthTips extends StatelessWidget {
  const DentalHealthTips({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ağız Sağlığı İpuçları',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildTipItem(
              context,
              'Günde en az iki kez dişlerinizi fırçalayın',
              'Sabah ve akşam en az 2 dakika boyunca dişlerinizi fırçalamak, diş çürüklerini ve diş eti hastalıklarını önlemenin en etkili yoludur.',
              Icons.brush,
              AppTheme.primaryColor,
            ),
            const Divider(),
            _buildTipItem(
              context,
              'Diş ipi kullanmayı ihmal etmeyin',
              'Diş ipi, diş fırçasının ulaşamadığı diş aralarındaki plakları temizler ve diş eti sağlığını korur.',
              Icons.linear_scale,
              AppTheme.accentColor,
            ),
            const Divider(),
            _buildTipItem(
              context,
              'Düzenli diş hekimi kontrollerine gidin',
              'Altı ayda bir diş hekimi kontrolü, erken teşhis ve tedavi için önemlidir.',
              Icons.medical_services,
              Colors.purple,
            ),
            const Divider(),
            _buildTipItem(
              context,
              'Şekerli yiyecek ve içecekleri sınırlayın',
              'Şeker, diş çürüklerine neden olan bakterilerin beslenmesini sağlar. Şekerli gıdaları azaltmak diş sağlığınızı korur.',
              Icons.no_food,
              Colors.orange,
            ),
            const Divider(),
            _buildTipItem(
              context,
              'Ağız gargarası kullanın',
              'Antimikrobiyal ağız gargaraları, diş fırçalama ve diş ipi kullanımına ek olarak ağız hijyenini destekler.',
              Icons.local_drink,
              Colors.teal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DentalProblemInfo extends StatelessWidget {
  const DentalProblemInfo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sık Görülen Ağız Problemleri',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildProblemItem(
              context,
              'Diş Çürükleri',
              'Diş yüzeyinde oluşan plak ve bakterilerin neden olduğu, diş dokusunun hasar görmesidir.',
              'Belirtiler: Diş ağrısı, dişte hassasiyet, dişte görünür delikler.',
              Colors.red,
            ),
            const Divider(),
            _buildProblemItem(
              context,
              'Diş Eti Hastalığı (Gingivitis)',
              'Diş etlerinin iltihaplanmasıdır. Tedavi edilmezse periodontitis adı verilen daha ciddi bir hastalığa dönüşebilir.',
              'Belirtiler: Kızarık, şiş diş etleri, diş eti kanaması, ağız kokusu.',
              Colors.orange,
            ),
            const Divider(),
            _buildProblemItem(
              context,
              'Diş Hassasiyeti',
              'Sıcak, soğuk, tatlı veya ekşi yiyecek ve içeceklere karşı dişlerde oluşan ağrı veya rahatsızlık hissidir.',
              'Belirtiler: Belirli yiyecek ve içeceklere maruz kalındığında ani, keskin ağrı.',
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProblemItem(
    BuildContext context,
    String title,
    String description,
    String symptoms,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  symptoms,
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
