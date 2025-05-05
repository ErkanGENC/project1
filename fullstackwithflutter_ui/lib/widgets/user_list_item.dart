import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../constants/app_theme.dart';
import '../screens/doctor/select_doctor_screen.dart';

class UserListItem extends StatelessWidget {
  final User user;
  final Function(User)? onUserUpdated;

  const UserListItem({
    super.key,
    required this.user,
    this.onUserUpdated,
  });

  @override
  Widget build(BuildContext context) {
    // Hasta için rastgele bir renk seçimi (gerçek uygulamada hasta durumuna göre değişebilir)
    final List<Color> avatarColors = [
      const Color(0xFF3498DB), // Mavi
      const Color(0xFF9B59B6), // Mor
      const Color(0xFF1ABC9C), // Turkuaz
      const Color(0xFF2ECC71), // Yeşil
      const Color(0xFFE74C3C), // Kırmızı
    ];

    // Hasta ID'sine göre sabit bir renk seçimi
    final Color avatarColor = avatarColors[user.id % avatarColors.length];

    // Hasta adının baş harflerini al
    final String initials = user.fullName
        .split(' ')
        .map((name) => name.isNotEmpty ? name[0].toUpperCase() : '')
        .join('')
        .substring(0, user.fullName.split(' ').length > 1 ? 2 : 1);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to user details
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Hero(
                tag: 'user-avatar-${user.id}',
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: avatarColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: avatarColor.withAlpha(76),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Hasta bilgileri
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.email_outlined,
                          size: 16,
                          color: AppTheme.secondaryTextColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            user.email,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.secondaryTextColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: 16,
                          color: AppTheme.secondaryTextColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          user.phoneNumber,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    if (user.doctorName != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.medical_services_outlined,
                            size: 16,
                            color: AppTheme.accentColor,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Dr. ${user.doctorName} (${user.specialization})',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.accentColor,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Sağ taraftaki işlem butonları
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.calendar_today_outlined,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      onPressed: () {
                        // Randevu oluştur
                      },
                      tooltip: 'Randevu Oluştur',
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.medical_services_outlined,
                        color: AppTheme.accentColor,
                        size: 20,
                      ),
                      onPressed: () {
                        // Doktor seçme ekranını aç
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SelectDoctorScreen(
                              user: user,
                              onDoctorSelected: (updatedUser) {
                                // Callback ile güncellenmiş kullanıcıyı geri döndür
                                if (onUserUpdated != null) {
                                  onUserUpdated!(updatedUser);
                                }
                              },
                            ),
                          ),
                        );
                      },
                      tooltip: user.doctorId == null
                          ? 'Doktor Seç'
                          : 'Doktor Değiştir',
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
