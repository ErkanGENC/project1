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

        // Mevcut kullanıcı bilgilerini al
        final currentUser = await _apiService.getCurrentUser();

        if (currentUser == null) {
          // Kullanıcı bilgileri alınamadı
          setState(() {
            _isLoading = false;
            _errorMessage = 'Kullanıcı bilgileri alınamadı';
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Kullanıcı bilgileri alınamadı, lütfen tekrar deneyin'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Kullanıcı rolünü kontrol et
        final role = currentUser.role.toLowerCase();

        // Debug için rol bilgisini yazdır
        print('LOGIN - Kullanıcı rolü: $role');

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

            // Yönlendirme mesajı göster
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Admin paneline yönlendiriliyor...'),
                backgroundColor: Colors.purple,
              ),
            );
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

  // İlk admin kullanıcısı oluşturma dialog'u
  void _showCreateFirstAdminDialog(BuildContext context) {
    bool isLoading = false;
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController fullNameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('İlk Admin Kullanıcısı Oluştur'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: ListBody(
                    children: <Widget>[
                      const Text(
                        'Bu işlem, sistemdeki ilk admin kullanıcısını oluşturacaktır.',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: fullNameController,
                        decoration: const InputDecoration(
                          labelText: 'Ad Soyad',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen ad soyad girin';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'E-posta',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen e-posta girin';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return 'Geçerli bir e-posta adresi girin';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Şifre',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen şifre girin';
                          }
                          if (value.length < 6) {
                            return 'Şifre en az 6 karakter olmalıdır';
                          }
                          return null;
                        },
                      ),
                      if (isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 16.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop();
                        },
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          // Form doğrulama
                          if (formKey.currentState!.validate()) {
                            // Yükleniyor durumunu güncelle
                            setState(() {
                              isLoading = true;
                            });

                            // Admin kullanıcı verilerini hazırla
                            final adminData = {
                              'email': emailController.text,
                              'password': passwordController.text,
                              'fullName': fullNameController.text,
                              'role': 'admin',
                            };

                            try {
                              // API isteğini yap
                              final result =
                                  await _apiService.createFirstAdmin(adminData);

                              // Sonuç mesajını hazırla
                              final String message =
                                  result['message'] ?? 'İşlem tamamlandı';
                              final bool success = result['success'] ?? false;

                              // Dialog'u kapat
                              if (dialogContext.mounted) {
                                Navigator.of(dialogContext).pop();
                              }

                              // Sonucu göster
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(message),
                                    backgroundColor:
                                        success ? Colors.green : Colors.red,
                                    duration:
                                        Duration(seconds: success ? 5 : 3),
                                  ),
                                );
                              }
                            } catch (error) {
                              // Yükleniyor durumunu güncelle
                              setState(() {
                                isLoading = false;
                              });

                              // Hata mesajını göster
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Bir hata oluştu: $error'),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            }
                          }
                        },
                  child: const Text('Oluştur'),
                ),
              ],
            );
          },
        );
      },
    );
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

                  // İlk admin kullanıcısı oluşturma butonu (sadece geliştirme aşamasında)
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {
                      _showCreateFirstAdminDialog(context);
                    },
                    icon: const Icon(Icons.admin_panel_settings, size: 16),
                    label: const Text('İlk Admin Kullanıcısı Oluştur'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
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
