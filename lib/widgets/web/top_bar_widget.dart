import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TopBarWidget extends StatefulWidget {
  final String userName;
  final String userEmail;
  final VoidCallback onLogout;
  final Function(String) onSearch;
  final VoidCallback onNotification;
  final String? avatarUrl;

  const TopBarWidget({
    Key? key,
    required this.userName,
    required this.userEmail,
    required this.onLogout,
    required this.onSearch,
    required this.onNotification,
    this.avatarUrl,
  }) : super(key: key);

  @override
  State<TopBarWidget> createState() => _TopBarWidgetState();
}

class _TopBarWidgetState extends State<TopBarWidget> {
  final TextEditingController _searchController = TextEditingController();
  bool _hasNotifications = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Search Bar
          Expanded(
            child: Container(
              height: 45,
              constraints: const BoxConstraints(maxWidth: 500),
              child: TextField(
                controller: _searchController,
                onSubmitted: widget.onSearch,
                decoration: InputDecoration(
                  hintText: 'Search anything...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      widget.onSearch('');
                      setState(() {});
                    },
                  )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: (value) {
                  setState(() {});
                  widget.onSearch(value);
                },
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Action Buttons
          Row(
            children: [
              // Notification Button
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: widget.onNotification,
                    icon: const Icon(Icons.notifications_none),
                    tooltip: 'Notifications',
                  ),
                  if (_hasNotifications)
                    Positioned(
                      right: 5,
                      top: 5,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              // Settings Button
              IconButton(
                onPressed: () {
                  // Navigate to settings
                },
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Settings',
              ),
              const SizedBox(width: 8),
              // Divider
              Container(
                width: 1,
                height: 30,
                color: Colors.grey.shade300,
              ),
              const SizedBox(width: 16),
              // User Profile
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'logout') {
                    widget.onLogout();
                  } else if (value == 'profile') {
                    // Navigate to profile
                  }
                },
                itemBuilder: (context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 18),
                        SizedBox(width: 12),
                        Text('My Profile'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings, size: 18),
                        SizedBox(width: 12),
                        Text('Account Settings'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider<String>(),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 18, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Logout', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: widget.avatarUrl != null
                          ? NetworkImage(widget.avatarUrl!)
                          : null,
                      backgroundColor: Colors.red.shade100,
                      child: widget.avatarUrl == null
                          ? Text(
                        widget.userName[0].toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.userName,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        Text(
                          widget.userEmail,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}