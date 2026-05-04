import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/web/stat_card_widget.dart';

class AdminWebNotifications extends StatefulWidget {
  const AdminWebNotifications({Key? key}) : super(key: key);

  @override
  State<AdminWebNotifications> createState() => _AdminWebNotificationsState();
}

class _AdminWebNotificationsState extends State<AdminWebNotifications> {
  String _typeFilter = 'All';

  final List<_NotificationItem> _notifications = [
    _NotificationItem(
      id: 'NTF-001',
      title: 'SOS Alert: O- Blood Needed',
      body: 'Urgent request for O- blood at City Hospital.',
      type: 'SOS',
      recipients: 'All O- Donors',
      sentAt: '2024-06-10 09:15',
      isRead: true,
    ),
    _NotificationItem(
      id: 'NTF-002',
      title: 'Blood Drive: Karachi Expo Center',
      body: 'Join us on 20 June for a community blood drive.',
      type: 'Blood Drive',
      recipients: 'All Users',
      sentAt: '2024-06-09 14:30',
      isRead: true,
    ),
    _NotificationItem(
      id: 'NTF-003',
      title: 'Eligibility Reminder',
      body: 'You are now eligible to donate blood again.',
      type: 'Reminder',
      recipients: '42 Donors',
      sentAt: '2024-06-08 08:00',
      isRead: false,
    ),
    _NotificationItem(
      id: 'NTF-004',
      title: 'Donation Verified',
      body: 'Your recent donation at Aga Khan Hospital has been verified.',
      type: 'System',
      recipients: 'Bilal Raza',
      sentAt: '2024-06-07 16:45',
      isRead: true,
    ),
    _NotificationItem(
      id: 'NTF-005',
      title: 'SOS Alert: AB+ Blood Needed',
      body: 'Critical need for AB+ blood at PIMS Hospital.',
      type: 'SOS',
      recipients: 'All AB+ Donors',
      sentAt: '2024-06-07 11:20',
      isRead: false,
    ),
    _NotificationItem(
      id: 'NTF-006',
      title: 'New Misuse Report Filed',
      body: 'A misuse report has been submitted for admin review.',
      type: 'System',
      recipients: 'Admins',
      sentAt: '2024-06-06 13:10',
      isRead: true,
    ),
    _NotificationItem(
      id: 'NTF-007',
      title: 'Monthly Newsletter',
      body: 'Check out this month\'s donation statistics and stories.',
      type: 'Announcement',
      recipients: 'All Users',
      sentAt: '2024-06-01 10:00',
      isRead: true,
    ),
    _NotificationItem(
      id: 'NTF-008',
      title: 'Reward Points Credited',
      body: 'You earned 50 reward points for your latest donation.',
      type: 'Reminder',
      recipients: 'Ali Hassan',
      sentAt: '2024-05-30 09:00',
      isRead: false,
    ),
  ];

  List<_NotificationItem> get _filtered {
    if (_typeFilter == 'All') return _notifications;
    return _notifications.where((n) => n.type == _typeFilter).toList();
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;
  int get _sosCount =>
      _notifications.where((n) => n.type == 'SOS').length;
  int get _announcementCount =>
      _notifications.where((n) => n.type == 'Announcement').length;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildStatCards(),
          const SizedBox(height: 24),
          _buildFilterRow(),
          const SizedBox(height: 16),
          _buildNotificationList(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifications',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            Text(
              'Send and manage system-wide notifications',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        Row(
          children: [
            if (_unreadCount > 0)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: TextButton.icon(
                  onPressed: () =>
                      setState(() => _notifications.forEach((n) => n.isRead = true)),
                  icon: const Icon(Icons.done_all, size: 18),
                  label: Text('Mark all read ($_unreadCount)'),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                ),
              ),
            ElevatedButton.icon(
              onPressed: () => _showSendNotificationDialog(context),
              icon: const Icon(Icons.send),
              label: const Text('Send Notification'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCards() {
    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        StatCardWidget(
          title: 'Total Sent',
          value: '${_notifications.length}',
          icon: Icons.notifications,
          color: Colors.blue,
          percentage: '+10%',
        ),
        StatCardWidget(
          title: 'Unread',
          value: '$_unreadCount',
          icon: Icons.mark_email_unread,
          color: Colors.orange,
          percentage: '+2%',
        ),
        StatCardWidget(
          title: 'SOS Alerts',
          value: '$_sosCount',
          icon: Icons.emergency,
          color: Colors.red,
          percentage: '+1%',
        ),
        StatCardWidget(
          title: 'Announcements',
          value: '$_announcementCount',
          icon: Icons.campaign,
          color: Colors.green,
          percentage: '+5%',
        ),
      ],
    );
  }

  Widget _buildFilterRow() {
    final types = ['All', 'SOS', 'Blood Drive', 'Reminder', 'System', 'Announcement'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: types.map((type) {
          final isSelected = _typeFilter == type;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(type),
              selected: isSelected,
              onSelected: (_) => setState(() => _typeFilter = type),
              selectedColor: Colors.red.shade50,
              checkmarkColor: Colors.red.shade700,
              labelStyle: GoogleFonts.poppins(
                color: isSelected ? Colors.red.shade700 : Colors.grey.shade700,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotificationList() {
    if (_filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(60),
          child: Column(
            children: [
              Icon(Icons.notifications_none,
                  size: 60, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No notifications found',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _filtered.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = _filtered[index];
          return _buildNotificationTile(context, item);
        },
      ),
    );
  }

  Widget _buildNotificationTile(BuildContext context, _NotificationItem item) {
    return InkWell(
      onTap: () {
        setState(() => item.isRead = true);
        _showNotificationDetailDialog(context, item);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        color: item.isRead ? null : Colors.red.shade50.withOpacity(0.4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _typeColor(item.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _typeIcon(item.type),
                color: _typeColor(item.type),
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (!item.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          item.title,
                          style: GoogleFonts.poppins(
                            fontWeight: item.isRead
                                ? FontWeight.normal
                                : FontWeight.w600,
                            fontSize: 14,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                      _buildTypeBadge(item.type),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.body,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.people_outline,
                          size: 13, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        item.recipients,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.access_time,
                          size: 13, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        item.sentAt,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  size: 18, color: Colors.grey.shade400),
              onPressed: () =>
                  setState(() => _notifications.remove(item)),
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _typeColor(type).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _typeColor(type),
        ),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'SOS':
        return Colors.red;
      case 'Blood Drive':
        return Colors.blue;
      case 'Reminder':
        return Colors.orange;
      case 'Announcement':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'SOS':
        return Icons.emergency;
      case 'Blood Drive':
        return Icons.event;
      case 'Reminder':
        return Icons.alarm;
      case 'Announcement':
        return Icons.campaign;
      default:
        return Icons.notifications;
    }
  }

  void _showNotificationDetailDialog(
      BuildContext context, _NotificationItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_typeIcon(item.type), color: _typeColor(item.type)),
            const SizedBox(width: 8),
            Expanded(child: Text(item.title)),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.body, style: GoogleFonts.poppins(fontSize: 14)),
              const Divider(height: 24),
              _detailRow('Type', item.type),
              _detailRow('Recipients', item.recipients),
              _detailRow('Sent At', item.sentAt),
              _detailRow('Status', item.isRead ? 'Read' : 'Unread'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Text(value, style: GoogleFonts.poppins(fontSize: 13)),
        ],
      ),
    );
  }

  void _showSendNotificationDialog(BuildContext context) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    String selectedType = 'Announcement';
    String selectedRecipients = 'All Users';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Send New Notification'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Notification Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bodyController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Message Body',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Notification Type',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Announcement', 'Reminder', 'SOS', 'Blood Drive', 'System']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => selectedType = v ?? selectedType),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRecipients,
                  decoration: const InputDecoration(
                    labelText: 'Recipients',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    'All Users',
                    'All Donors',
                    'All Receivers',
                    'Admins',
                    'Specific Blood Group',
                  ]
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setDialogState(
                      () => selectedRecipients = v ?? selectedRecipients),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.send),
              label: const Text('Send'),
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationItem {
  final String id;
  final String title;
  final String body;
  final String type;
  final String recipients;
  final String sentAt;
  bool isRead;

  _NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.recipients,
    required this.sentAt,
    required this.isRead,
  });
}
