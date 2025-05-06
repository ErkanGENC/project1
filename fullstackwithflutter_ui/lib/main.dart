import 'package:flutter/material.dart';
import 'constants/app_theme.dart';
import 'routes/app_routes.dart';
import 'services/api_service.dart';

// Ana uygulama başlangıç noktası
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // API servisinin platform ayarlarını yapılandır
  ApiService.configurePlatformSpecificUrl();

  // Debug için API URL'yi yazdır
  print('API URL: ${ApiService.baseUrl}');

  runApp(const MyApp());
}

// Ana uygulama widget'ı
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ağız ve Diş Sağlığı Takip',
      debugShowCheckedModeBanner: false, // Debug etiketini kaldır
      theme: AppTheme.lightTheme, // Uygulama temasını ayarla
      initialRoute:
          AppRoutes.login, // Başlangıç sayfasını giriş ekranı olarak belirle
      routes: AppRoutes.routes, // Uygulama rotalarını tanımla
    );
  }
}
