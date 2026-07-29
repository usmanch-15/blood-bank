import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';

/// ⚠️ NOT CURRENTLY WIRED — no admin screen imports this yet.
/// ⚠️ DUPLICATE CLASS NAME with lib/screens/admin/web/admin_widgets/top_bar_widget.dart
/// — see the note there. This is the more feature-complete of the two
/// (supports avatarUrl, inline user name/email, clear-search button), so
/// treat THIS as the canonical one going forward.
class TopBarWidget extends StatefulWidget {
  final String userName;
  final String userEmail;
  final VoidCallback onLogout;
  final Function(String) onSearch;
  final VoidCallback onNotification;
  final String? avatarUrl;

  const TopBarWidget({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.onLogout,
    required this.onSearch,
    required this.onNotification,
    this.avatarUrl,
  });

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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Container(
              height: 46,
              constraints: const BoxConstraints(maxWidth: 500),
              child: TextField(
                controller: _searchController,
                onSubmitted: widget.onSearch,
                decoration: InputDecoration(
                  hintText: 'Search anything...',
                  prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
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
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.backgroundLight,
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                ),
                onChanged: (value) {
                  setState(() {});
                  widget.onSearch(value);
                },
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xxl),
          Row(
            children: [
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
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Settings',
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(width: 1, height: 30, color: Colors.grey.shade300),
              const SizedBox(width: AppSpacing.md),
              PopupMenuButton<String>(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                onSelected: (value) {
                  if (value == 'logout') {
                    widget.onLogout();
                  } else if (value == 'profile') {
                    // Navigate to profile
                  }
                },
                itemBuilder: (context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(children: [
                      Icon(Icons.person, size: 18),
                      SizedBox(width: 12),
                      Text('My Profile'),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(children: [
                      Icon(Icons.settings, size: 18),
                      SizedBox(width: 12),
                      Text('Account Settings'),
                    ]),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(children: [
                      const Icon(Icons.logout, size: 18, color: AppColors.error),
                      const SizedBox(width: 12),
                      Text('Logout', style: TextStyle(color: AppColors.error)),
                    ]),
                  ),
                ],
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: widget.avatarUrl != null ? NetworkImage(widget.avatarUrl!) : null,
                      backgroundColor: AppColors.primaryRed.withOpacity(0.12),
                      child: widget.avatarUrl == null
                          ? Text(
                        widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : '?',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryRed),
                      )
                          : null,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.userName, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        Text(widget.userEmail, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                    const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
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