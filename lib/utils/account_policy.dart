/// Shared policy for interactive login and restored sessions.
class AccountPolicy {
  static bool isActive(Map<String, dynamic>? data) =>
      data != null &&
      data['status'] == 'approved' &&
      const ['donor', 'receiver', 'admin'].contains(data['role']);

  static String route(Map<String, dynamic> data) =>
      data['role'] == 'admin' ? '/admin/dashboard' : '/role-select';

  static bool canSwitchMode(String? role, String mode) =>
      const ['donor', 'receiver'].contains(role) &&
      const ['donor', 'receiver'].contains(mode);
}
