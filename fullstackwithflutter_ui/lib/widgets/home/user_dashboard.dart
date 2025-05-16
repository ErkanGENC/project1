import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../models/appointment_model.dart';
import '../../models/user_model.dart';
import '../../routes/app_routes.dart';
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
                        ? 'Doktorunuz: ${currentUser!.doctorName}'
                        : 'Henüz bir doktor seçmediniz',
                    style: TextStyle(
                      fontSize: 14,
                      color: currentUser?.doctorName != null &&
                              currentUser!.doctorName!.isNotEmpty
                          ? AppTheme.secondaryTextColor
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
                () => Navigator.pushNamed(context, AppRoutes.dentalHealth),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                'Randevu Oluştur',
                Icons.calendar_today,
                AppTheme.accentColor,
                () => Navigator.pushNamed(context, AppRoutes.createAppointment),
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
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                'Doktor Seç',
                Icons.medical_services_outlined,
                Colors.teal,
                () {
                  // Doktor seçme ekranına yönlendir
                  // Şimdilik randevu oluşturma ekranına yönlendirelim
                  Navigator.pushNamed(context, AppRoutes.createAppointment);
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
                        onPressed: () => Navigator.pushNamed(
                            context, AppRoutes.createAppointment),
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
                Navigator.pushNamed(context, AppRoutes.createAppointment);
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
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildHealthIndicator(
                      'Diş Fırçalama',
                      Icons.brush,
                      AppTheme.primaryColor,
                      0.7,
                    ),
                    _buildHealthIndicator(
                      'Diş İpi',
                      Icons.linear_scale,
                      AppTheme.accentColor,
                      0.5,
                    ),
                    _buildHealthIndicator(
                      'Gargara',
                      Icons.local_drink,
                      Colors.purple,
                      0.3,
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
            ),
          ),
        ),
      ],
    );
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
