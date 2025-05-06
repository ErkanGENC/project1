import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';

/// Gizlilik politikası ekranı
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gizlilik Politikası'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            const Center(
              child: Icon(
                Icons.privacy_tip_outlined,
                size: 64,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Gizlilik Politikası',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Son Güncelleme: 1 Haziran 2023',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.secondaryTextColor,
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Giriş
            _buildSection(
              'Giriş',
              'Bu gizlilik politikası, Ağız ve Diş Sağlığı Takip uygulamasını kullanırken toplanan, işlenen ve saklanan kişisel verilerinizle ilgili bilgileri içerir. Uygulamayı kullanarak bu politikada belirtilen şartları kabul etmiş olursunuz.',
            ),
            
            // Toplanan Veriler
            _buildSection(
              'Toplanan Veriler',
              'Uygulamamız, size daha iyi hizmet sunabilmek için aşağıdaki verileri toplar:\n\n'
              '• Kişisel Bilgiler: Ad, soyad, e-posta adresi, telefon numarası\n'
              '• Sağlık Bilgileri: Diş sağlığı durumu, tedavi geçmişi, randevu bilgileri\n'
              '• Kullanım Verileri: Uygulama içi aktiviteler, tercihler, ayarlar\n'
              '• Cihaz Bilgileri: Cihaz türü, işletim sistemi, uygulama versiyonu',
            ),
            
            // Verilerin Kullanımı
            _buildSection(
              'Verilerin Kullanımı',
              'Topladığımız verileri aşağıdaki amaçlar için kullanırız:\n\n'
              '• Hesabınızı oluşturmak ve yönetmek\n'
              '• Size özel sağlık hizmetleri sunmak\n'
              '• Randevularınızı planlamak ve hatırlatmak\n'
              '• Diş sağlığı takibinizi yapmak\n'
              '• Uygulamayı geliştirmek ve iyileştirmek\n'
              '• Teknik sorunları çözmek ve destek sağlamak',
            ),
            
            // Veri Güvenliği
            _buildSection(
              'Veri Güvenliği',
              'Kişisel verilerinizin güvenliği bizim için önemlidir. Verilerinizi korumak için endüstri standardı güvenlik önlemleri alıyoruz. Ancak, internet üzerinden hiçbir veri iletiminin %100 güvenli olmadığını unutmayın.',
            ),
            
            // Veri Paylaşımı
            _buildSection(
              'Veri Paylaşımı',
              'Kişisel verilerinizi aşağıdaki durumlar dışında üçüncü taraflarla paylaşmıyoruz:\n\n'
              '• Yasal zorunluluk durumunda\n'
              '• Sizin açık izniniz olduğunda\n'
              '• Hizmet sağlayıcılarımızla (sadece hizmet sunmak amacıyla)\n'
              '• Şirket birleşmesi veya satın alınması durumunda',
            ),
            
            // Çerezler ve Takip Teknolojileri
            _buildSection(
              'Çerezler ve Takip Teknolojileri',
              'Uygulamamız, deneyiminizi iyileştirmek için çerezler ve benzer takip teknolojileri kullanabilir. Bu teknolojiler, tercihlerinizi hatırlamak ve uygulama kullanımınızı analiz etmek için kullanılır.',
            ),
            
            // Çocukların Gizliliği
            _buildSection(
              'Çocukların Gizliliği',
              'Hizmetlerimiz 13 yaşın altındaki çocuklara yönelik değildir. 13 yaşın altındaki çocuklardan bilerek kişisel veri toplamıyoruz. Eğer 13 yaşın altındaki bir çocuğa ait veri topladığımızı fark edersek, bu verileri derhal silmek için adımlar atarız.',
            ),
            
            // Haklarınız
            _buildSection(
              'Haklarınız',
              'Kişisel verilerinizle ilgili aşağıdaki haklara sahipsiniz:\n\n'
              '• Verilerinize erişim hakkı\n'
              '• Verilerinizi düzeltme hakkı\n'
              '• Verilerinizin silinmesini talep etme hakkı\n'
              '• Veri işlemeye itiraz etme hakkı\n'
              '• Veri taşınabilirliği hakkı',
            ),
            
            // Politika Değişiklikleri
            _buildSection(
              'Politika Değişiklikleri',
              'Bu gizlilik politikasını zaman zaman güncelleyebiliriz. Değişiklikler yapıldığında, uygulama içinde bildirim yayınlayacağız ve politikanın güncellenmiş versiyonunu web sitemizde yayınlayacağız.',
            ),
            
            // İletişim
            _buildSection(
              'İletişim',
              'Bu gizlilik politikası hakkında sorularınız veya endişeleriniz varsa, lütfen aşağıdaki iletişim bilgilerini kullanarak bize ulaşın:\n\n'
              'E-posta: privacy@dentalhealthapp.com\n'
              'Telefon: +90 212 123 4567\n'
              'Adres: Örnek Mahallesi, Örnek Sokak No:1, İstanbul, Türkiye',
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textColor,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
