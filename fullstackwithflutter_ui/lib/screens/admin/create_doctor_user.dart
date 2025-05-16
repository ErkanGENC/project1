import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../constants/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/doctor_model.dart';

class CreateDoctorUserScreen extends StatefulWidget {
  const CreateDoctorUserScreen({super.key});

  @override
  CreateDoctorUserScreenState createState() => CreateDoctorUserScreenState();
}

class CreateDoctorUserScreenState extends State<CreateDoctorUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _specializationController = TextEditingController();
  final _phoneController = TextEditingController();

  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String _errorMessage = '';
  DateTime _selectedBirthDate = DateTime.now()
      .subtract(const Duration(days: 365 * 30)); // Varsayılan 30 yaş

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _specializationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.textColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  Future<void> _createDoctorUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Şifre kontrolü
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Şifreler eşleşmiyor';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Doktor bilgilerini oluştur
      final doctor = Doctor(
        id: 0, // API tarafından atanacak
        name: _nameController.text,
        specialization: _specializationController.text,
        email: _emailController.text,
        phoneNumber: _phoneController.text,
        isAvailable: true,
      );

      // Doğrudan doktor oluştur - bu işlem hem Doctors tablosuna hem de AppUser tablosuna kayıt ekler
      final doctorResult = await _apiService.addDoctor(doctor);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (doctorResult['success']) {
          // Başarılı mesajı göster
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Doktor kullanıcısı başarıyla oluşturuldu'),
              backgroundColor: Colors.green,
            ),
          );

          // Eğer API'den doktor ID'si döndüyse, kullanıcının doctorId değerini güncelle
          if (doctorResult['data'] != null &&
              doctorResult['data'] is Map &&
              doctorResult['data'].containsKey('id')) {
            final int doctorId = doctorResult['data']['id'];

            // Debug için yazdır
            debugPrint('Doktor ID: $doctorId');

            // Şimdi doktor kullanıcısı için şifre ayarla
            final passwordResult = await _apiService.register(
              fullName: _nameController.text,
              email: _emailController.text,
              password: _passwordController.text,
              birthDate: _selectedBirthDate,
              role: 'doctor',
              specialization: _specializationController.text,
              doctorId: doctorId,
              doctorName: _nameController.text,
            );

            if (passwordResult['success']) {
              // Başarılı mesajı göster
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Doktor şifresi başarıyla ayarlandı'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } else {
              // Şifre ayarlama hatası
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Doktor şifresi ayarlanamadı: ${passwordResult['message']}'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
          }

          // Formu temizle
          _nameController.clear();
          _emailController.clear();
          _passwordController.clear();
          _confirmPasswordController.clear();
          _specializationController.clear();
          _phoneController.clear();

          // Önceki sayfaya dön
          if (mounted) {
            Navigator.pop(context);
          }
        } else {
          // Hata mesajı göster
          setState(() {
            _errorMessage = doctorResult['message'];
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doktor Kullanıcısı Oluştur'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hata mesajı
              if (_errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              // Ad Soyad
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ad Soyad alanı boş bırakılamaz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // E-posta
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'E-posta alanı boş bırakılamaz';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value)) {
                    return 'Geçerli bir e-posta adresi giriniz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Şifre
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Şifre',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Şifre alanı boş bırakılamaz';
                  }
                  if (value.length < 6) {
                    return 'Şifre en az 6 karakter olmalıdır';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Şifre Tekrar
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Şifre Tekrar',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Şifre tekrar alanı boş bırakılamaz';
                  }
                  if (value != _passwordController.text) {
                    return 'Şifreler eşleşmiyor';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Uzmanlık Alanı
              TextFormField(
                controller: _specializationController,
                decoration: const InputDecoration(
                  labelText: 'Uzmanlık Alanı',
                  prefixIcon: Icon(Icons.medical_services),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Uzmanlık alanı boş bırakılamaz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Telefon
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefon',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Telefon alanı boş bırakılamaz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Doğum Tarihi
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Doğum Tarihi',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    '${_selectedBirthDate.day}/${_selectedBirthDate.month}/${_selectedBirthDate.year}',
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Kaydet Butonu
              ElevatedButton(
                onPressed: _isLoading ? null : _createDoctorUser,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('DOKTOR KULLANICISI OLUŞTUR'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
