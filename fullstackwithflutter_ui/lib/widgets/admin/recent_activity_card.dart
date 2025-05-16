import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/activity.dart';

class RecentActivityCard extends StatelessWidget {
  final List<Activity> activities;

  const RecentActivityCard({
    super.key,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Son Aktiviteler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (activities.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Henüz aktivite bulunmamaktadır',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              ...activities.map((activity) => _buildActivityItem(activity)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(Activity activity) {
    // String'den IconData'ya dönüştürme
    IconData getIconData(String? iconName) {
      switch (iconName) {
        case 'person_add':
          return Icons.person_add;
        case 'login':
          return Icons.login;
        case 'logout':
          return Icons.logout;
        case 'event_available':
          return Icons.event_available;
        case 'event_note':
          return Icons.event_note;
        case 'medical_services':
          return Icons.medical_services;
        case 'admin_panel_settings':
          return Icons.admin_panel_settings;
        default:
          return Icons.info_outline;
      }
    }

    // String'den Color'a dönüştürme
    Color getColorFromHex(String? hexColor) {
      if (hexColor == null || hexColor.isEmpty) {
        return Colors.blue;
      }

      hexColor = hexColor.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }

      try {
        return Color(int.parse(hexColor, radix: 16));
      } catch (e) {
        return Colors.blue;
      }
    }

    final IconData icon = getIconData(activity.icon);
    final Color color = getColorFromHex(activity.color);
    final String formattedDate =
        DateFormat('dd.MM.yyyy HH:mm').format(activity.createdDate);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(25), // 0.1 * 255 = 25
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.type ?? 'Bilinmeyen Aktivite',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.description ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                if (activity.userName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Kullanıcı: ${activity.userName}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            formattedDate,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
