import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'constants/app_theme.dart';
import 'routes/app_routes.dart';
import 'services/api_service.dart';
import 'services/theme_service.dart';

// Ana uygulama başlangıç noktası
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // API servisinin platform ayarlarını yapılandır
  ApiService.configurePlatformSpecificUrl();

  // Debug için API URL'yi yazdır
  print('API URL: ${ApiService.baseUrl}');

  // ThemeService'i oluştur ve ayarları yükle
  final themeService = ThemeService();
  themeService.loadSettings();

  runApp(
    ChangeNotifierProvider<ThemeService>.value(
      value: themeService,
      child: const MyApp(),
    ),
  );
}

// Ana uygulama widget'ı
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ThemeService'den tema bilgilerini al
    final themeService = Provider.of<ThemeService>(context);

    return MaterialApp(
      title: 'Ağız ve Diş Sağlığı Takip',
      debugShowCheckedModeBanner: false, // Debug etiketini kaldır
      theme: themeService.theme, // ThemeService'den gelen temayı kullan
      initialRoute:
          AppRoutes.login, // Başlangıç sayfasını giriş ekranı olarak belirle
      routes: AppRoutes.routes, // Uygulama rotalarını tanımla
    );
  }
}
