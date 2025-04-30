import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../constants/app_theme.dart';
import '../../widgets/user_list_item.dart';
import '../../routes/app_routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

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
    'Randevulu Hastalar'
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
      // Burada gerçek bir kategori filtresi uygulayabilirsiniz
      // Örnek olarak basit bir filtreleme yapıyoruz
      switch (_selectedCategoryIndex) {
        case 1: // Aktif Hastalar
          categoryFiltered = _users
              .where((user) => user.id % 2 == 0)
              .toList(); // Örnek filtreleme
          break;
        case 2: // Yeni Hastalar
          categoryFiltered = _users
              .where((user) => user.id % 3 == 0)
              .toList(); // Örnek filtreleme
          break;
        case 3: // Randevulu Hastalar
          categoryFiltered = _users
              .where((user) => user.id % 5 == 0)
              .toList(); // Örnek filtreleme
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
      print('Fetching users...');
      final users = await _apiService.getAllUsers();
      print('Users fetched: ${users.length}');

      if (mounted) {
        setState(() {
          _users = users;
          _filteredUsers = users; // Başlangıçta tüm kullanıcıları göster
          _isLoading = false;
          _errorMessage = ''; // Hata mesajını temizle
        });
      }
    } catch (e) {
      print('Error fetching users: $e');

      if (mounted) {
        setState(() {
          _errorMessage = 'Kullanıcılar yüklenirken bir hata oluştu: $e';
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Yeni hasta ekleme fonksiyonu
        },
        tooltip: 'Yeni Hasta Ekle',
        child: const Icon(Icons.add),
      ),
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
                color: Colors.black.withOpacity(0.05),
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
                  color: AppTheme.primaryColor.withOpacity(0.1),
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
                'Yeni hasta eklemek için aşağıdaki butonu kullanabilirsiniz.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // Yeni hasta ekleme fonksiyonu
                },
                icon: const Icon(Icons.add),
                label: const Text('Yeni Hasta Ekle'),
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
                      color: Colors.black.withOpacity(0.05),
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
                        color: AppTheme.warningColor.withOpacity(0.1),
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
                return UserListItem(user: _filteredUsers[index]);
              },
            ),
    );
  }
}
