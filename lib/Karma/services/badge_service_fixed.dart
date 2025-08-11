import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/badge.dart';
import '../badges/badge_rules.dart';

class BadgeService {
  final String uid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  BadgeService(this.uid);

  /// Stream all badges with their unlock status
  Stream<List<Badge>> stream() => _firestore
      .collection('users')
      .doc(uid)
      .collection('badges')
      .orderBy('unlockedAt', descending: true)
      .snapshots()
      .map((q) => q.docs.map((d) => Badge.fromMap(d.data())).toList());

  /// Unlock badge and increment karma score atomically
  Future<void> unlockBadge(String badgeId) async {
    final userDoc = _firestore.collection('users').doc(uid);
    final badgeDoc = userDoc.collection('badges').doc(badgeId);
    final summaryDoc = userDoc.collection('karma').doc('summary');

    await _firestore.runTransaction((transaction) async {
      // Get current badge state
      final badgeSnapshot = await transaction.get(badgeDoc);
      final summarySnapshot = await transaction.get(summaryDoc);

      // Check if badge is already unlocked
      if (badgeSnapshot.exists) {
        final badgeData = badgeSnapshot.data() ?? {};
        if (badgeData['unlocked'] == true) {
          return; // Badge already unlocked
        }
      }

      // Get current score
      int currentScore = 0;
      if (summarySnapshot.exists) {
        final summaryData = summarySnapshot.data() ?? {};
        currentScore = summaryData['score'] ?? 0;
      }

      // Find badge rule
      final badgeRule = BadgeRules.all.firstWhere(
        (rule) => rule.id == badgeId,
        orElse: () => throw Exception('Badge rule not found: $badgeId'),
      );

      // Atomic updates
      final newScore = currentScore + 5;

      // Update badge to unlocked
      transaction.set(badgeDoc, {
        'id': badgeId,
        'name': badgeRule.title,
        'description': badgeRule.title,
        'icon': badgeRule.icon,
        'unlocked': true,
        'unlockedAt': FieldValue.serverTimestamp(),
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
    final userDoc = _firestore.collection('users').doc(uid);
    final batch = _firestore.batch();

    // Create all badge documents as locked
    for (final rule in BadgeRules.all) {
      final badgeDoc = userDoc.collection('badges').doc(rule.id);
      batch.set(badgeDoc, {
        'id': rule.id,
        'name': rule.title,
        'description': rule.title,
        'icon': rule.icon,
        'unlocked': false,
        'unlockedAt': null,
      });
    }

    await batch.commit();
  }

  /// Check if badge is unlocked
  Future<bool> isBadgeUnlocked(String badgeId) async {
    final badgeDoc = _firestore.collection('users').doc(uid).collection('badges').doc(badgeId);
    final snapshot = await badgeDoc.get();

    if (!snapshot.exists) return false;

    final data = snapshot.data() ?? {};
    return data['unlocked'] == true;
  }

  /// Get total badges unlocked
  Future<int> getTotalBadgesUnlocked() async {
    final badgesSnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('badges')
        .where('unlocked', isEqualTo: true)
        .get();

    return badgesSnapshot.docs.length;
  }

  /// Get badges unlocked in last 7 days
  Future<int> getBadgesUnlockedLast7() async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(Duration(days: 7));
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('badges')
        .where('unlockedAt', isGreaterThanOrEqualTo: sevenDaysAgo)
        .get();
    return snapshot.docs.length;
  }

  /// Get all badges
  Future<List<Badge>> getAllBadges() async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('badges')
        .get();

    final badges = <Badge>[];
    for (final doc in snapshot.docs) {
      badges.add(Badge.fromMap(doc.data()));
    }

    // Add missing badges that haven't been created yet
    for (final rule in BadgeRules.all) {
      if (!badges.any((b) => b.id == rule.id)) {
        badges.add(Badge(
          id: rule.id,
          name: rule.title,
          description: rule.title,
          type: BadgeType.bronze, // Default type
          icon: rule.icon,
          isUnlocked: false,
        ));
      }
    }

    return badges;
  }
}
