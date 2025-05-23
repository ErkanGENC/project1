import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../models/appointment_model.dart';
import '../../models/user_model.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';
import '../../screens/doctor/select_doctor_screen.dart';
import '../../screens/appointment/create_appointment_screen.dart';
import 'dental_health_tips.dart';

class UserDashboard extends StatelessWidget {
  final User? currentUser;
  final List<Appointment> upcomingAppointments;
  final Function() onRefresh;

  const UserDashboard({
    Key? key,
    this.currentUser,
    required this.upcomingAppointments,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(context),
          const SizedBox(height: 24),
          _buildQuickActions(context),
          const SizedBox(height: 24),
          _buildUpcomingAppointments(context),
          const SizedBox(height: 24),
          _buildDentalHealthSummary(context),
          const SizedBox(height: 24),
          const DentalHealthTips(),
          const SizedBox(height: 24),
          const DentalProblemInfo(),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.primaryColor,
              child: Text(
                _getInitials(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hoş Geldiniz, ${currentUser?.fullName ?? 'Değerli Hastamız'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentUser?.doctorName != null &&
                            currentUser!.doctorName!.isNotEmpty
                        ? 'Doktorunuz: Dr. ${currentUser!.doctorName}'
                        : 'Henüz bir doktor seçmediniz',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: currentUser?.doctorName != null &&
                              currentUser!.doctorName!.isNotEmpty
                          ? FontWeight.w500
                          : FontWeight.normal,
                      color: currentUser?.doctorName != null &&
                              currentUser!.doctorName!.isNotEmpty
                          ? Colors.teal
                          : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hızlı Erişim',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                'Diş Sağlığı Takibi',
                Icons.medical_services,
                AppTheme.primaryColor,
                () async {
                  if (currentUser != null) {
                    // Yükleniyor göstergesi
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext dialogContext) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                    );

                    // BuildContext'i saklayalım
                    final currentContext = context;

                    try {
                      // Kullanıcının onaylanmış randevusu olup olmadığını kontrol et
                      final apiService = ApiService();
                      final hasApprovedAppointment = await apiService
                          .hasApprovedAppointment(currentUser!.id);

                      // Yükleniyor göstergesini kapat
                      if (currentContext.mounted) {
                        Navigator.of(currentContext, rootNavigator: true).pop();
                      } else {
                        return;
                      }

                      if (!hasApprovedAppointment) {
                        // Onaylanmış randevu yoksa uyarı göster
                        if (currentContext.mounted) {
                          ScaffoldMessenger.of(currentContext).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Bu sayfaya erişim için onaylanmış bir doktor randevunuz olmalıdır. '
                                  'Lütfen önce bir randevu oluşturun ve doktorunuzun onaylamasını bekleyin.'),
                              backgroundColor: Colors.orange,
                              duration: Duration(seconds: 5),
                            ),
                          );
                        }
                        return;
                      }

                      // Onaylanmış randevu varsa sayfaya yönlendir
                      if (currentContext.mounted) {
                        Navigator.pushNamed(
                            currentContext, AppRoutes.dentalHealth);
                      }
                    } catch (e) {
                      // Yükleniyor göstergesini kapat
                      if (currentContext.mounted) {
                        Navigator.of(currentContext, rootNavigator: true).pop();
                      }

                      // Hata mesajı göster
                      if (currentContext.mounted) {
                        ScaffoldMessenger.of(currentContext).showSnackBar(
                          SnackBar(
                            content: Text('Bir hata oluştu: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  } else {
                    // Kullanıcı bilgisi yoksa uyarı göster
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Kullanıcı bilgileriniz yüklenemedi. Lütfen tekrar giriş yapın.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                'Randevu Oluştur',
                Icons.calendar_today,
                AppTheme.accentColor,
                () {
                  // Kullanıcının kendi adına randevu oluşturması için
                  // kullanıcı adını parametre olarak geçir
                  if (currentUser != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateAppointmentScreen(
                          patientName: currentUser!.fullName,
                        ),
                      ),
                    );
                  } else {
                    // Kullanıcı bilgisi yoksa normal yönlendirme yap
                    Navigator.pushNamed(context, AppRoutes.createAppointment);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                'Profil',
                Icons.person,
                Colors.purple,
                () => Navigator.pushNamed(context, AppRoutes.profile),
              ),
            ),
            // Eğer kullanıcının zaten bir doktoru varsa (randevu onaylandığında otomatik atanır)
            // "Doktor Seç" butonunu gösterme
            if (currentUser?.doctorName == null ||
                currentUser!.doctorName!.isEmpty)
              const SizedBox(width: 12),
            if (currentUser?.doctorName == null ||
                currentUser!.doctorName!.isEmpty)
              Expanded(
                child: _buildActionCard(
                  context,
                  'Doktor Seç',
                  Icons.medical_services_outlined,
                  Colors.teal,
                  () {
                    // Kullanıcının kendi doktorunu seçmesi için
                    // kullanıcı bilgisini parametre olarak geçir
                    if (currentUser != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SelectDoctorScreen(
                            user: currentUser!,
                            onDoctorSelected: (updatedUser) {
                              // Kullanıcı bilgilerini güncelle ve sayfayı yenile
                              onRefresh();
                            },
                          ),
                        ),
                      );
                    } else {
                      // Kullanıcı bilgisi yoksa uyarı göster
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Kullanıcı bilgileriniz yüklenemedi. Lütfen tekrar deneyin.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingAppointments(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Yaklaşan Randevularınız',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 12),
        upcomingAppointments.isEmpty
            ? Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Yaklaşan randevunuz bulunmamaktadır',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.secondaryTextColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Kullanıcının kendi adına randevu oluşturması için
                          // kullanıcı adını parametre olarak geçir
                          if (currentUser != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CreateAppointmentScreen(
                                  patientName: currentUser!.fullName,
                                ),
                              ),
                            );
                          } else {
                            // Kullanıcı bilgisi yoksa normal yönlendirme yap
                            Navigator.pushNamed(
                                context, AppRoutes.createAppointment);
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Randevu Oluştur'),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: upcomingAppointments.length > 2
                    ? 2
                    : upcomingAppointments.length,
                itemBuilder: (context, index) {
                  final appointment = upcomingAppointments[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.calendar_today,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      title: Text(
                        'Dr. ${appointment.doctorName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${_formatDate(appointment.date)} - ${appointment.time}',
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              _getStatusColor(appointment.status).withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          appointment.status,
                          style: TextStyle(
                            color: _getStatusColor(appointment.status),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
        if (upcomingAppointments.length > 2)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton(
              onPressed: () {
                // Tüm randevuları göster
                // Şimdilik randevu oluşturma ekranına yönlendirelim
                if (currentUser != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateAppointmentScreen(
                        patientName: currentUser!.fullName,
                      ),
                    ),
                  );
                } else {
                  // Kullanıcı bilgisi yoksa normal yönlendirme yap
                  Navigator.pushNamed(context, AppRoutes.createAppointment);
                }
              },
              child: const Text('Tüm Randevuları Göster'),
            ),
          ),
      ],
    );
  }

  Widget _buildDentalHealthSummary(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ağız Sağlığı Özeti',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FutureBuilder<Map<String, dynamic>>(
              future: _loadDentalSummary(),
              builder: (context, snapshot) {
                // Yükleniyor durumu
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                // Hata durumu
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Veriler yüklenirken bir hata oluştu',
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  );
                }

                // Veri yoksa
                if (!snapshot.hasData || snapshot.data == null) {
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildHealthIndicator(
                            'Diş Fırçalama',
                            Icons.brush,
                            AppTheme.primaryColor,
                            0.0,
                          ),
                          _buildHealthIndicator(
                            'Diş İpi',
                            Icons.linear_scale,
                            AppTheme.accentColor,
                            0.0,
                          ),
                          _buildHealthIndicator(
                            'Gargara',
                            Icons.local_drink,
                            Colors.purple,
                            0.0,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(
                            context, AppRoutes.dentalHealth),
                        icon: const Icon(Icons.medical_services),
                        label: const Text('Detaylı Takip'),
                      ),
                    ],
                  );
                }

                // Veri varsa
                final data = snapshot.data!;
                final brushingPercentage =
                    data['brushingPercentage'] as double? ?? 0.0;
                final flossPercentage =
                    data['flossPercentage'] as double? ?? 0.0;
                final mouthwashPercentage =
                    data['mouthwashPercentage'] as double? ?? 0.0;

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildHealthIndicator(
                          'Diş Fırçalama',
                          Icons.brush,
                          AppTheme.primaryColor,
                          brushingPercentage,
                        ),
                        _buildHealthIndicator(
                          'Diş İpi',
                          Icons.linear_scale,
                          AppTheme.accentColor,
                          flossPercentage,
                        ),
                        _buildHealthIndicator(
                          'Gargara',
                          Icons.local_drink,
                          Colors.purple,
                          mouthwashPercentage,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.dentalHealth),
                      icon: const Icon(Icons.medical_services),
                      label: const Text('Detaylı Takip'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // Diş sağlığı özet verilerini yükle
  Future<Map<String, dynamic>> _loadDentalSummary() async {
    if (currentUser == null) {
      return {
        'brushingPercentage': 0.0,
        'flossPercentage': 0.0,
        'mouthwashPercentage': 0.0
      };
    }

    try {
      final ApiService apiService = ApiService();
      final summary = await apiService.getUserDentalSummary(currentUser!.id);
      return summary;
    } catch (e) {
      // Hata durumunda varsayılan değerleri döndür
      return {
        'brushingPercentage': 0.0,
        'flossPercentage': 0.0,
        'mouthwashPercentage': 0.0
      };
    }
  }

  Widget _buildHealthIndicator(
    String title,
    IconData icon,
    Color color,
    double progress,
  ) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                color: color,
                strokeWidth: 6,
              ),
            ),
            Icon(
              icon,
              color: color,
              size: 24,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '${(progress * 100).toInt()}%',
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _getInitials() {
    if (currentUser == null || currentUser!.fullName.isEmpty) {
      return '?';
    }

    final nameParts = currentUser!.fullName.split(' ');
    if (nameParts.isEmpty) {
      return '?';
    }

    if (nameParts.length == 1) {
      return nameParts[0][0].toUpperCase();
    }

    return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'bekleyen':
        return Colors.orange;
      case 'onaylandı':
        return Colors.green;
      case 'iptal edildi':
        return Colors.red;
      case 'tamamlandı':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
