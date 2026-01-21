import '../constants/app_constants.dart';

/// Utility class for checking donor eligibility
class EligibilityChecker {
  /// Check if donor is eligible based on last donation date
  static bool isEligibleForDonation(DateTime? lastDonationDate) {
    if (lastDonationDate == null) {
      return true; // First-time donor
    }

    DateTime now = DateTime.now();
    int daysSinceLastDonation = now.difference(lastDonationDate).inDays;

    return daysSinceLastDonation >= AppConstants.minDaysBetweenDonations;
  }

  /// Get days until eligible
  static int? daysUntilEligible(DateTime? lastDonationDate) {
    if (lastDonationDate == null) {
      return 0; // Already eligible
    }

    DateTime now = DateTime.now();
    int daysSinceLastDonation = now.difference(lastDonationDate).inDays;
    int daysUntilEligible =
        AppConstants.minDaysBetweenDonations - daysSinceLastDonation;

    return daysUntilEligible > 0 ? daysUntilEligible : 0;
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
