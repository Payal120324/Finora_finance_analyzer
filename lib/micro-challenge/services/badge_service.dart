import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../models/badge.dart';
import 'challenge_service.dart';

class BadgeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream controller for badge unlock notifications
  static final StreamController<Badge> _badgeUnlockController = StreamController<Badge>.broadcast();
  static Stream<Badge> get onBadgeUnlocked => _badgeUnlockController.stream;

  // Get user-specific collection reference
  CollectionReference<Map<String, dynamic>> _userBadgesCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('badges');
  }

  // Get badges from ChallengeService
  Map<String, Badge> get _challengeBadges {
    final challengeService = ChallengeService();
    final challenges = challengeService.getChallenges();
    
    return {
      for (var challenge in challenges)
        challenge.id: Badge(
          id: challenge.badgeId,
          name: challenge.title.split(' ').take(2).join(' '),
          description: challenge.description,
          title: challenge.title,
          icon: _getBadgeIconFromTitle(challenge.title),
          animationPath: challenge.animationPath,
          difficulty: _getDifficultyFromTitle(challenge.title),
          category: _getCategoryFromTitle(challenge.title),
        )
    };
  }

  // Helper methods to extract badge details from challenge titles
  String _getBadgeIconFromTitle(String title) {
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

  int _getDifficultyFromTitle(String title) {
    if (title.contains('Master') || title.contains('Boost')) return 5;
    if (title.contains('Audit') || title.contains('Control')) return 4;
    if (title.contains('Tracker') || title.contains('Envelope')) return 3;
    if (title.contains('Days') || title.contains('Reading')) return 2;
    return 1;
  }

  String _getCategoryFromTitle(String title) {
    if (title.contains('Budget') || title.contains('Cash')) return 'Budgeting';
    if (title.contains('Spend') || title.contains('Impulse')) return 'Spending Control';
    if (title.contains('Savings') || title.contains('Envelope')) return 'Saving';
    if (title.contains('Meal') || title.contains('Reading')) return 'Lifestyle';
    if (title.contains('Subscription') || title.contains('Digital')) return 'Digital Wellness';
    return 'General';
  }

  // Get badge for a specific challenge
  Badge getBadgeForChallenge(String challengeId) {
    return _challengeBadges[challengeId] ?? _challengeBadges.values.first;
  }

  // Check if a badge is unlocked for a specific user
  Future<bool> isBadgeUnlocked(String badgeId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      final doc = await _userBadgesCollection(user.uid).doc(badgeId).get();
      return doc.exists;
    } catch (e) {
      print('Error checking badge unlock status: $e');
      return false;
    }
  }

  // Unlock a badge when challenge is completed
  Future<void> unlockBadge(String challengeId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      final badge = getBadgeForChallenge(challengeId);
      
      if (badge.id.isEmpty) return;

      // Check if badge is already unlocked
      final isUnlocked = await isBadgeUnlocked(badge.id);
      if (!isUnlocked) {
        await _userBadgesCollection(user.uid).doc(badge.id).set({
          'unlockedAt': FieldValue.serverTimestamp(),
          'challengeId': challengeId,
          'badgeName': badge.name,
          'badgeTitle': badge.title,
        });
        
        // Notify listeners that a badge has been unlocked
        _badgeUnlockController.add(badge);
        print('✅ Badge unlocked for user ${user.uid}: ${badge.name}');
      }
    } catch (e) {
      print('Error unlocking badge: $e');
    }
  }

  // Close the stream controller when no longer needed
  static void dispose() {
    _badgeUnlockController.close();
  }

  // Get all unlocked badges for current user
  Future<List<Badge>> getUnlockedBadges() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];
      
      final unlockedSnapshot = await _userBadgesCollection(user.uid).get();
      final unlockedIds = unlockedSnapshot.docs.map((doc) => doc.id).toSet();
      
      return _challengeBadges.values
          .where((badge) => unlockedIds.contains(badge.id))
          .toList();
    } catch (e) {
      print('Error getting unlocked badges: $e');
      return [];
    }
  }

  // Get all badges with their unlock status for current user
  Future<List<Badge>> getAllBadgesWithStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        // Return all badges locked if no user is logged in
        return _challengeBadges.values.map((badge) => badge.copyWith(isUnlocked: false)).toList();
      }
      
      // Get all unlocked badge IDs for this user
      final unlockedSnapshot = await _userBadgesCollection(user.uid).get();
      final unlockedIds = unlockedSnapshot.docs.map((doc) => doc.id).toSet();

      // Return all badges with their unlock status
      return _challengeBadges.values.map((badge) {
        return badge.copyWith(isUnlocked: unlockedIds.contains(badge.id));
      }).toList();
    } catch (e) {
      print('Error getting badges with status: $e');
      return _challengeBadges.values.map((badge) => badge.copyWith(isUnlocked: false)).toList();
    }
  }

  // Reset all badges for current user (for testing)
  Future<void> resetAllBadges() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      final batch = _firestore.batch();
      final badgesSnapshot = await _userBadgesCollection(user.uid).get();
      
      for (final doc in badgesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      print('✅ All badges reset for user ${user.uid}');
    } catch (e) {
      print('Error resetting badges: $e');
    }
  }

  // Check if user can unlock badge (before next Monday)
  bool canUnlockBadge(DateTime challengeStartDate) {
    final now = DateTime.now();
    final nextMonday = _getNextMonday(now);
    
    // User has until next Monday to complete the challenge
    return now.isBefore(nextMonday);
  }

  DateTime _getNextMonday(DateTime date) {
    // Get next Monday
    final daysUntilMonday = (8 - date.weekday) % 7;
    if (daysUntilMonday == 0) {
      return date.add(const Duration(days: 7));
    }
    return date.add(Duration(days: daysUntilMonday));
  }

  // Check if it's Monday (for weekly updates)
  bool isMonday() {
    return DateTime.now().weekday == DateTime.monday;
  }
}
