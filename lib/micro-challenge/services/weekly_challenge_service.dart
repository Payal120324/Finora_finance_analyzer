import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/weekly_challenge.dart';
import 'badge_service.dart';

class WeeklyChallengeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<WeeklyChallenge> _challenges = [
    WeeklyChallenge(
      id: '1',
      title: 'Budget Master 💰',
      description: 'Stay within your weekly budget for 7 days straight',
      badgeId: 'badge_budget_master',
      badgeName: 'Budget Master',
      badgeIcon: '🏆',
      animationPath: 'assets/budget_ninja.json',
      difficulty: 3,
      category: 'Budgeting',
    ),
    WeeklyChallenge(
      id: '2',
      title: 'No Spend Days 🚫',
      description: 'Complete 3 no-spend days this week',
      badgeId: 'badge_no_spend',
      badgeName: 'No Spend Hero',
      badgeIcon: '🛑',
      animationPath: 'assets/discipline_seeker.json',
      difficulty: 4,
      category: 'Saving',
    ),
    WeeklyChallenge(
      id: '3',
      title: 'Cash Tracker 📊',
      description: 'Log every single expense for 7 days',
      badgeId: 'badge_cash_tracker',
      badgeName: 'Expense Logger',
      badgeIcon: '📝',
      animationPath: 'assets/consistent.json',
      difficulty: 2,
      category: 'Tracking',
    ),
    WeeklyChallenge(
      id: '4',
      title: 'Meal Planner 🍱',
      description: 'Cook all meals at home for 5 days straight',
      badgeId: 'badge_meal_planner',
      badgeName: 'Home Chef',
      badgeIcon: '🍳',
      animationPath: 'assets/badge_meal_planner.json',
      difficulty: 3,
      category: 'Food',
    ),
    WeeklyChallenge(
      id: '5',
      title: 'Digital Detox 📵',
      description: 'No online shopping for the entire week',
      badgeId: 'badge_digital_detox',
      badgeName: 'Digital Minimalist',
      badgeIcon: '📵',
      animationPath: 'assets/weekly_saver.json',
      difficulty: 4,
      category: 'Digital',
    ),
    WeeklyChallenge(
      id: '6',
      title: 'Savings Boost 🐷',
      description: 'Save an extra ₹1000 this week',
      badgeId: 'badge_savings_boost',
      badgeName: 'Savings Champion',
      badgeIcon: '💰',
      animationPath: 'assets/small_saver.json',
      difficulty: 3,
      category: 'Saving',
    ),
    WeeklyChallenge(
      id: '7',
      title: 'Subscription Audit 🔍',
      description: 'Cancel one unused subscription this week',
      badgeId: 'badge_subscription_audit',
      badgeName: 'Subscription Sleuth',
      badgeIcon: '🔍',
      animationPath: 'assets/mindful_spender.json',
      difficulty: 2,
      category: 'Audit',
    ),
    WeeklyChallenge(
      id: '8',
      title: 'Impulse Control 🎯',
      description: 'No impulse purchases for 7 days',
      badgeId: 'badge_impulse_control',
      badgeName: 'Impulse Master',
      badgeIcon: '🎯',
      animationPath: 'assets/goal_crusher.json',
      difficulty: 4,
      category: 'Control',
    ),
    WeeklyChallenge(
      id: '9',
      title: 'Cash Envelope 💳',
      description: 'Use only cash for discretionary spending',
      badgeId: 'badge_cash_envelope',
      badgeName: 'Cash King',
      badgeIcon: '💵',
      animationPath: 'assets/envelope.json',
      difficulty: 3,
      category: 'Method',
    ),
    WeeklyChallenge(
      id: '10',
      title: 'Financial Reading 📚',
      description: 'Read 30 minutes of financial content daily',
      badgeId: 'badge_financial_reader',
      badgeName: 'Finance Scholar',
      badgeIcon: '📚',
      animationPath: 'assets/reader.json',
      difficulty: 2,
      category: 'Education',
    ),
  ];

  // Get user-specific collection reference
  CollectionReference<Map<String, dynamic>> _userChallengesCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('challenges');
  }

  CollectionReference<Map<String, dynamic>> _userDataCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('user_data');
  }

  List<WeeklyChallenge> getAllChallenges() => _challenges;

  Future<WeeklyChallenge> getCurrentWeeklyChallenge() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return _challenges[0]; // Fallback if no user
      
      final today = DateTime.now();
      
      // Check if we have a current challenge for this user
      final currentChallengeDoc = await _userDataCollection(user.uid).doc('current_challenge').get();
      
      if (currentChallengeDoc.exists) {
        final data = currentChallengeDoc.data();
        final lastChallengeDate = (data?['last_challenge_date'] as Timestamp?)?.toDate();
        final challengeId = data?['current_challenge_id'] as String?;
        
        // Check if it's a new week (Monday) or if no challenge exists
        final isNewWeek = lastChallengeDate == null || _isDifferentWeek(today, lastChallengeDate);
        
        if (isNewWeek) {
          // Select new random challenge
          return _selectNewChallenge(user.uid, today);
        } else if (challengeId != null) {
          // Return existing challenge
          return _challenges.firstWhere(
            (c) => c.id == challengeId,
            orElse: () => _challenges[0],
          );
        }
      }
      
      // Default to selecting a new challenge
      return _selectNewChallenge(user.uid, today);
    } catch (e) {
      print('Error getting current challenge: $e');
      return _challenges[0]; // Fallback to first challenge
    }
  }

  Future<WeeklyChallenge> _selectNewChallenge(String userId, DateTime today) async {
    final random = Random();
    final challenge = _challenges[random.nextInt(_challenges.length)];
    
    // Save the new challenge selection
    await _userDataCollection(userId).doc('current_challenge').set({
      'current_challenge_id': challenge.id,
      'last_challenge_date': Timestamp.fromDate(today),
      'updated_at': FieldValue.serverTimestamp(),
    });
    
    return challenge;
  }

  bool _isDifferentWeek(DateTime date1, DateTime date2) {
    // Only rotate on Mondays
    final monday1 = _getMondayOfWeek(date1);
    final monday2 = _getMondayOfWeek(date2);
    return monday1 != monday2;
  }

  DateTime _getMondayOfWeek(DateTime date) {
    // Get the Monday of the current week
    return DateTime(date.year, date.month, date.day - (date.weekday - 1));
  }

  Future<bool> isChallengeCompleted(String challengeId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      final completedDoc = await _userChallengesCollection(user.uid).doc(challengeId).get();
      return completedDoc.exists;
    } catch (e) {
      print('Error checking challenge completion: $e');
      return false;
    }
  }

  Future<void> markChallengeCompleted(String challengeId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      // Check if already completed
      final isCompleted = await isChallengeCompleted(challengeId);
      if (!isCompleted) {
        await _userChallengesCollection(user.uid).doc(challengeId).set({
          'completed_at': FieldValue.serverTimestamp(),
          'challenge_id': challengeId,
        });
        
        // Unlock the badge for this challenge
        final badgeService = BadgeService();
        await badgeService.unlockBadge(challengeId);
        
        print('✅ Challenge marked as completed for user ${user.uid}: $challengeId');
      }
    } catch (e) {
      print('Error marking challenge completed: $e');
    }
  }

  Future<List<String>> getCompletedChallenges() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];
      
      final completedSnapshot = await _userChallengesCollection(user.uid).get();
      return completedSnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('Error getting completed challenges: $e');
      return [];
    }
  }

  Future<void> resetWeeklyChallenge() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      // Reset current challenge data
      await _userDataCollection(user.uid).doc('current_challenge').delete();
      
      // Reset completed challenges
      final batch = _firestore.batch();
      final challengesSnapshot = await _userChallengesCollection(user.uid).get();
      
      for (final doc in challengesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      print('✅ Weekly challenge reset for user ${user.uid}');
    } catch (e) {
      print('Error resetting weekly challenge: $e');
    }
  }
}
