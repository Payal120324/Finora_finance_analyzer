import 'package:cloud_firestore/cloud_firestore.dart';
import '../badges/badge_rules.dart';

class AtomicBadgeService {
  final String uid;
  
  AtomicBadgeService(this.uid);

  /// Unlock badge and increment karma score atomically
  Future<void> unlockBadgeAndIncrementScore(String badgeId) async {
    final firestore = FirebaseFirestore.instance;
    final userDoc = firestore.collection('users').doc(uid);
    final badgeDoc = userDoc.collection('badges').doc(badgeId);
    final summaryDoc = userDoc.collection('karma').doc('summary');

    await firestore.runTransaction((transaction) async {
      // Get current badge state
      final badgeSnapshot = await transaction.get(badgeDoc);
      final summarySnapshot = await transaction.get(summaryDoc);
      
      // Check if badge is already unlocked
      if (badgeSnapshot.exists) {
        final badgeData = badgeSnapshot.data()!;
        if (badgeData['unlocked'] == true) {
          return; // Badge already unlocked
        }
      }
      
      // Get current score
      int currentScore = 0;
      if (summarySnapshot.exists) {
        final summaryData = summarySnapshot.data()!;
        currentScore = summaryData['score'] ?? 0;
      }
      
      // Find badge rule
      final badgeRule = BadgeRules.all.firstWhere(
        (rule) => rule.id == badgeId,
        orElse: () => BadgeRule(
          id: '',
          title: '',
          icon: '',
          shouldUnlock: (_) => false,
          shouldRevoke: (_) => false,
        ),
      );
      if (badgeRule.id.isEmpty) return;
      
      
      final newScore = currentScore + 5;
      
      // Update badge to unlocked
      transaction.set(badgeDoc, {
        'id': badgeId,
        'name': badgeRule.title,
        'description': 'Badge for ${badgeRule.title}',
        'threshold': 0, // Placeholder since BadgeRule doesn't have threshold
        'unlocked': true,
        'unlockedAt': FieldValue.serverTimestamp(),
        'icon': badgeRule.icon,
      });
      
      // Update karma score
      transaction.update(summaryDoc, {
        'score': newScore,
        'totalBadgesUnlocked': FieldValue.increment(1),
      });
    });
  }

  /// Initialize all badges as locked for new user
  Future<void> initializeAllBadgesAsLocked() async {
    final firestore = FirebaseFirestore.instance;
    final userDoc = firestore.collection('users').doc(uid);
    final batch = firestore.batch();

    // Create all badge documents as locked
    for (final rule in BadgeRules.all) {
      final badgeDoc = userDoc.collection('badges').doc(rule.id);
      batch.set(badgeDoc, {
        'id': rule.id,
        'name': rule.title,
        'description': 'Badge for ${rule.title}',
        'threshold': 0, // Placeholder since BadgeRule doesn't have threshold
        'unlocked': false,
        'unlockedAt': null,
        'icon': rule.icon,
      });
    }

    await batch.commit();
  }

  /// Check and unlock badges based on current score
  Future<void> checkAndUnlockBadges(int currentScore) async {
    final firestore = FirebaseFirestore.instance;
    final userDoc = firestore.collection('users').doc(uid);
    
    // Get all locked badges
    final lockedBadges = await userDoc
        .collection('badges')
        .where('unlocked', isEqualTo: false)
        .get();

    for (final badgeDoc in lockedBadges.docs) {
      final badgeData = badgeDoc.data();
      final threshold = badgeData['threshold'] as int;
      
      if (currentScore >= threshold) {
        await unlockBadgeAndIncrementScore(badgeDoc.id);
      }
    }
  }
}
