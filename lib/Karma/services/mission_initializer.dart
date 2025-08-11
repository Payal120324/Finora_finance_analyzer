import 'package:cloud_firestore/cloud_firestore.dart';
import 'mission_service.dart';

class MissionInitializer {
  final String uid;
  final MissionService missionService;

  MissionInitializer(this.uid) : missionService = MissionService(uid);

  Future<void> createSampleMissions() async {
    final missions = [
      {'id': 'start_journey', 'title': 'First Step', 'description': 'Complete your first step to start your journey.', 'done': false},
      {'id': 'log_3_days', 'title': 'Getting Consistent', 'description': 'Log your expenses for 3 days.', 'done': false},
      {'id': 'log_7_days', 'title': 'Weekly Saver', 'description': 'Maintain a 7-day logging streak.', 'done': false},
      {'id': 'budget_1_month', 'title': 'Budget Beginner', 'description': 'Stay under budget for 1 month.', 'done': false},
      {'id': 'budget_3_months', 'title': 'Budget Ninja', 'description': 'Stay under budget for 3 months.', 'done': false},
      {'id': 'paid_1_bill', 'title': 'On-Time Starter', 'description': 'Pay your first bill on time.', 'done': false},
      {'id': 'paid_5_bills', 'title': 'Bill Boss', 'description': 'Pay 5 bills on time.', 'done': false},
      {'id': 'goal_1_saved', 'title': 'Small Saver', 'description': 'Achieve your first savings goal.', 'done': false},
      {'id': 'goal_3_saved', 'title': 'Steady Saver', 'description': 'Achieve 3 savings goals.', 'done': false},
      {'id': 'goal_5_saved', 'title': 'Goal Crusher', 'description': 'Achieve 5 savings goals.', 'done': false},
      {'id': 'no_spend_day', 'title': 'Mindful Spender', 'description': 'Have a day with no spending.', 'done': false},
      {'id': 'spending_ratio', 'title': 'Needs First', 'description': 'Keep your needs spending above 70%.', 'done': false},
      {'id': 'streak_14', 'title': 'Discipline Seeker', 'description': 'Maintain a 14-day streak.', 'done': false},
      {'id': 'export_used', 'title': 'Insight Seeker', 'description': 'Use the export feature.', 'done': false},
      {'id': 'smart_tip_done', 'title': 'Action Taker', 'description': 'Use a smart tip.', 'done': false},
      {'id': 'mission_complete', 'title': 'Weekly Warrior', 'description': 'Complete a weekly mission.', 'done': false},
      {'id': 'combo_3_badges', 'title': 'Level-Up Master', 'description': 'Unlock 3 badges in 7 days.', 'done': false},
      {'id': 'score_90', 'title': 'Karma Legend', 'description': 'Maintain a score of 90 for 7 days.', 'done': false},
      {'id': 'help_others', 'title': 'Community Hero', 'description': 'Refer a friend.', 'done': false},
      {'id': 'all_badges', 'title': 'Elite Financier', 'description': 'Unlock all badges.', 'done': false},
    ];

    final batch = FirebaseFirestore.instance.batch();
    final missionsCol = FirebaseFirestore.instance.collection('users').doc(uid).collection('missions');

    for (var mission in missions) {
      final docRef = missionsCol.doc(mission['id'] as String);
      batch.set(docRef, mission);
    }

    await batch.commit();
  }
}
