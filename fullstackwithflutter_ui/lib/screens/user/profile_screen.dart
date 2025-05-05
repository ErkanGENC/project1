import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';

/// Kullanıcı profil ekranı
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _apiService = ApiService();
  bool _isEditing = false;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Kullanıcı bilgilerini yükle
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Önce SharedPreferences'dan kullanıcı bilgilerini al
      final userData = await _apiService.getUserData();

      if (userData != null) {
        // Kullanıcı bilgileri varsa, form alanlarını doldur
        setState(() {
          _fullNameController.text = userData['fullName'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _phoneController.text = userData['phoneNumber'] ?? '';
          _isLoading = false;
        });
      } else {
        // Kullanıcı bilgileri yoksa, API'den al
        final result = await _apiService.getCurrentUser();

        if (result['success'] && result['data'] != null) {
          final data = result['data'];

          // API'den gelen veri yapısına göre bilgileri al
          String fullName = '';
          String email = '';
          String phoneNumber = '';

          if (data is Map) {
            fullName = data['fullName'] ?? data['name'] ?? '';
            email = data['email'] ?? '';
            phoneNumber = data['phoneNumber'] ?? data['phone'] ?? '';
          }

          // Form alanlarını doldur
          setState(() {
            _fullNameController.text = fullName;
            _emailController.text = email;
            _phoneController.text = phoneNumber;
            _isLoading = false;
          });

          // Kullanıcı bilgilerini kaydet
          await _apiService.saveUserData({
            'fullName': fullName,
            'email': email,
            'phoneNumber': phoneNumber,
          });
        } else {
          setState(() {
            _errorMessage =
                result['message'] ?? 'Kullanıcı bilgileri alınamadı';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Bir hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  // Profil avatarı oluştur
  Widget _buildProfileAvatar() {
    // Kullanıcı adının baş harflerini al
    String initials = '';
    if (_fullNameController.text.isNotEmpty) {
      final nameParts = _fullNameController.text.split(' ');
      if (nameParts.isNotEmpty) {
        initials = nameParts
            .map((part) => part.isNotEmpty ? part[0].toUpperCase() : '')
            .join('');
        if (initials.length > 2) {
          initials = initials.substring(0, 2);
        }
      }
    } else if (_emailController.text.isNotEmpty) {
      initials = _emailController.text[0].toUpperCase();
    } else {
      initials = '?';
    }

    // Rastgele bir renk seç (kullanıcı adına göre sabit)
    final List<Color> avatarColors = [
      const Color(0xFF3498DB), // Mavi
      const Color(0xFF9B59B6), // Mor
      const Color(0xFF1ABC9C), // Turkuaz
      const Color(0xFF2ECC71), // Yeşil
      const Color(0xFFE74C3C), // Kırmızı
    ];

    // Kullanıcı adının hash değerine göre renk seç
    final int colorIndex = _fullNameController.text.isEmpty
        ? 0
        : _fullNameController.text.hashCode % avatarColors.length;
    final Color avatarColor = avatarColors[colorIndex.abs()];

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: avatarColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: avatarColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Kullanıcı bilgilerini güncelle
        final userData = {
          'fullName': _fullNameController.text,
          'email': _emailController.text,
          'phoneNumber': _phoneController.text,
        };

        // API'ye güncelleme isteği gönder
        final result = await _apiService.updateProfile(userData);

        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _isEditing = false;
        });

        if (result['success']) {
          // Başarılı güncelleme
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(result['message'] ?? 'Profil bilgileriniz güncellendi'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Hata durumu
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  result['message'] ?? 'Profil güncellenirken bir hata oluştu'),
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
  }

  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // API çıkış işlemi
      final success = await _apiService.logout();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (success) {
        // Başarılı çıkış
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Başarıyla çıkış yapıldı'),
            backgroundColor: Colors.green,
          ),
        );

        // Giriş sayfasına yönlendir
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      } else {
        // Hata durumu
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Çıkış yapılırken bir hata oluştu'),
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
        title: const Text('Profil'),
        actions: [
          if (!_isLoading && _errorMessage.isEmpty)
            IconButton(
              icon: Icon(_isEditing ? Icons.close : Icons.edit),
              onPressed: _toggleEdit,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Profil bilgileri yükleniyor...',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.errorColor.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.error_outline,
                            color: AppTheme.errorColor,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Profil bilgileri alınamadı',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.secondaryTextColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadUserData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tekrar Dene'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Profil resmi
                        _buildProfileAvatar(),
                        const SizedBox(height: 16),

                        // Kullanıcı adı
                        Text(
                          _fullNameController.text.isEmpty
                              ? 'İsimsiz Kullanıcı'
                              : _fullNameController.text,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // E-posta
                        Text(
                          _emailController.text.isEmpty
                              ? 'E-posta yok'
                              : _emailController.text,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Profil bilgileri
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Kişisel Bilgiler',
                            style: AppTheme.subheadingStyle,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Ad Soyad alanı
                        TextFormField(
                          controller: _fullNameController,
                          decoration: const InputDecoration(
                            labelText: 'Ad Soyad',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                          enabled: _isEditing,
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
                          decoration: const InputDecoration(
                            labelText: 'E-posta',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                          enabled: _isEditing,
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

                        // Telefon alanı
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Telefon',
                            prefixIcon: Icon(Icons.phone_outlined),
                            border: OutlineInputBorder(),
                          ),
                          enabled: _isEditing,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Lütfen telefon numaranızı girin';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),

                        // Kaydet butonu (sadece düzenleme modunda göster)
                        if (_isEditing)
                          ElevatedButton(
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 16),
                            ),
                            child: const Text(
                              'Değişiklikleri Kaydet',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Diğer seçenekler
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Hesap',
                            style: AppTheme.subheadingStyle,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Şifre değiştir
                        ListTile(
                          leading: const Icon(Icons.lock_outline),
                          title: const Text('Şifre Değiştir'),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            // Şifre değiştirme sayfasına yönlendir
                          },
                        ),

                        // Bildirim ayarları
                        ListTile(
                          leading: const Icon(Icons.notifications_outlined),
                          title: const Text('Bildirim Ayarları'),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            // Bildirim ayarları sayfasına yönlendir
                          },
                        ),

                        // Gizlilik politikası
                        ListTile(
                          leading: const Icon(Icons.privacy_tip_outlined),
                          title: const Text('Gizlilik Politikası'),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            // Gizlilik politikası sayfasına yönlendir
                          },
                        ),

                        // Çıkış yap
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text(
                            'Çıkış Yap',
                            style: TextStyle(color: Colors.red),
                          ),
                          onTap: _logout,
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
