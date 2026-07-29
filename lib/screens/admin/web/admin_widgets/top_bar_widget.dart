import 'package:flutter/material.dart';
import '../../../../constants/app_colors.dart';
import '../../../../constants/app_spacing.dart';

/// ⚠️ NOT CURRENTLY WIRED — none of the admin_web_*.dart screens use this;
/// they each build their own inline AppBar. Polished for future use.
///
/// ⚠️ DUPLICATE CLASS NAME — lib/widgets/web/top_bar_widget.dart also
/// defines a `TopBarWidget` (a more feature-complete version — supports
/// avatarUrl, a clear-search button, and shows userName/userEmail inline).
/// Since neither file is ever imported into the same file as the other,
/// this doesn't currently cause a compile conflict, but it IS genuine
/// duplication. Recommendation: keep lib/widgets/web/top_bar_widget.dart
/// as the one true version going forward and delete this file once
/// something actually imports the other one — not done here since
/// deleting could break something. Copy-paste note if adopting this
/// widget: import ONE of the two, never both in the same screen.
class TopBarWidget extends StatefulWidget {
  final String userName;
  final String userEmail;
  final VoidCallback onLogout;
  final Function(String) onSearch;
  final VoidCallback onNotification;

  const TopBarWidget({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.onLogout,
    required this.onSearch,
    required this.onNotification,
  });

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
          _buildSearchBar(),
          const SizedBox(width: AppSpacing.xl),
          _buildUserSection(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Expanded(
      child: Container(
        height: 46,
        constraints: const BoxConstraints(maxWidth: 420),
        child: TextField(
          controller: _searchController,
          onSubmitted: widget.onSearch,
          decoration: InputDecoration(
            hintText: 'Search...',
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
          onChanged: (_) => setState(() {}),
        ),
      ),
    );
  }

  Widget _buildUserSection() {
    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: widget.onNotification,
              tooltip: 'Notifications',
              icon: const Icon(Icons.notifications_none),
            ),
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
              ),
            ),
          ],
        ),
        const SizedBox(width: AppSpacing.md),
        Container(width: 1, height: 30, color: Colors.grey.shade300),
        const SizedBox(width: AppSpacing.md),
        PopupMenuButton<String>(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
          onSelected: (value) {
            if (value == 'logout') widget.onLogout();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profile',
              child: Row(children: [
                Icon(Icons.person, size: 18),
                SizedBox(width: 12),
                Text('Profile'),
              ]),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(children: [
                Icon(Icons.settings, size: 18),
                SizedBox(width: 12),
                Text('Settings'),
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
                backgroundColor: AppColors.primaryRed.withOpacity(0.12),
                child: Text(
                  widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryRed),
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.userName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  Text(widget.userEmail,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
              const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
            ],
          ),
        ),
      ],
    );
  }
}