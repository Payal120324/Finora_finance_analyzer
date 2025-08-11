
class BadgeRule {
  final String id, title, icon;
  final bool Function(Map<String, dynamic>) shouldUnlock;
  final bool Function(Map<String, dynamic>) shouldRevoke;
  const BadgeRule({
    required this.id,
    required this.title,
    required this.icon,
    required this.shouldUnlock,
    required this.shouldRevoke,
  });
}

/// 20-level ladder
class BadgeRules {
  static final List<BadgeRule> all = [
    BadgeRule(
      id: 'start_journey',
      title: 'First Step',
      icon: 'first_step.json',
      shouldUnlock: (c) => (c['totalExpenses'] ?? 0) >= 1,
      shouldRevoke: (_) => false,
    ),
    BadgeRule(
      id: 'log_3_days',
      title: 'Getting Consistent',
      icon: 'consistent.json',
      shouldUnlock: (c) => (c['totalDistinctLogDays'] ?? 0) >= 3,
      shouldRevoke: (c) => (c['totalDistinctLogDays'] ?? 0) < 3,
    ),
    BadgeRule(
      id: 'log_7_days',
      title: 'Weekly Saver',
      icon: 'weekly_saver.json',
      shouldUnlock: (c) => (c['totalDistinctLogDays'] ?? 0) >= 7,
      shouldRevoke: (c) => (c['totalDistinctLogDays'] ?? 0) < 7,
    ),
    BadgeRule(
      id: 'budget_1_month',
      title: 'Budget Beginner',
      icon: 'budget_beginner.json',
      shouldUnlock: (c) => (c['monthsUnderBudget'] ?? 0) >= 1,
      shouldRevoke: (c) => (c['monthsUnderBudget'] ?? 0) < 1,
    ),
    BadgeRule(
      id: 'budget_3_months',
      title: 'Budget Ninja',
      icon: 'budget_ninja.json',
      shouldUnlock: (c) => (c['monthsUnderBudget'] ?? 0) >= 3,
      shouldRevoke: (c) => (c['monthsUnderBudget'] ?? 0) < 3,
    ),
    BadgeRule(
      id: 'paid_1_bill',
      title: 'On-Time Starter',
      icon: 'On-Time_Starter.json',
      shouldUnlock: (c) => (c['billsPaid'] ?? 0) >= 1,
      shouldRevoke: (_) => false,
    ),
    BadgeRule(
      id: 'paid_5_bills',
      title: 'Bill Boss',
      icon: 'bill_boss.json',
      shouldUnlock: (c) => (c['billsPaid'] ?? 0) >= 5,
      shouldRevoke: (c) => (c['missedBills'] ?? 0) > 0,
    ),
    BadgeRule(
      id: 'goal_1_saved',
      title: 'Small Saver',
      icon: 'small_saver.json',
      shouldUnlock: (c) => (c['goalsDone'] ?? 0) >= 1,
      shouldRevoke: (_) => false,
    ),
    BadgeRule(
      id: 'goal_3_saved',
      title: 'Steady Saver',
      icon: 'steady_saver.json',
      shouldUnlock: (c) => (c['goalsDone'] ?? 0) >= 3,
      shouldRevoke: (_) => false,
    ),
    BadgeRule(
      id: 'goal_5_saved',
      title: 'Goal Crusher',
      icon: 'goal_crusher.json',
      shouldUnlock: (c) => (c['goalsDone'] ?? 0) >= 5,
      shouldRevoke: (_) => false,
    ),
    BadgeRule(
      id: 'no_spend_day',
      title: 'Mindful Spender',
      icon: 'mindful_spender.json',
      shouldUnlock: (c) => (c['noSpendDays'] ?? 0) >= 1,
      shouldRevoke: (_) => false,
    ),
    BadgeRule(
      id: 'spending_ratio',
      title: 'Needs First',
      icon: 'need_first.json',
      shouldUnlock: (c) => (c['needsPct'] ?? 0) >= 70,
      shouldRevoke: (c) => (c['needsPct'] ?? 0) < 70,
    ),
    BadgeRule(
      id: 'streak_14',
      title: 'Discipline Seeker',
      icon: 'discipline_seeker.json',
      shouldUnlock: (c) => (c['streak'] ?? 0) >= 14,
      shouldRevoke: (c) => (c['streak'] ?? 0) < 14,
    ), 
    BadgeRule(
      id: 'export_used',
      title: 'Insight Seeker',
      icon: 'Insight_seeker.json',
      shouldUnlock: (c) => (c['exports'] ?? 0) >= 1,
      shouldRevoke: (_) => false,
    ),
    BadgeRule(
      id: 'smart_tip_done',
      title: 'Action Taker',
      icon: 'Action_Taker.json',
      shouldUnlock: (c) => (c['tipsUsed'] ?? 0) >= 1,
      shouldRevoke: (_) => false,
    ),
    BadgeRule(
      id: 'mission_complete',
      title: 'Weekly Warrior',
      icon: 'Weekly_Warrior.json', 
      shouldUnlock: (c) => (c['missionsDone'] ?? 0) >= 1,
      shouldRevoke: (_) => false,
    ),
    BadgeRule(
      id: 'combo_3_badges',
      title: 'Level-Up Master',
      icon: 'Level-Up_Master.json',
      shouldUnlock: (c) => (c['badgesUnlockedLast7'] ?? 0) >= 3,
      shouldRevoke: (_) => false,
    ),
    BadgeRule(
      id: 'score_90',
      title: 'Karma Legend',
      icon: 'Karma_Legend.json',
      shouldUnlock: (c) => (c['score'] ?? 0) >= 90 && (c['scoreDays90'] ?? 0) >= 7,
      shouldRevoke: (c) => (c['score'] ?? 0) < 90,
    ),
    BadgeRule(
      id: 'help_others',
      title: 'Community Hero',
      icon: 'Community_Hero.json',
      shouldUnlock: (c) => (c['referrals'] ?? 0) >= 1,
      shouldRevoke: (_) => false,
    ),
  ];
}
