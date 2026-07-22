import '../constants/app_constants.dart';

/// Utility class for checking donor eligibility
class EligibilityChecker {
  /// Returns the exact UTC instant at which the donor becomes eligible again.
  static DateTime? nextEligibleDate(DateTime? lastDonationDate) {
    if (lastDonationDate == null) return null;
    final lastUtc = lastDonationDate.toUtc();
    return lastUtc.add(
      Duration(days: AppConstants.minDaysBetweenDonations),
    );
  }

  /// Check if donor is eligible based on last donation date.
  /// FIX: previously used DateTime.now() in the device's local timezone
  /// combined with Duration.inDays, which truncates the time-of-day
  /// component. That caused donors to be marked eligible/ineligible up to
  /// ~24 hours early or late depending on the device timezone and the time
  /// of day the last donation was recorded. We now compare UTC instants
  /// directly, so the 90-day window is exact down to the second.
  static bool isEligibleForDonation(DateTime? lastDonationDate) {
    if (lastDonationDate == null) {
      return true; // First-time donor
    }

    final nowUtc = DateTime.now().toUtc();
    final eligibleFrom = nextEligibleDate(lastDonationDate)!;

    return !nowUtc.isBefore(eligibleFrom);
  }

  /// Get days until eligible (rounded up, so "less than a day left" still
  /// shows as 1 day rather than 0, which would incorrectly read as eligible).
  static int? daysUntilEligible(DateTime? lastDonationDate) {
    if (lastDonationDate == null) {
      return 0; // Already eligible
    }

    final nowUtc = DateTime.now().toUtc();
    final eligibleFrom = nextEligibleDate(lastDonationDate)!;

    if (!nowUtc.isBefore(eligibleFrom)) return 0;

    final remaining = eligibleFrom.difference(nowUtc);
    final daysLeft = (remaining.inHours / 24).ceil();

    return daysLeft > 0 ? daysLeft : 0;
  }

  /// Get eligibility message
  static String getEligibilityMessage(DateTime? lastDonationDate) {
    if (isEligibleForDonation(lastDonationDate)) {
      return 'You are eligible to donate blood!';
    }

    int? daysLeft = daysUntilEligible(lastDonationDate);
    if (daysLeft != null && daysLeft > 0) {
      return 'You can donate again in $daysLeft days';
    }

    return 'You are eligible to donate blood!';
  }
}