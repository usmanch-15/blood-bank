import 'package:flutter/material.dart';
import '../../../models/notification_model.dart';
import '../../../utils/date_utils.dart';

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationTile(
      {super.key, required this.notification, required this.onTap});

  IconData _iconForType(String type) {
    switch (type) {
      case 'blood_request': return Icons.bloodtype;
      case 'blood_drive': return Icons.favorite;
      case 'eligibility': return Icons.check_circle;
      case 'reward': return Icons.star;
      default: return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      tileColor: notification.isRead ? null : Colors.red.shade50,
      leading: CircleAvatar(
        backgroundColor: Colors.red.shade100,
        child: Icon(_iconForType(notification.type),
            color: Colors.red, size: 20),
      ),
      title: Text(notification.title,
          style: TextStyle(
              fontWeight: notification.isRead
                  ? FontWeight.normal
                  : FontWeight.bold)),
      subtitle: Text(notification.body,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12)),
      trailing: Text(
        AppDateUtils.timeAgo(notification.createdAt),
        style: const TextStyle(fontSize: 11, color: Colors.grey),
      ),
    );
  }
}