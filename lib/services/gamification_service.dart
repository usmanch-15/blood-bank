/// ✅ PHASE 3 — Gamification: Levels & Badges
/// Pure calculation logic based on donationCount / rewardPoints already
/// stored on the user document. No new Firestore writes needed — this
/// just derives a level/badge from existing data.
class GamificationService {
  /// Returns a level name based on total donations.
  static String levelForDonationCount(int donationCount) {
    if (donationCount >= 20) return 'Legend';
    if (donationCount >= 10) return 'Hero';
    if (donationCount >= 5) return 'Champion';
    if (donationCount >= 1) return 'Donor';
    return 'Newcomer';
  }

  /// Returns the icon/emoji associated with a level, for quick display.
  static String iconForLevel(String level) {
    switch (level) {
      case 'Legend':
        return '👑';
      case 'Hero':
        return '🏆';
      case 'Champion':
        return '🥇';
      case 'Donor':
        return '🩸';
      default:
        return '🌱';
    }
  }

  /// Returns donations needed to reach the next level, or null if already
  /// at max level.
  static int? donationsToNextLevel(int donationCount) {
    const thresholds = [1, 5, 10, 20];
    for (final t in thresholds) {
      if (donationCount < t) return t - donationCount;
    }
    return null; // already at max level (Legend)
  }

  /// List of badge ids the user has earned, based on donation count and
  /// other milestones you track (e.g. profile completeness, referrals).
  static List<String> earnedBadges({
    required int donationCount,
    bool isVerified = false,
    int referralCount = 0,
  }) {
    final badges = <String>[];
    if (donationCount >= 1) badges.add('first_donation');
    if (donationCount >= 5) badges.add('regular_donor');
    if (donationCount >= 10) badges.add('hero_donor');
    if (isVerified) badges.add('verified_donor');
    if (referralCount >= 3) badges.add('community_builder');
    return badges;
  }

  static String badgeLabel(String badgeId) {
    switch (badgeId) {
      case 'first_donation':
        return 'First Donation';
      case 'regular_donor':
        return 'Regular Donor (5+)';
      case 'hero_donor':
        return 'Hero Donor (10+)';
      case 'verified_donor':
        return 'Verified';
      case 'community_builder':
        return 'Community Builder';
      default:
        return badgeId;
    }
  }
}