import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/notification_model.dart';
import '../../../constants/app_colors.dart';

class AdminWebNotifications extends StatefulWidget {
  const AdminWebNotifications({Key? key}) : super(key: key);

  @override
  State<AdminWebNotifications> createState() =>
      _AdminWebNotificationsState();
}

class _AdminWebNotificationsState extends State<AdminWebNotifications>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Compose form controllers
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _targetType = 'all'; // all | donor | receiver
  String _notificationType = 'blood_request'; // blood_request | blood_drive | eligibility | reward
  bool _isSending = false;

  final List<Map<String, dynamic>> _targetOptions = [
    {'value': 'all', 'label': 'All Users', 'icon': Icons.people},
    {'value': 'donor', 'label': 'Donors Only', 'icon': Icons.favorite},
    {'value': 'receiver', 'label': 'Receivers Only', 'icon': Icons.person_search},
  ];

  final List<Map<String, dynamic>> _typeOptions = [
    {'value': 'blood_request', 'label': 'Blood Request', 'icon': Icons.bloodtype},
    {'value': 'blood_drive', 'label': 'Blood Drive', 'icon': Icons.campaign},
    {'value': 'eligibility', 'label': 'Eligibility Update', 'icon': Icons.health_and_safety},
    {'value': 'reward', 'label': 'Reward', 'icon': Icons.stars},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Stream<List<NotificationModel>> _getAllNotifications() {
    return FirebaseFirestore.instance
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => NotificationModel.fromFirestore(
        d.data() as Map<String, dynamic>, d.id))
        .toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Send broadcast notifications & view history',
                    style: TextStyle(
                        fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Tabs ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.red.shade700,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: Colors.red.shade700,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send, size: 16),
                      SizedBox(width: 8),
                      Text('Send Notification'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 16),
                      SizedBox(width: 8),
                      Text('History'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildComposeTab(),
              _buildHistoryTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ── Compose tab ──────────────────────────────────────────────
  Widget _buildComposeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compose form
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Compose Notification',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Target audience
                  const Text('Target Audience',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 10),
                  Row(
                    children: _targetOptions.map((opt) {
                      final isSelected = _targetType == opt['value'];
                      return Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _targetType = opt['value']),
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.red.shade50
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.red.shade400
                                    : Colors.grey.shade200,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  opt['icon'] as IconData,
                                  color: isSelected
                                      ? Colors.red.shade700
                                      : Colors.grey.shade500,
                                  size: 22,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  opt['label'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Colors.red.shade700
                                        : Colors.grey.shade600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Notification type
                  const Text('Notification Type',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _typeOptions.map((opt) {
                      final isSelected = _notificationType == opt['value'];
                      return GestureDetector(
                        onTap: () => setState(
                                () => _notificationType = opt['value']),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.red.shade50
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.red.shade400
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(opt['icon'] as IconData,
                                  size: 14,
                                  color: isSelected
                                      ? Colors.red.shade700
                                      : Colors.grey.shade600),
                              const SizedBox(width: 6),
                              Text(
                                opt['label'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected
                                      ? Colors.red.shade700
                                      : Colors.grey.shade600,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Title
                  const Text('Title',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. Urgent Blood Needed in Lahore',
                      hintStyle: TextStyle(
                          color: Colors.grey.shade400, fontSize: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                        BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                        BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                        BorderSide(color: Colors.red.shade400),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Body
                  const Text('Message Body',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bodyCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText:
                      'Write the full notification message here...',
                      hintStyle: TextStyle(
                          color: Colors.grey.shade400, fontSize: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                        BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                        BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                        BorderSide(color: Colors.red.shade400),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Send button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isSending ? null : _sendNotification,
                      icon: _isSending
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                          : const Icon(Icons.send),
                      label: Text(
                        _isSending ? 'Sending...' : 'Send Notification',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 20),

          // Preview panel
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Preview',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),

                  // Notification preview card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.bloodtype,
                                  color: Colors.red.shade700, size: 18),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Blood Connect',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13),
                              ),
                            ),
                            Text('now',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade400)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ListenableBuilder(
                          listenable: _titleCtrl,
                          builder: (_, __) => Text(
                            _titleCtrl.text.isEmpty
                                ? 'Notification Title'
                                : _titleCtrl.text,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: _titleCtrl.text.isEmpty
                                  ? Colors.grey.shade400
                                  : Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        ListenableBuilder(
                          listenable: _bodyCtrl,
                          builder: (_, __) => Text(
                            _bodyCtrl.text.isEmpty
                                ? 'Your message will appear here...'
                                : _bodyCtrl.text,
                            style: TextStyle(
                              fontSize: 12,
                              color: _bodyCtrl.text.isEmpty
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade700,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Send summary
                  _infoRow(Icons.people, 'Target',
                      _targetOptions.firstWhere((o) =>
                      o['value'] == _targetType)['label'] as String),
                  const SizedBox(height: 8),
                  _infoRow(
                      Icons.label,
                      'Type',
                      _typeOptions.firstWhere((o) =>
                      o['value'] ==
                          _notificationType)['label'] as String),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade400),
        const SizedBox(width: 8),
        Text('$label: ',
            style: TextStyle(
                fontSize: 12, color: Colors.grey.shade500)),
        Text(value,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ── History tab ──────────────────────────────────────────────
  Widget _buildHistoryTab() {
    return StreamBuilder<List<NotificationModel>>(
      stream: _getAllNotifications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child:
              CircularProgressIndicator(color: AppColors.primaryRed));
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('Error: ${snapshot.error}',
                  style: TextStyle(color: Colors.red.shade400)));
        }

        final notifications = snapshot.data ?? [];

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text('No notifications sent yet',
                    style: TextStyle(
                        fontSize: 16, color: Colors.grey.shade500)),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '${notifications.length} notification${notifications.length == 1 ? '' : 's'}',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ListView.separated(
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: Colors.grey.shade100),
                      itemBuilder: (_, i) =>
                          _buildNotificationTile(notifications[i]),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationTile(NotificationModel n) {
    final typeColor = _notifTypeColor(n.type);
    return ListTile(
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: typeColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(_notifTypeIcon(n.type), color: typeColor, size: 20),
      ),
      title: Text(
        n.title,
        style:
        const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(n.body,
              style: TextStyle(
                  fontSize: 12, color: Colors.grey.shade600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  n.type.replaceAll('_', ' '),
                  style: TextStyle(
                      fontSize: 10,
                      color: typeColor,
                      fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDate(n.createdAt),
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade400),
              ),
              const SizedBox(width: 8),
              if (n.isRead)
                Icon(Icons.done_all,
                    size: 14, color: Colors.blue.shade400)
              else
                Icon(Icons.done,
                    size: 14, color: Colors.grey.shade400),
            ],
          ),
        ],
      ),
    );
  }

  // ── Send notification to Firestore ────────────────────────────
  Future<void> _sendNotification() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in both title and message'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final db = FirebaseFirestore.instance;

      // Get target users
      Query usersQuery = db.collection('users');
      if (_targetType != 'all') {
        usersQuery = usersQuery.where('role', isEqualTo: _targetType);
      }
      final usersSnap = await usersQuery.get();

      // Batch write notifications
      final batch = db.batch();
      for (final userDoc in usersSnap.docs) {
        final notifRef = db.collection('notifications').doc();
        batch.set(notifRef, {
          'userId': userDoc.id,
          'title': title,
          'body': body,
          'type': _notificationType,
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
          'data': {
            'sentByAdmin': true,
            'target': _targetType,
          },
        });
      }
      await batch.commit();

      if (mounted) {
        _titleCtrl.clear();
        _bodyCtrl.clear();
        setState(() {
          _isSending = false;
          _targetType = 'all';
          _notificationType = 'blood_request';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✓ Notification sent to ${usersSnap.size} user${usersSnap.size == 1 ? '' : 's'}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );

        // Switch to history tab
        _tabController.animateTo(1);
      }
    } catch (e) {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _notifTypeColor(String type) {
    switch (type) {
      case 'blood_request':
        return Colors.red;
      case 'blood_drive':
        return Colors.orange;
      case 'eligibility':
        return Colors.green;
      case 'reward':
        return Colors.amber;
      default:
        return Colors.blue;
    }
  }

  IconData _notifTypeIcon(String type) {
    switch (type) {
      case 'blood_request':
        return Icons.bloodtype;
      case 'blood_drive':
        return Icons.campaign;
      case 'eligibility':
        return Icons.health_and_safety;
      case 'reward':
        return Icons.stars;
      default:
        return Icons.notifications;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_month(date.month)} ${date.year}';
  }

  String _month(int m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m - 1];
  }
}