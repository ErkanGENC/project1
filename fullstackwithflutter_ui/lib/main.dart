import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'constants/app_theme.dart';
import 'routes/app_routes.dart';
import 'services/api_service.dart';
import 'services/theme_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  ApiService.configurePlatformSpecificUrl();

  print('API URL: ${ApiService.baseUrl}');

  final themeService = ThemeService();
  themeService.loadSettings();

  runApp(
    ChangeNotifierProvider<ThemeService>.value(
      value: themeService,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return MaterialApp(
      title: 'Ağız ve Diş Sağlığı Takip',
      debugShowCheckedModeBanner: false,
      theme: themeService.theme,
      initialRoute: AppRoutes.login,
      routes: AppRoutes.routes,
    );
  }
}
