import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';
import 'dart:async';

/// Kullanıcı kayıt ekranı
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  RegisterScreenState createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _apiService = ApiService();
  DateTime? _birthDate;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _acceptTerms = false;
  bool _isLoading = false;
  bool _isEmailChecking = false;
  bool _isEmailAvailable = true;
  String _emailErrorMessage = '';

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // E-posta adresinin kullanılabilirliğini kontrol et
  Future<void> _checkEmailAvailability(String email) async {
    if (email.isEmpty ||
        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return;
    }

    setState(() {
      _isEmailChecking = true;
      _isEmailAvailable = true;
      _emailErrorMessage = '';
    });

    try {
      // Burada normalde API'ye istek atılmalı
      // Şimdilik basit bir kontrol yapıyoruz
      // Gerçek bir API entegrasyonunda, e-posta kontrolü için endpoint oluşturulmalı

      // API isteği simülasyonu
      await Future.delayed(const Duration(seconds: 1));

      // Örnek olarak test@test.com adresinin kullanıldığını varsayalım
      final bool isAvailable = email.toLowerCase() != 'test@test.com';

      if (!mounted) return;

      setState(() {
        _isEmailChecking = false;
        _isEmailAvailable = isAvailable;
        _emailErrorMessage =
            isAvailable ? '' : 'Bu e-posta adresi zaten kullanılıyor';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isEmailChecking = false;
        _isEmailAvailable = false;
        _emailErrorMessage = 'E-posta kontrolü sırasında bir hata oluştu: $e';
      });
    }
  }

  // Şifre güvenlik kontrolü
  bool _isPasswordStrong(String password) {
    // En az 8 karakter
    if (password.length < 8) return false;

    // En az bir büyük harf
    if (!password.contains(RegExp(r'[A-Z]'))) return false;

    // En az bir küçük harf
    if (!password.contains(RegExp(r'[a-z]'))) return false;

    // En az bir rakam
    if (!password.contains(RegExp(r'[0-9]'))) return false;

    return true;
  }

  // Doğum tarihi seçici
  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Doğum Tarihinizi Seçin',
      cancelText: 'İptal',
      confirmText: 'Tamam',
      fieldLabelText: 'Doğum Tarihi',
      fieldHintText: 'GG/AA/YYYY',
      errorFormatText: 'Geçerli bir tarih girin',
      errorInvalidText: 'Geçerli bir tarih aralığı girin',
    );

    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  // Kayıt işlemi
  Future<void> _register() async {
    // Form doğrulama
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Doğum tarihi kontrolü
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen doğum tarihinizi seçin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Kullanım koşulları kontrolü
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen kullanım koşullarını kabul edin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // E-posta kullanılabilirlik kontrolü
    if (!_isEmailAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_emailErrorMessage),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // API isteği
      final result = await _apiService.register(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        birthDate: _birthDate!,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        // Başarılı kayıt
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );

        // Eğer API token ve kullanıcı bilgilerini döndürdüyse, otomatik giriş yap
        if (result['data'] != null && result['data'] is Map) {
          final data = result['data'] as Map<String, dynamic>;

          if (data.containsKey('token')) {
            // Token'i kaydet
            await _apiService.saveToken(data['token']);

            // Kullanıcı bilgilerini kaydet
            if (data.containsKey('user')) {
              await _apiService
                  .saveUserData(data['user'] as Map<String, dynamic>);
            }

            // Ana sayfaya yönlendir
            if (mounted) {
              Navigator.pushReplacementNamed(context, AppRoutes.home);
              return;
            }
          }
        }

        // Token yoksa giriş sayfasına yönlendir
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      } else {
        // Hata durumu
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bir hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kayıt Ol'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Başlık
                  const Text(
                    'Yeni Hesap Oluştur',
                    style: AppTheme.headingStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ağız ve diş sağlığınızı takip etmek için hesap oluşturun',
                    style: AppTheme.captionStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Ad Soyad alanı
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Ad Soyad',
                      hintText: 'Adınız ve soyadınız',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen adınızı ve soyadınızı girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // E-posta alanı
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'E-posta',
                      hintText: 'ornek@mail.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: const OutlineInputBorder(),
                      suffixIcon: _isEmailChecking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : _emailErrorMessage.isNotEmpty
                              ? const Icon(Icons.error, color: Colors.red)
                              : _emailController.text.isNotEmpty
                                  ? const Icon(Icons.check_circle,
                                      color: Colors.green)
                                  : null,
                    ),
                    onChanged: (value) {
                      // E-posta değiştiğinde hata mesajını temizle
                      if (_emailErrorMessage.isNotEmpty) {
                        setState(() {
                          _emailErrorMessage = '';
                          _isEmailAvailable = true;
                        });
                      }
                    },
                    onEditingComplete: () {
                      // Odak kaybedildiğinde e-posta kontrolü yap
                      if (_emailController.text.isNotEmpty) {
                        _checkEmailAvailability(_emailController.text);
                      }
                      FocusScope.of(context).nextFocus();
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen e-posta adresinizi girin';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'Geçerli bir e-posta adresi girin';
                      }
                      if (!_isEmailAvailable) {
                        return _emailErrorMessage;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Doğum tarihi alanı
                  InkWell(
                    onTap: _selectBirthDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Doğum Tarihi',
                        hintText: 'Doğum tarihinizi seçin',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _birthDate == null
                                ? 'Doğum tarihinizi seçin'
                                : '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
                            style: TextStyle(
                              color: _birthDate == null
                                  ? Colors.grey.shade600
                                  : Colors.black,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Şifre alanı
                  TextFormField(
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
                      if (!_isPasswordStrong(value)) {
                        return 'Şifre en az 8 karakter uzunluğunda olmalı ve en az bir büyük harf, bir küçük harf ve bir rakam içermelidir';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Şifre tekrar alanı
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Şifre Tekrar',
                      hintText: '********',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen şifrenizi tekrar girin';
                      }
                      if (value != _passwordController.text) {
                        return 'Şifreler eşleşmiyor';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Kullanım koşulları
                  Row(
                    children: [
                      Checkbox(
                        value: _acceptTerms,
                        onChanged: (value) {
                          setState(() {
                            _acceptTerms = value ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _acceptTerms = !_acceptTerms;
                            });
                          },
                          child: const Text(
                            'Kullanım koşullarını ve gizlilik politikasını kabul ediyorum',
                            style: AppTheme.captionStyle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Kayıt ol butonu
                  ElevatedButton(
                    onPressed: _isLoading ? null : _register,
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
                            'Kayıt Ol',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Giriş yap yönlendirmesi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Zaten hesabınız var mı?'),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(
                              context, AppRoutes.login);
                        },
                        child: const Text('Giriş Yap'),
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
