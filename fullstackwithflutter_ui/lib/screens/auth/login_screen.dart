import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';
import 'dart:async';

/// Kullanıcı giriş ekranı
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Giriş işlemi
  Future<void> _login() async {
    // Form doğrulama
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // API isteği
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final result = await _apiService.login(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (result['success']) {
        // Başarılı giriş
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );

        // Kullanıcı rolünü kontrol et
        Map<String, dynamic> userData = {};

        // Debug için tüm yanıtı yazdır
        print('LOGIN - Tüm yanıt: $result');

        // API yanıt formatını kontrol et - iç içe yapıları kontrol et
        if (result['data'] != null) {
          if (result['data'] is Map) {
            // Yeni API formatı: data -> data -> user
            if (result['data']['data'] != null &&
                result['data']['data'] is Map) {
              if (result['data']['data']['user'] != null &&
                  result['data']['data']['user'] is Map) {
                userData =
                    Map<String, dynamic>.from(result['data']['data']['user']);
                print('LOGIN - Kullanıcı verisi (data->data->user): $userData');
              }
            }
            // Eski API formatı: data -> user
            else if (result['data']['user'] != null &&
                result['data']['user'] is Map) {
              userData = Map<String, dynamic>.from(result['data']['user']);
              print('LOGIN - Kullanıcı verisi (data->user): $userData');
            }
            // Düz data
            else {
              userData = Map<String, dynamic>.from(result['data']);
              print('LOGIN - Kullanıcı verisi (data): $userData');
            }
          }
        }

        // Rol bilgisini direkt al
        String role = 'user'; // Varsayılan rol

        // API'den dönen role doğrudan kontrol et
        if (userData.containsKey('role') &&
            userData['role'] != null &&
            userData['role'].toString().isNotEmpty) {
          role = userData['role'].toString().toLowerCase();
          print('LOGIN - API\'den gelen rol: $role');
        }

        // Sadece API'den gelen role değerine göre işlem yap
        // Kullanıcı verilerini güncelle
        await _apiService.saveUserData(userData);

        // Debug için rol bilgisini yazdır
        print('LOGIN - Kullanıcı rolü: $role');

        print('LOGIN - Son belirlenen rol: $role');

        // Role göre yönlendirme yap
        if (role == 'doctor') {
          print(
              'LOGIN - Doktor rolü tespit edildi, doctor_dashboard sayfasına yönlendiriliyor...');

          // Doktor dashboard'a yönlendir
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.doctorDashboard,
            );

            // Yönlendirme mesajı göster
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Doktor paneline yönlendiriliyor...'),
                backgroundColor: Colors.blue,
              ),
            );
          }
        } else if (role == 'admin') {
          print(
              'LOGIN - Admin rolü tespit edildi, admin_dashboard sayfasına yönlendiriliyor...');
          if (mounted) {
            Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
          }
        } else {
          print(
              'LOGIN - Normal kullanıcı rolü tespit edildi, welcome sayfasına yönlendiriliyor...');
          if (mounted) {
            Navigator.pushReplacementNamed(context, AppRoutes.welcome);
          }
        }
      } else {
        // Hatalı giriş
        setState(() {
          _isLoading = false;
          _errorMessage = result['message'];
        });

        // Hata mesajını göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Bir hata oluştu: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo ve başlık
                  const Icon(
                    Icons.medical_services_outlined,
                    size: 80,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Ağız ve Diş Sağlığı Takip',
                    style: AppTheme.headingStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Hesabınıza giriş yapın',
                    style: AppTheme.captionStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // E-posta alanı
                  SizedBox(
                    width: double.infinity,
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-posta',
                        hintText: 'ornek@mail.com',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen e-posta adresinizi girin';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return 'Geçerli bir e-posta adresi girin';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Şifre alanı
                  SizedBox(
                    width: double.infinity,
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Şifre',
                        hintText: '********',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen şifrenizi girin';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Beni hatırla ve şifremi unuttum
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                            ),
                            const Flexible(
                              child: Text(
                                'Beni hatırla',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(
                              context, AppRoutes.forgotPassword);
                        },
                        child: const Text('Şifremi Unuttum'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Giriş butonu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Giriş Yap',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Kayıt ol yönlendirmesi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Flexible(
                        child: Text(
                          'Hesabınız yok mu?',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.register);
                        },
                        child: const Text('Kayıt Ol'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
