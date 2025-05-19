import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/appointment_model.dart';
import '../../services/api_service.dart';
import '../../constants/app_theme.dart';
import '../../widgets/user_list_item.dart';
import '../../widgets/home/user_dashboard.dart';
import '../../routes/app_routes.dart';
import '../../screens/dental/dental_health_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  List<User> _users = [];
  List<User> _filteredUsers = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _searchQuery = '';

  // Mevcut kullanıcı
  User? _currentUser;
  // Yaklaşan randevular
  List<Appointment> _upcomingAppointments = [];
  // Seçili sekme indeksi
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
    _fetchUsers();
    _fetchCurrentUser(); // Bu metod içinde _fetchUpcomingAppointments() çağrılıyor
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Mevcut kullanıcı bilgilerini getir
  Future<void> _fetchCurrentUser() async {
    try {
      final currentUser = await _apiService.getCurrentUser();

      if (currentUser != null) {
        setState(() {
          _currentUser = currentUser;
        });

        // Kullanıcı bilgileri alındıktan sonra randevuları getir
        _fetchUpcomingAppointments();
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }

  // Yaklaşan randevuları getir
  Future<void> _fetchUpcomingAppointments() async {
    try {
      List<Appointment> appointments = [];

      // Eğer giriş yapmış bir kullanıcı varsa, sadece o kullanıcının randevularını getir
      if (_currentUser != null) {
        appointments = await _apiService.getUserAppointments(_currentUser!.id);
      } else {
        // Kullanıcı yoksa boş liste kullan
        appointments = [];
      }

      // Bugün ve sonrası için olan randevuları filtrele
      final now = DateTime.now();
      final upcoming = appointments
          .where((appointment) =>
              appointment.date.isAfter(now) ||
              (appointment.date.year == now.year &&
                  appointment.date.month == now.month &&
                  appointment.date.day == now.day))
          .toList();

      // Tarihe göre sırala
      upcoming.sort((a, b) => a.date.compareTo(b.date));

      setState(() {
        _upcomingAppointments = upcoming;
      });
    } catch (e) {
      // Hata durumunda sessizce devam et
      setState(() {
        _upcomingAppointments = [];
      });
    }
  }

  // Kullanıcıları filtrele
  void _filterUsers() {
    if (_searchQuery.isEmpty) {
      // Arama yoksa tüm kullanıcıları göster
      setState(() {
        _filteredUsers = _users;
      });
      return;
    }

    // Arama sorgusuna göre filtrele
    final query = _searchQuery.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((user) {
        return user.fullName.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query) ||
            user.phoneNumber.toLowerCase().contains(query);
      }).toList();
    });
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

  // Alt gezinme çubuğu kaldırıldı - drawer menüsünde aynı seçenekler mevcut

  // Drawer menüsünü oluştur
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: AppTheme.primaryColor,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Hasta Paneli',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Ağız ve Diş Sağlığı Takip',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.medical_services),
            title: const Text('Diş Sağlığı'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DentalHealthScreen(
                    onRefresh: () {
                      setState(() {
                        _isLoading = true;
                      });
                      _fetchCurrentUser(); // Bu metod içinde _fetchUpcomingAppointments() çağrılıyor
                      setState(() {
                        _isLoading = false;
                      });
                    },
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profil'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.profile);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ağız ve Diş Sağlığı Takip'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = '';
              });
              _fetchUsers();
              _fetchCurrentUser(); // Bu metod içinde _fetchUpcomingAppointments() çağrılıyor
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ana Sayfa'),
            Tab(text: 'Hastalar'),
          ],
        ),
      ),
      drawer: _buildDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Ana Sayfa Sekmesi
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: UserDashboard(
                    currentUser: _currentUser,
                    upcomingAppointments: _upcomingAppointments,
                    onRefresh: () {
                      setState(() {
                        _isLoading = true;
                      });
                      _fetchCurrentUser(); // Bu metod içinde _fetchUpcomingAppointments() çağrılıyor
                      setState(() {
                        _isLoading = false;
                      });
                    },
                  ),
                ),

          // Hastalar Sekmesi
          Column(
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
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTabIndex,
        onTap: (index) {
          _tabController.animateTo(index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Hastalar',
          ),
        ],
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
                  currentUser: _currentUser, // Mevcut kullanıcı bilgisini aktar
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
