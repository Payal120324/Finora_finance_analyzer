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
    final firestore = FirebaseFirestore.instance;
    final userDoc = firestore.collection('users').doc(uid);
    final badgeDoc = userDoc.collection('badges').doc(badgeId);

    await firestore.runTransaction((transaction) async {
      // Get current badge state
      final badgeSnapshot = await transaction.get(badgeDoc);
      
      // Check if badge is already unlocked
      if (badgeSnapshot.exists) {
        final badgeData = badgeSnapshot.data()!;
        if (badgeData['isUnlocked'] == true) {
          return; // Badge already unlocked
        }
      }

      // Find badge rule
      final badgeRule = BadgeRules.all.firstWhere(
        (rule) => rule.id == badgeId,
        orElse: () => throw Exception('Badge rule not found: $badgeId'),
      );

      // Update badge to unlocked
      transaction.set(badgeDoc, {
        'id': badgeId,
        'name': badgeRule.title,
        'description': 'Badge for ${badgeRule.title}',
        'type': 'bronze',
        'icon': badgeRule.icon,
        'unlockedAt': FieldValue.serverTimestamp(),
        'isUnlocked': true,
        'category': 'achievement',
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
        'type': 'bronze',
        'icon': rule.icon,
        'unlockedAt': null,
        'isUnlocked': false,
        'category': 'achievement',
      });
    }

    await batch.commit();
  }

  /// Check and unlock badges based on user context
  Future<void> checkAndUnlockBadges(Map<String, dynamic> userContext) async {
    final firestore = FirebaseFirestore.instance;
    final userDoc = firestore.collection('users').doc(uid);

    // Get all locked badges
    final lockedBadges = await userDoc
        .collection('badges')
        .where('isUnlocked', isEqualTo: false)
        .get();

    for (final badgeDoc in lockedBadges.docs) {
      final badgeData = badgeDoc.data();
      final badgeId = badgeData['id'] as String;

      // Check if user meets criteria based on badge rule
      final badgeRule = BadgeRules.all.firstWhere(
        (rule) => rule.id == badgeId,
        orElse: () => throw Exception('Badge rule not found: $badgeId'),
      );

      if (badgeRule.shouldUnlock(userContext)) {
        await unlockBadge(badgeId);
      }
    }
  }

  /// Get badge unlock status
  Future<bool> isBadgeUnlocked(String badgeId) async {
    final badgeDoc = _firestore.collection('users').doc(uid).collection('badges').doc(badgeId);
    final snapshot = await badgeDoc.get();

    if (!snapshot.exists) return false;

    final data = snapshot.data() ?? {};
    return data['isUnlocked'] == true;
  }

  /// Get badge by ID
  Future<Badge?> getBadge(String badgeId) async {
    try {
      final badgeDoc = _firestore.collection('users').doc(uid).collection('badges').doc(badgeId);
      final snapshot = await badgeDoc.get();

      if (snapshot.exists) {
        final data = snapshot.data()!;
        return Badge.fromMap(data);
      }

      // Return locked badge if not found
      final badgeRule = BadgeRules.all.firstWhere(
        (rule) => rule.id == badgeId,
        orElse: () => BadgeRule(
          id: badgeId,
          title: 'Unknown Badge',
          icon: '❓',
          shouldUnlock: (_) => false,
          shouldRevoke: (_) => false,
        ),
      );

      return Badge(
        id: badgeId,
        name: badgeRule.title,
        description: 'Badge for ${badgeRule.title}',
        type: BadgeType.bronze,
        icon: badgeRule.icon,
        unlockedAt: null,
        isUnlocked: false,
        category: 'achievement',
      );
    } catch (e) {
      return null;
    }
  }

  // Get collection reference
  CollectionReference get _col =>
      _firestore.collection('users').doc(uid).collection('badges');

  // Stream all badges
  Stream<List<Badge>> getAllBadgesStream() => _col
      .orderBy('unlockedAt', descending: true)
      .snapshots()
      .map((q) => q.docs.map((d) => Badge.fromMap(d.data()! as Map<String, dynamic>)).toList());

  Future<void> unlock(String badgeId) async {
    await unlockBadge(badgeId);
  }

  Future<void> revoke(String id) => _col.doc(id).delete();

  Future<bool> isUnlocked(String id) async => await isBadgeUnlocked(id);

  Future<int> getBadgesUnlockedLast7() async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(Duration(days: 7));
    final snapshot = await _col
        .where('unlockedAt', isGreaterThanOrEqualTo: sevenDaysAgo)
        .get();
    return snapshot.docs.length;
  }

  Future<int> getTotalBadgesUnlocked() async {
    final snapshot = await _col.where('isUnlocked', isEqualTo: true).get();
    return snapshot.docs.length;
  }

  Future<List<Badge>> getAllBadges() async {
    final snapshot = await _col.get();
    return snapshot.docs
        .map((doc) => Badge.fromMap(doc.data()! as Map<String, dynamic>))
        .toList();
  }
}
