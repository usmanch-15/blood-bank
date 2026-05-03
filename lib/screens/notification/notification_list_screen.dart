import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/notification_model.dart';

/// Notification List Screen — inbox for all user notifications
class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() =>
      _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'Blood Request',
    'Blood Drive',
    'Eligibility',
    'Reward',
  ];

  // 🔧 Dummy notifications — replace with Firestore stream in production
  final List<NotificationModel> _notifications = [
    NotificationModel(
      id: 'n001',
      userId: 'user123',
      title: '🚨 Urgent Blood Request Nearby',
      body: 'A patient in City Hospital needs O+ blood urgently. '
          'You are within 2 km. Please respond if available.',
      type: 'blood_request',
      relatedId: 'req001',
      createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
      isRead: false,
    ),
    NotificationModel(
      id: 'n002',
      userId: 'user123',
      title: '🎉 Reward Points Earned',
      body: 'You earned 200 reward points for your last donation. '
          'You are now at Silver tier!',
      type: 'reward',
      relatedId: 'reward001',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
    ),
    NotificationModel(
      id: 'n003',
      userId: 'user123',
      title: '📅 Blood Drive This Weekend',
      body: 'A blood drive is scheduled at Jinnah Hospital on Saturday, '
          '10 AM – 4 PM. All blood groups needed. Come donate!',
      type: 'blood_drive',
      relatedId: 'drive001',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      isRead: true,
    ),
    NotificationModel(
      id: 'n004',
      userId: 'user123',
      title: '✅ You Are Eligible to Donate',
      body: '90 days have passed since your last donation. '
          'You are now eligible to donate blood again. Thank you!',
      type: 'eligibility',
      relatedId: null,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
    NotificationModel(
      id: 'n005',
      userId: 'user123',
      title: '🩸 SOS Alert: Critical Need',
      body: 'EMERGENCY: AB- blood needed at General Hospital within the '
          'next hour. Please contact 03001234567 immediately.',
      type: 'blood_request',
      relatedId: 'req002',
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      isRead: true,
    ),
    NotificationModel(
      id: 'n006',
      userId: 'user123',
      title: '🏆 New Certificate Unlocked',
      body: 'Congratulations! You have earned the "Life Saver" certificate '
          'for responding to an emergency donation.',
      type: 'reward',
      relatedId: 'cert003',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
    ),
    NotificationModel(
      id: 'n007',
      userId: 'user123',
      title: '📣 Blood Drive Reminder',
      body: 'Reminder: Community Blood Drive tomorrow at 9 AM at '
          'COMSATS University Vehari campus. Register now!',
      type: 'blood_drive',
      relatedId: 'drive002',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      isRead: true,
    ),
    NotificationModel(
      id: 'n008',
      userId: 'user123',
      title: '🔔 Blood Request Fulfilled',
      body: 'Great news! Your blood request for patient Ali has been '
          'fulfilled. A donor is on their way to City Hospital.',
      type: 'blood_request',
      relatedId: 'req003',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      isRead: true,
    ),
  ];

  List<NotificationModel> get _filtered {
    if (_selectedFilter == 'All') return _notifications;
    final typeMap = {
      'Blood Request': 'blood_request',
      'Blood Drive': 'blood_drive',
      'Eligibility': 'eligibility',
      'Reward': 'reward',
    };
    final key = typeMap[_selectedFilter];
    return _notifications.where((n) => n.type == key).toList();
  }

  int get _unreadCount =>
      _notifications.where((n) => !n.isRead).length;

  void _markAsRead(String id) {
    setState(() {
      final idx = _notifications.indexWhere((n) => n.id == id);
      if (idx != -1 && !_notifications[idx].isRead) {
        _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      }
    });
  }

  void _markAllRead() {
    setState(() {
      for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] =
              _notifications[i].copyWith(isRead: true);
        }
      }
    });
  }

  void _deleteNotification(String id) {
    setState(() => _notifications.removeWhere((n) => n.id == id));
  }

  // ─────────────────────────────────────────────
  // Type helpers
  // ─────────────────────────────────────────────
  Color _typeColor(String type) {
    switch (type) {
      case 'blood_request':
        return AppColors.primaryRed;
      case 'blood_drive':
        return AppColors.secondaryBlue;
      case 'eligibility':
        return AppColors.success;
      case 'reward':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'blood_request':
        return Icons.bloodtype;
      case 'blood_drive':
        return Icons.event;
      case 'eligibility':
        return Icons.check_circle;
      case 'reward':
        return Icons.star;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Text(
              'Notifications',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryRed,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'Mark all read',
                style:
                TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              children: _filters.map((f) {
                final selected = _selectedFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _selectedFilter = f),
                    selectedColor:
                    AppColors.primaryRed.withOpacity(0.15),
                    checkmarkColor: AppColors.primaryRed,
                    labelStyle: TextStyle(
                      color: selected
                          ? AppColors.primaryRed
                          : AppColors.textSecondary,
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // List
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (ctx, i) =>
                  _buildNotificationTile(filtered[i]),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Empty state
  // ─────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 70, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No notifications',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            'You\'re all caught up!',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Notification tile with swipe-to-delete
  // ─────────────────────────────────────────────
  Widget _buildNotificationTile(NotificationModel notif) {
    final color = _typeColor(notif.type);
    final isUnread = !notif.isRead;

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete_outline,
            color: Colors.white, size: 28),
      ),
      onDismissed: (_) => _deleteNotification(notif.id),
      child: GestureDetector(
        onTap: () {
          _markAsRead(notif.id);
          _showNotificationDetail(notif);
        },
        child: Container(
          margin:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color:
            isUnread ? Colors.white : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(14),
            border: isUnread
                ? Border.all(
                color: color.withOpacity(0.4), width: 1.5)
                : Border.all(
                color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 8),
            leading: Stack(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(_typeIcon(notif.type),
                      color: color, size: 22),
                ),
                if (isUnread)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              notif.title,
              style: TextStyle(
                fontWeight:
                isUnread ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
                color: isUnread
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 3),
                Text(
                  notif.body,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  _formatDate(notif.createdAt),
                  style: TextStyle(
                      fontSize: 11, color: color.withOpacity(0.8)),
                ),
              ],
            ),
            trailing: isUnread
                ? Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  color: color, shape: BoxShape.circle),
            )
                : null,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Detail bottom sheet
  // ─────────────────────────────────────────────
  void _showNotificationDetail(NotificationModel notif) {
    final color = _typeColor(notif.type);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.12),
                  radius: 24,
                  child: Icon(_typeIcon(notif.type),
                      color: color, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    notif.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              notif.body,
              style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.6),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.access_time_outlined,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 5),
                Text(
                  _fullDate(notif.createdAt),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Close',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _fullDate(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month]} ${dt.year}, $h:$m';
  }
}
