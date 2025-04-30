import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';

/// Şifre sıfırlama ekranı
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;
  bool _isEmailSent = false;
  bool _isUserFound = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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

  // E-posta kontrolü
  Future<void> _checkEmail() async {
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
      final result = await _apiService.forgotPassword(email);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isUserFound = result['success'];

        if (!result['success']) {
          _errorMessage = result['message'];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          // Kullanıcı bulundu, şifre sıfırlama formunu göster
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Kullanıcı bulundu. Lütfen yeni şifrenizi belirleyin.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      });
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

  // Şifre sıfırlama
  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // API isteği
      final email = _emailController.text.trim();
      final newPassword = _passwordController.text;

      final result = await _apiService.resetPassword(
        email: email,
        newPassword: newPassword,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        // Başarılı sıfırlama
        setState(() {
          _isEmailSent = true;
        });
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
      appBar: AppBar(
        title: const Text('Şifremi Unuttum'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: _isEmailSent ? _buildSuccessContent() : _buildResetForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildResetForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // İkon ve başlık
          const Icon(
            Icons.lock_reset,
            size: 80,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 24),
          const Text(
            'Şifrenizi mi unuttunuz?',
            style: AppTheme.headingStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Endişelenmeyin! E-posta adresinizi girin ve size şifre sıfırlama bağlantısı gönderelim.',
            style: AppTheme.captionStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // E-posta alanı
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            enabled: !_isUserFound, // Kullanıcı bulunduysa devre dışı bırak
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
          const SizedBox(height: 16),

          // Kullanıcı bulunduysa şifre alanlarını göster
          if (_isUserFound) ...[
            // Yeni şifre alanı
            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Yeni Şifre',
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
                if (_isUserFound) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen yeni şifrenizi girin';
                  }
                  if (!_isPasswordStrong(value)) {
                    return 'Şifre en az 8 karakter uzunluğunda olmalı ve en az bir büyük harf, bir küçük harf ve bir rakam içermelidir';
                  }
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
                labelText: 'Yeni Şifre Tekrar',
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
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (_isUserFound) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen şifrenizi tekrar girin';
                  }
                  if (value != _passwordController.text) {
                    return 'Şifreler eşleşmiyor';
                  }
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 24),

          // Sıfırlama butonu
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _isUserFound ? _resetPassword : _checkEmail,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    _isUserFound
                        ? 'Yeni Şifreyi Kaydet'
                        : 'E-posta Adresini Doğrula',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
          const SizedBox(height: 16),

          // Giriş sayfasına dön
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Giriş sayfasına dön'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Başarılı ikonu
        const Icon(
          Icons.check_circle_outline,
          size: 80,
          color: Colors.green,
        ),
        const SizedBox(height: 24),
        const Text(
          'E-posta Gönderildi!',
          style: AppTheme.headingStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Şifre sıfırlama bağlantısı ${_emailController.text} adresine gönderildi. Lütfen e-postanızı kontrol edin ve bağlantıya tıklayarak şifrenizi sıfırlayın.',
          style: AppTheme.bodyStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            'Giriş Sayfasına Dön',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
