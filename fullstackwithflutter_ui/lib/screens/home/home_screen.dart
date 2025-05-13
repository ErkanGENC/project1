import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../constants/app_theme.dart';
import '../../widgets/user_list_item.dart';
import '../../routes/app_routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<User> _users = [];
  List<User> _filteredUsers = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _searchQuery = '';
  late TabController _tabController;

  // Kategori filtreleri için
  final List<String> _categories = [
    'Tümü',
    'Aktif Hastalar',
    'Yeni Hastalar',
    'Randevulu Hastalar',
    'Doktor Atanmış Hastalar'
  ];
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    // Tab controller'ı başlat
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _fetchUsers();
  }

  @override
  void dispose() {
    // Controller'ı temizle
    _tabController.dispose();
    super.dispose();
  }

  // Tab değişikliğini dinle
  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedCategoryIndex = _tabController.index;
        _filterUsers();
      });
    }
  }

  // Kullanıcıları filtrele
  void _filterUsers() {
    if (_searchQuery.isEmpty && _selectedCategoryIndex == 0) {
      // Arama yoksa ve tüm kategoriler seçiliyse, tüm kullanıcıları göster
      setState(() {
        _filteredUsers = _users;
      });
      return;
    }

    // Önce kategoriye göre filtrele
    List<User> categoryFiltered = _users;
    if (_selectedCategoryIndex > 0) {
      // Gerçek verilere dayalı filtreleme
      final now = DateTime.now();
      final oneWeekAgo = now.subtract(const Duration(days: 7));

      switch (_selectedCategoryIndex) {
        case 1: // Aktif Hastalar - Son 30 gün içinde kaydedilmiş kullanıcılar
          final thirtyDaysAgo = now.subtract(const Duration(days: 30));
          categoryFiltered = _users.where((user) {
            // Kullanıcının kayıt tarihi varsa ve son 30 gün içindeyse
            if (user.createdDate != null) {
              return user.createdDate!.isAfter(thirtyDaysAgo);
            }
            return false;
          }).toList();
          break;
        case 2: // Yeni Hastalar - Son 7 gün içinde kaydedilmiş kullanıcılar
          categoryFiltered = _users.where((user) {
            // Kullanıcının kayıt tarihi varsa ve son 7 gün içindeyse
            if (user.createdDate != null) {
              return user.createdDate!.isAfter(oneWeekAgo);
            }
            return false;
          }).toList();
          break;
        case 3: // Randevulu Hastalar - Randevusu olan kullanıcılar
          // Burada gerçek randevu verisi olmadığı için,
          // örnek olarak ID'si 5'in katı olan kullanıcıları gösteriyoruz
          // Gerçek uygulamada, randevusu olan kullanıcıları API'den almalısınız
          categoryFiltered = _users.where((user) => user.id % 5 == 0).toList();
          break;
        case 4: // Doktor Atanmış Hastalar
          categoryFiltered = _users
              .where((user) => user.doctorId != null && user.doctorName != null)
              .toList();
          break;
      }
    }

    // Sonra arama sorgusuna göre filtrele
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      setState(() {
        _filteredUsers = categoryFiltered.where((user) {
          return user.fullName.toLowerCase().contains(query) ||
              user.email.toLowerCase().contains(query) ||
              user.phoneNumber.toLowerCase().contains(query);
        }).toList();
      });
    } else {
      setState(() {
        _filteredUsers = categoryFiltered;
      });
    }
  }

  Future<void> _fetchUsers() async {
    try {
      final users = await _apiService.getAllUsers();

      if (mounted) {
        setState(() {
          _users = users;
          _filteredUsers = users; // Başlangıçta tüm kullanıcıları göster
          _isLoading = false;
          _errorMessage = ''; // Hata mesajını temizle
        });
      }
    } catch (e) {
      if (mounted) {
        String userFriendlyMessage;

        // Hata türüne göre kullanıcı dostu mesajlar
        if (e.toString().contains('SocketException') ||
            e.toString().contains('Connection refused')) {
          userFriendlyMessage =
              'Sunucuya bağlanılamıyor. Lütfen internet bağlantınızı kontrol edin.';
        } else if (e.toString().contains('TimeoutException')) {
          userFriendlyMessage =
              'Sunucu yanıt vermiyor. Lütfen daha sonra tekrar deneyin.';
        } else if (e.toString().contains('FormatException')) {
          userFriendlyMessage =
              'Sunucudan gelen veri işlenemedi. Lütfen daha sonra tekrar deneyin.';
        } else {
          userFriendlyMessage =
              'Hastalar yüklenirken bir hata oluştu. Lütfen daha sonra tekrar deneyin.';
        }

        setState(() {
          _errorMessage = userFriendlyMessage;
          _isLoading = false;
        });
      }
    }
  }

  // Arama sorgusunu güncelle
  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query;
      _filterUsers(); // Arama sorgusuna göre filtreleme yap
    });
  }

  // Seçili alt gezinme öğesi
  int _selectedIndex = 0;

  // Alt gezinme öğelerine tıklandığında çağrılan fonksiyon
  void _onItemTapped(int index) {
    if (index == _selectedIndex) return; // Zaten seçili ise bir şey yapma

    switch (index) {
      case 0: // Ana Sayfa
        // Zaten ana sayfadayız, bir şey yapma
        break;
      case 1: // Ağız ve Diş Sağlığı
        Navigator.pushNamed(context, AppRoutes.dentalHealth);
        return; // return ile fonksiyondan çık
      case 2: // Profil
        Navigator.pushNamed(context, AppRoutes.profile);
        return; // return ile fonksiyondan çık
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ağız ve Diş Sağlığı Takip'),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.adminDashboard);
            },
            tooltip: 'Admin Paneli',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = '';
              });
              _fetchUsers();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: Colors.white,
            tabs: _categories.map((category) => Tab(text: category)).toList(),
          ),
        ),
      ),
      body: Column(
        children: [
          // Arama çubuğu
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _updateSearchQuery,
              decoration: InputDecoration(
                hintText: 'Hasta ara...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(vertical: 0.0),
              ),
            ),
          ),
          // Liste içeriği
          Expanded(child: _buildBody()),
        ],
      ),
      // Hasta ekleme butonu kaldırıldı - kullanıcılar kayıt olduklarında otomatik olarak hasta olarak kaydedilir
      // Alt gezinme çubuğu
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: 'Diş Sağlığı',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppTheme.primaryColor,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Hastalar yükleniyor...',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.secondaryTextColor,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.errorColor.withAlpha(25),
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
                  color: AppTheme.errorColor.withAlpha(25),
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
                'Bir hata oluştu',
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
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = '';
                  });
                  _fetchUsers();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_users.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
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
                  color: AppTheme.primaryColor.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.people_outline,
                  color: AppTheme.primaryColor,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Henüz kayıtlı hasta bulunmamaktadır',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Yeni kullanıcılar kayıt olduklarında otomatik olarak hasta olarak eklenirler.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  _fetchUsers();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Yenile'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchUsers,
      color: AppTheme.primaryColor,
      backgroundColor: Colors.white,
      child: _filteredUsers.isEmpty
          ? Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(13),
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
                        color: AppTheme.warningColor.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.search_off,
                        color: AppTheme.warningColor,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Arama sonucu bulunamadı',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Farklı bir arama terimi deneyin veya filtreleri değiştirin',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.secondaryTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () {
                        // Arama sorgusunu temizle
                        setState(() {
                          _searchQuery = '';
                          _filterUsers();
                        });
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Aramayı Temizle'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                return UserListItem(
                  user: _filteredUsers[index],
                  onUserUpdated: (updatedUser) {
                    // Kullanıcı listesini güncelle
                    setState(() {
                      // Güncellenmiş kullanıcıyı bul ve güncelle
                      final userIndex =
                          _users.indexWhere((u) => u.id == updatedUser.id);
                      if (userIndex != -1) {
                        _users[userIndex] = updatedUser;
                      }

                      // Filtrelenmiş listeyi de güncelle
                      final filteredIndex = _filteredUsers
                          .indexWhere((u) => u.id == updatedUser.id);
                      if (filteredIndex != -1) {
                        _filteredUsers[filteredIndex] = updatedUser;
                      }
                    });
                  },
                );
              },
            ),
    );
  }
}
