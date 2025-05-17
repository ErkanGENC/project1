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
  List<Appointment> _appointments = [];
  List<String> _patientsWithAppointments = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _searchQuery = '';

  // Kategori indeksi
  // 0: Tümü
  // 1: Aktif Hastalar (Son 30 gün içinde randevusu olan hastalar)
  // 2: Yeni Hastalar (Son 7 gün içinde kaydedilmiş hastalar)
  // 3: Randevulu Hastalar (Herhangi bir zamanda randevusu olan hastalar)
  // 4: Doktor Atanmış Hastalar (Bir doktora atanmış hastalar)
  int _selectedCategoryIndex = 0;

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
    _fetchCurrentUser();
    _fetchUpcomingAppointments();
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
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
      print('Kullanıcı bilgileri alınırken hata: $e');
    }
  }

  // Yaklaşan randevuları getir
  Future<void> _fetchUpcomingAppointments() async {
    try {
      final appointments = await _apiService.getAllAppointments();

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
        case 1: // Aktif Hastalar - Son 30 gün içinde randevusu olan hastalar
          // Randevuları getir ve son 30 gün içinde randevusu olan hastaları filtrele
          _fetchActivePatients();
          return; // Filtreleme _fetchActivePatients içinde yapılıyor
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
          // Gerçek randevu verilerine göre filtreleme yapacağız
          // Önce tüm randevuları alıp, hasta adlarını bir listeye ekleyeceğiz
          _fetchAppointmentsForFilter();
          return; // Filtreleme _fetchAppointmentsForFilter içinde yapılıyor
        case 4: // Doktor Atanmış Hastalar
          categoryFiltered = _users
              .where((user) =>
                  user.doctorId != null &&
                  user.doctorName != null &&
                  user.doctorName!.isNotEmpty)
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

  // Randevuları getir ve randevulu hastaları filtrele
  Future<void> _fetchAppointmentsForFilter() async {
    try {
      // Tüm randevuları al
      final appointments = await _apiService.getAllAppointments();

      // Randevusu olan hastaların adlarını bir listeye ekle
      final patientsWithAppointments = appointments
          .map((appointment) => appointment.patientName)
          .toSet() // Tekrar eden isimleri kaldır
          .toList();

      setState(() {
        _appointments = appointments;
        _patientsWithAppointments = patientsWithAppointments;

        // Randevusu olan kullanıcıları filtrele
        // Tam eşleşme yaparak sadece gerçekten randevusu olan hastaları göster
        _filteredUsers = _users.where((user) {
          // Kullanıcının tam adı randevulu hastalar listesinde var mı kontrol et
          return patientsWithAppointments.contains(user.fullName);
        }).toList();

        // TabBar'ı güncelle
        setState(() {});
      });
    } catch (e) {
      // Hata durumunda sessizce devam et
      // Hata durumunda boş liste göster
      setState(() {
        _filteredUsers = [];
        _patientsWithAppointments = [];
      });
    }
  }

  // Aktif hastaları getir (son 30 gün içinde randevusu olanlar)
  Future<void> _fetchActivePatients() async {
    try {
      // Tüm randevuları al
      final appointments = await _apiService.getAllAppointments();

      // Son 30 gün içindeki randevuları filtrele
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final recentAppointments = appointments
          .where((appointment) => appointment.date.isAfter(thirtyDaysAgo))
          .toList();

      // Son 30 gün içinde randevusu olan hastaların adlarını bir listeye ekle
      final activePatientNames = recentAppointments
          .map((appointment) => appointment.patientName)
          .toSet() // Tekrar eden isimleri kaldır
          .toList();

      setState(() {
        // Son 30 gün içinde randevusu olan kullanıcıları filtrele
        _filteredUsers = _users.where((user) {
          // Kullanıcının tam adı aktif hastalar listesinde var mı kontrol et
          return activePatientNames.contains(user.fullName);
        }).toList();

        // TabBar'ı güncelle
        setState(() {});
      });
    } catch (e) {
      // Hata durumunda sessizce devam et
      // Hata durumunda boş liste göster
      setState(() {
        _filteredUsers = [];
      });
    }
  }

  Future<void> _fetchUsers() async {
    try {
      final users = await _apiService.getAllUsers();

      // Tüm randevuları da yükle
      final appointments = await _apiService.getAllAppointments();

      if (mounted) {
        setState(() {
          _users = users;
          _appointments = appointments;
          _filteredUsers = users; // Başlangıçta tüm kullanıcıları göster
          _isLoading = false;
          _errorMessage = ''; // Hata mesajını temizle
        });

        // Seçili kategoriye göre filtreleme yap
        if (_selectedCategoryIndex == 1) {
          _fetchActivePatients();
        } else if (_selectedCategoryIndex == 3) {
          _fetchAppointmentsForFilter();
        } else {
          // TabBar'ı güncelle
          setState(() {});
        }
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
            leading: const Icon(Icons.people),
            title: Row(
              children: [
                const Text('Tümü'),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_users.length}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            selected: _selectedCategoryIndex == 0,
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _selectedCategoryIndex = 0;
                _filterUsers();
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: Row(
              children: [
                const Text('Aktif Hastalar'),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_appointments.where((a) => a.date.isAfter(DateTime.now().subtract(const Duration(days: 30)))).map((a) => a.patientName).toSet().length}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            selected: _selectedCategoryIndex == 1,
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _selectedCategoryIndex = 1;
                _filterUsers();
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_add),
            title: Row(
              children: [
                const Text('Yeni Hastalar'),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_users.where((user) => user.createdDate != null && user.createdDate!.isAfter(DateTime.now().subtract(const Duration(days: 7)))).length}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            selected: _selectedCategoryIndex == 2,
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _selectedCategoryIndex = 2;
                _filterUsers();
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Row(
              children: [
                const Text('Randevulu Hastalar'),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_patientsWithAppointments.length}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            selected: _selectedCategoryIndex == 3,
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _selectedCategoryIndex = 3;
                _filterUsers();
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.medical_services),
            title: Row(
              children: [
                const Text('Doktor Atanmış Hastalar'),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_users.where((user) => user.doctorId != null && user.doctorName != null && user.doctorName!.isNotEmpty).length}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            selected: _selectedCategoryIndex == 4,
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _selectedCategoryIndex = 4;
                _filterUsers();
              });
            },
          ),
          const Divider(),
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
                      _fetchCurrentUser();
                      _fetchUpcomingAppointments();
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
          ListTile(
            leading: const Icon(Icons.admin_panel_settings),
            title: const Text('Admin Paneli'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.adminDashboard);
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
              _fetchCurrentUser();
              _fetchUpcomingAppointments();
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
                      _fetchCurrentUser();
                      _fetchUpcomingAppointments();
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Randevu oluşturma ekranını aç
          Navigator.pushNamed(context, AppRoutes.createAppointment);
        },
        tooltip: 'Randevu Oluştur',
        child: const Icon(Icons.add),
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
