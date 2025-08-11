import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/badge.dart';

class UserScoreService {
  final String uid;
  UserScoreService(this.uid);

  // Fixed points per badge - 5 points for any badge type
  static const int pointsPerBadge = 5;

  // Update user score when badge is unlocked
  Future<void> updateScoreForBadgeUnlock(Badge badge) async {
    final points = pointsPerBadge;
    
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final scoreHistoryRef = userRef.collection('scoreHistory');
      
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        final currentScore = userDoc.data()?['karmaScore'] ?? 0;
        final newScore = currentScore + points;

        // Update user score
        transaction.update(userRef, {
          'karmaScore': newScore,
          'lastScoreUpdate': FieldValue.serverTimestamp(),
        });

        // Add score history entry
        transaction.set(
          scoreHistoryRef.doc(),
          {
            'badgeId': badge.id,
            'badgeName': badge.name,
            'badgeType': badge.type.toString(),
            'pointsEarned': points,
            'newTotal': newScore,
            'timestamp': FieldValue.serverTimestamp(),
            'type': 'badge_unlock',
          },
        );
      });
    } catch (e) {
      print('Error updating user score: $e');
      throw Exception('Failed to update user score');
    }
  }

  // Get user score history
  Stream<List<ScoreHistoryEntry>> getScoreHistory() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('scoreHistory')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ScoreHistoryEntry.fromFirestore(doc))
            .toList());
  }

  // Get current user score
  Stream<int> getCurrentScore() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.data()?['karmaScore'] ?? 0);
  }

  // Get score statistics
  Future<ScoreStats> getScoreStats() async {
    final historySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('scoreHistory')
        .get();
    
    final history = historySnapshot.docs
        .map((doc) => ScoreHistoryEntry.fromFirestore(doc))
        .toList();

    final currentScore = await getCurrentScore().first;
    
    int totalBadges = history.length;
    int totalPointsEarned = history.fold(0, (sum, entry) => sum + entry.pointsEarned);
    
    Map<BadgeType, int> pointsByType = {};
    for (var entry in history) {
      final badgeType = BadgeType.values.firstWhere(
        (e) => e.toString() == entry.badgeType,
        orElse: () => BadgeType.bronze,
      );
      pointsByType[badgeType] = (pointsByType[badgeType] ?? 0) + pointsPerBadge;
    }

    return ScoreStats(
      currentScore: currentScore,
      totalBadges: totalBadges,
      totalPointsEarned: totalPointsEarned,
      pointsByType: pointsByType,
    );
  }
}

class ScoreHistoryEntry {
  final String id;
  final String badgeId;
  final String badgeName;
  final String badgeType;
  final int pointsEarned;
  final int newTotal;
  final DateTime timestamp;

  ScoreHistoryEntry({
    required this.id,
    required this.badgeId,
    required this.badgeName,
    required this.badgeType,
    required this.pointsEarned,
    required this.newTotal,
    required this.timestamp,
  });

  factory ScoreHistoryEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ScoreHistoryEntry(
      id: doc.id,
      badgeId: data['badgeId'] ?? '',
      badgeName: data['badgeName'] ?? '',
      badgeType: data['badgeType'] ?? '',
      pointsEarned: data['pointsEarned'] ?? 0,
      newTotal: data['newTotal'] ?? 0,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
}

class ScoreStats {
  final int currentScore;
  final int totalBadges;
  final int totalPointsEarned;
  final Map<BadgeType, int> pointsByType;

  ScoreStats({
    required this.currentScore,
    required this.totalBadges,
    required this.totalPointsEarned,
    required this.pointsByType,
  });
}
