import '../constants/app_constants.dart';

class AppDateUtils {
  static bool isEligible(DateTime? lastDonationDate) {
    if (lastDonationDate == null) return true;
    final daysPassed = DateTime.now().difference(lastDonationDate).inDays;
    return daysPassed >= AppConstants.minDaysBetweenDonations;
  }

  static int daysRemaining(DateTime lastDonationDate) {
    final daysPassed = DateTime.now().difference(lastDonationDate).inDays;
    final remaining = AppConstants.minDaysBetweenDonations - daysPassed;
    return remaining < 0 ? 0 : remaining;
  }

  static DateTime nextEligibleDate(DateTime lastDonationDate) {
    return lastDonationDate
        .add(Duration(days: AppConstants.minDaysBetweenDonations));
  }

  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} months ago';
    if (diff.inDays > 0) return '${diff.inDays} days ago';
    if (diff.inHours > 0) return '${diff.inHours} hours ago';
    return 'Just now';
  }
}