// ✅ part of hata diya — ab standalone file hai
import 'package:flutter/material.dart';

class TopBarWidget extends StatefulWidget {
  final String userName;
  final String userEmail;
  final VoidCallback onLogout;
  final Function(String) onSearch;
  final VoidCallback onNotification;

  const TopBarWidget({
    Key? key,
    required this.userName,
    required this.userEmail,
    required this.onLogout,
    required this.onSearch,
    required this.onNotification,
  }) : super(key: key);

  @override
  State<TopBarWidget> createState() => _TopBarWidgetState();
}

class _TopBarWidgetState extends State<TopBarWidget> {
  final TextEditingController _searchController = TextEditingController();

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
          _buildSearchBar(),
          _buildUserSection(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Expanded(
      child: Container(
        height: 45,
        constraints: const BoxConstraints(maxWidth: 400),
        child: TextField(
          controller: _searchController,
          onSubmitted: widget.onSearch,
          decoration: InputDecoration(
            hintText: 'Search...',
            prefixIcon: const Icon(Icons.search, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildUserSection() {
    return Row(
      children: [
        IconButton(
          onPressed: widget.onNotification,
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_none),
              Positioned(
                right: 0,
                top: 0,
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
        ),
        const SizedBox(width: 16),
        Container(width: 1, height: 30, color: Colors.grey.shade300),
        const SizedBox(width: 16),
        PopupMenuButton(
          onSelected: (value) {
            if (value == 'logout') widget.onLogout();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'profile', child: Row(children: [Icon(Icons.person, size: 18), SizedBox(width: 12), Text('Profile')])),
            const PopupMenuItem(value: 'settings', child: Row(children: [Icon(Icons.settings, size: 18), SizedBox(width: 12), Text('Settings')])),
            const PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout, size: 18, color: Colors.red), SizedBox(width: 12), Text('Logout', style: TextStyle(color: Colors.red))])),
          ],
          child: CircleAvatar(
            radius: 20,
            backgroundColor: Colors.red.shade100,
            child: Text(
              widget.userName[0].toUpperCase(),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red.shade700),
            ),
          ),
        ),
      ],
    );
  }
}