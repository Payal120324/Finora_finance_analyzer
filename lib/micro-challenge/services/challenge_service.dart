import '../models/challenge.dart';
import '../models/badge.dart';
import 'badge_service.dart';
class ChallengeService {
  List<Challenge> getChallenges() {
   return [
    Challenge(
      id: '1',
      title: 'Budget Master 💰',
      description: 'Stay within your weekly budget for 7 days straight',
      badgeId: 'badge_budget_master',
      animationPath: 'assets/budget_ninja.json',
      
    ),
  Challenge(
      id: '2',
      title: 'No Spend Days 🚫',
      description: 'Complete 3 no-spend days this week',
      badgeId: 'badge_no_spend',
      animationPath: 'assets/discipline_seeker.json',
    ),
  Challenge(
      id: '3',
      title: 'Cash Tracker 📊',
      description: 'Log every single expense for 7 days',
      badgeId: 'badge_cash_tracker',
      animationPath: 'assets/consistent.json',
     
    ),
    Challenge(
      id: '4',
      title: 'Meal Planner 🍱',
      description: 'Cook all meals at home for 5 days straight',
      badgeId: 'badge_meal_planner',
      animationPath: 'assets/badge_meal_planner.json',
    ),
 Challenge(
      id: '5',
      title: 'Digital Detox 📵',
      description: 'No online shopping for the entire week',
      badgeId: 'badge_digital_detox',
      animationPath: 'assets/weekly_saver.json',
    ),
  Challenge(
      id: '6',
      title: 'Savings Boost 🐷',
      description: 'Save an extra ₹1000 this week',
      badgeId: 'badge_savings_boost',
      animationPath: 'assets/small_saver.json',
    ),
Challenge(
      id: '7',
      title: 'Subscription Audit 🔍',
      description: 'Cancel one unused subscription this week',
      badgeId: 'badge_subscription_audit',
      animationPath: 'assets/mindful_spender.json',

    ),
Challenge(
      id: '8',
      title: 'Impulse Control 🎯',
      description: 'No impulse purchases for 7 days',
      badgeId: 'badge_impulse_control',
      animationPath: 'assets/goal_crusher.json',
    ),
 Challenge(
      id: '9',
      title: 'Cash Envelope 💳',
      description: 'Use only cash for discretionary spending',
      badgeId: 'badge_cash_envelope',
      animationPath: 'assets/envelope.json',
    ),
Challenge(
      id: '10',
      title: 'Financial Reading 📚',
      description: 'Read 30 minutes of financial content daily',
      badgeId: 'badge_financial_reader',
      animationPath: 'assets/reader.json',
    ),
  ];
  }

  /// Fetches all available badges from the challenge service
  List<Badge> getAllBadges() {
    final challenges = getChallenges();
    return challenges.map((challenge) => Badge.fromChallenge(
      id: challenge.id,
      title: challenge.title,
      description: challenge.description,
      badgeId: challenge.badgeId,
      animationPath: challenge.animationPath,
      difficulty: _getDifficultyFromTitle(challenge.title),
      category: _getCategoryFromTitle(challenge.title),
      icon: _getBadgeIconFromTitle(challenge.title),
    )).toList();
  }

  /// Helper method to determine difficulty from title
  static int _getDifficultyFromTitle(String title) {
    // Simple mapping based on title complexity
    if (title.contains('Master') || title.contains('Boost')) return 5;
    if (title.contains('Audit') || title.contains('Control')) return 4;
    if (title.contains('Tracker') || title.contains('Envelope')) return 3;
    if (title.contains('Days') || title.contains('Reading')) return 2;
    return 1;
  }

  /// Helper method to determine category from title
  static String _getCategoryFromTitle(String title) {
    if (title.contains('Budget') || title.contains('Cash')) return 'Budgeting';
    if (title.contains('Spend') || title.contains('Impulse')) return 'Spending Control';
    if (title.contains('Savings') || title.contains('Envelope')) return 'Saving';
    if (title.contains('Meal') || title.contains('Reading')) return 'Lifestyle';
    if (title.contains('Subscription') || title.contains('Digital')) return 'Digital Wellness';
    return 'General';
  }

  /// Helper method to get badge icon from title
  static String _getBadgeIconFromTitle(String title) {
    final iconMap = {
      'Budget Master': '🏆',
      'No Spend Days': '🚫',
      'Cash Tracker': '📊',
      'Meal Planner': '🍱',
      'Digital Detox': '📵',
      'Savings Boost': '🐷',
      'Subscription Audit': '🔍',
      'Impulse Control': '🎯',
      'Cash Envelope': '💳',
      'Financial Reading': '📚',
    };
    
    return iconMap[title] ?? '🏅';
  }

  /// Fetches badges with their unlock status
  Future<List<Badge>> getAllBadgesWithStatus() async {
    final challenges = getChallenges();
    final badges = <Badge>[];
    
    for (final challenge in challenges) {
      // Check actual unlock status from BadgeService
      final badgeService = BadgeService();
      final isUnlocked = await badgeService.isBadgeUnlocked(challenge.badgeId);
      
      badges.add(Badge.fromChallenge(
        id: challenge.id,
        title: challenge.title,
        description: challenge.description,
        badgeId: challenge.badgeId,
        animationPath: challenge.animationPath,
        difficulty: _getDifficultyFromTitle(challenge.title),
        category: _getCategoryFromTitle(challenge.title),
        icon: _getBadgeIconFromTitle(challenge.title),
        isUnlocked: isUnlocked,
      ));
    }
    
    return badges;
  }

  /// Check badge unlock status using BadgeService
  // ignore: unused_element
  Future<bool> _checkBadgeUnlockStatus(String badgeId) async {
    final badgeService = BadgeService();
    return await badgeService.isBadgeUnlocked(badgeId);
  }
}
