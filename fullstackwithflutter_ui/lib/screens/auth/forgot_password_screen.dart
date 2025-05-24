import 'dart:async';
import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ForgotPasswordScreenState createState() => ForgotPasswordScreenState();
}

class ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _resetCodeController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;
  bool _isResendLoading = false;
  bool _isEmailSent = false;
  bool _isCodeVerified = false;
  bool _isResetComplete = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String _errorMessage = '';

  int _currentStep = 1;

  int _resendCountdown = 0;
  Timer? _resendTimer;

  String? _debugResetCode;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _resetCodeController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendCountdown = 30;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          _resendTimer?.cancel();
        }
      });
    });
  }

  Future<void> _resendResetCode() async {
    if (_isResendLoading) return;

    setState(() {
      _isResendLoading = true;
      _errorMessage = '';
    });

    try {
      final email = _emailController.text.trim();
      final result = await _apiService.sendPasswordResetEmail(email);

      if (!mounted) return;

      setState(() {
        _isResendLoading = false;
      });

      if (result['success']) {
        _startResendTimer();

        if (result['message'] != null &&
            result['message'].toString().contains('DOĞRULAMA KODU:')) {
          final String message = result['message'].toString();
          final RegExp regex = RegExp(r'DOĞRULAMA KODU: (\d+)');
          final match = regex.firstMatch(message);
          if (match != null && match.groupCount >= 1) {
            setState(() {
              _debugResetCode = match.group(1);
            });
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                result['message'] ?? 'Şifre sıfırlama kodu tekrar gönderildi'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _errorMessage = result['message'] ??
            'Şifre sıfırlama kodu gönderilirken bir hata oluştu';
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
        _isResendLoading = false;
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

  bool _isPasswordStrong(String password) {
    if (password.length < 8) return false;

    if (!password.contains(RegExp(r'[A-Z]'))) return false;

    if (!password.contains(RegExp(r'[a-z]'))) return false;

    if (!password.contains(RegExp(r'[0-9]'))) return false;

    return true;
  }

  Future<void> _sendResetCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final email = _emailController.text.trim();
      final result = await _apiService.sendPasswordResetEmail(email);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        setState(() {
          _isEmailSent = true;
          _currentStep = 2;
        });

        _startResendTimer();

        if (result['message'] != null &&
            result['message'].toString().contains('DOĞRULAMA KODU:')) {
          final String message = result['message'].toString();
          final RegExp regex = RegExp(r'DOĞRULAMA KODU: (\d+)');
          final match = regex.firstMatch(message);
          if (match != null && match.groupCount >= 1) {
            setState(() {
              _debugResetCode = match.group(1);
            });
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ??
                'Şifre sıfırlama kodu e-posta adresinize gönderildi'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _errorMessage = result['message'] ??
            'Şifre sıfırlama kodu gönderilirken bir hata oluştu';
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

  Future<void> _verifyResetCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final email = _emailController.text.trim();
      final resetCode = _resetCodeController.text.trim();

      final result = await _apiService.verifyResetCode(email, resetCode);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        setState(() {
          _isCodeVerified = true;
          _currentStep = 3;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ??
                'Kod doğrulandı. Şimdi yeni şifrenizi belirleyebilirsiniz.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _errorMessage =
            result['message'] ?? 'Kod doğrulanırken bir hata oluştu';
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

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final email = _emailController.text.trim();
      final resetCode = _resetCodeController.text.trim();
      final newPassword = _passwordController.text;

      final result = await _apiService.resetPasswordWithToken(
        email: email,
        resetCode: resetCode,
        newPassword: newPassword,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        setState(() {
          _isResetComplete = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Şifre başarıyla sıfırlandı'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _errorMessage =
            result['message'] ?? 'Şifre sıfırlama sırasında bir hata oluştu';
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
      appBar: AppBar(
        title: const Text('Şifremi Unuttum'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child:
                _isResetComplete ? _buildSuccessContent() : _buildResetForm(),
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
          Text(
            _currentStep == 1
                ? 'Endişelenmeyin! Kayıtlı e-posta adresinizi girin ve size şifre sıfırlama kodu gönderelim.'
                : _currentStep == 2
                    ? 'E-posta adresinize gönderilen 6 haneli doğrulama kodunu girin. Spam klasörünü de kontrol etmeyi unutmayın.'
                    : 'Şimdi yeni şifrenizi belirleyin.',
            style: AppTheme.captionStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (_currentStep == 1) ...[
            TextFormField(
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
          ],
          if (_currentStep == 2) ...[
            TextFormField(
              controller: _emailController,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'E-posta',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _resetCodeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'Doğrulama Kodu',
                hintText: '123456',
                prefixIcon: const Icon(Icons.pin_outlined),
                border: const OutlineInputBorder(),
                helperText: _debugResetCode != null
                    ? 'Geliştirme modu: Kod: $_debugResetCode'
                    : null,
                helperStyle: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Lütfen doğrulama kodunu girin';
                }
                if (value.length != 6 || !RegExp(r'^\d{6}$').hasMatch(value)) {
                  return 'Geçerli bir 6 haneli kod girin';
                }
                return null;
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _resendCountdown > 0 || _isResendLoading
                    ? null
                    : _resendResetCode,
                icon: _isResendLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.refresh, size: 14),
                label: Text(
                  _resendCountdown > 0
                      ? 'Tekrar gönder ($_resendCountdown)'
                      : 'Kodu tekrar gönder',
                  style: TextStyle(
                    color: _resendCountdown > 0 || _isResendLoading
                        ? Colors.grey
                        : Theme.of(context).primaryColor,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 0),
                  minimumSize: const Size(0, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
          if (_currentStep == 3) ...[
            TextFormField(
              controller: _emailController,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'E-posta',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _resetCodeController,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Doğrulama Kodu',
                prefixIcon: Icon(Icons.pin_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
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
                if (value == null || value.isEmpty) {
                  return 'Lütfen yeni şifrenizi girin';
                }
                if (!_isPasswordStrong(value)) {
                  return 'Şifre en az 8 karakter uzunluğunda olmalı ve en az bir büyük harf, bir küçük harf ve bir rakam içermelidir';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
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
                if (value == null || value.isEmpty) {
                  return 'Lütfen şifrenizi tekrar girin';
                }
                if (value != _passwordController.text) {
                  return 'Şifreler eşleşmiyor';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 24),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: () {
                    if (_currentStep == 1) {
                      _sendResetCode();
                    } else if (_currentStep == 2) {
                      _verifyResetCode();
                    } else {
                      _resetPassword();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    _currentStep == 1
                        ? 'Doğrulama Kodu Gönder'
                        : _currentStep == 2
                            ? 'Kodu Doğrula'
                            : 'Şifreyi Sıfırla',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
          const SizedBox(height: 16),
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
        const Icon(
          Icons.check_circle_outline,
          size: 80,
          color: Colors.green,
        ),
        const SizedBox(height: 24),
        const Text(
          'Şifre Başarıyla Sıfırlandı!',
          style: AppTheme.headingStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'Şifreniz başarıyla sıfırlandı. Artık yeni şifrenizle giriş yapabilirsiniz.',
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
            backgroundColor: AppTheme.primaryColor,
          ),
          child: const Text(
            'Giriş Sayfasına Dön',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
