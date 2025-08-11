import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> diagnoseScoreIssue() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user logged in');
      return;
    }
    
    final uid = user.uid;
    print('Diagnosing score for user: $uid');
    
    // Get user document
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    
    if (!userDoc.exists) {
      print('User document does not exist');
      return;
    }
    
    final userData = userDoc.data() ?? {};
    final currentScore = userData['karmaScore'] ?? 0;
    final totalBadgesUnlocked = userData['totalBadgesUnlocked'] ?? 0;
    
    print('=== USER DOCUMENT ===');
    print('Current karmaScore: $currentScore');
    print('totalBadgesUnlocked: $totalBadgesUnlocked');
    print('score (from karma collection): ${userData['score'] ?? 'not found'}');
    
    // Get badges collection
    final badgesSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('badges')
        .where('isUnlocked', isEqualTo: true)
        .get();
    
    final actualUnlockedBadges = badgesSnapshot.docs.length;
    print('\n=== BADGES ===');
    print('Actual unlocked badges: $actualUnlockedBadges');
    
    for (var doc in badgesSnapshot.docs) {
      final data = doc.data();
      print('Badge: ${data['name'] ?? doc.id} - ${data['unlockedAt']}');
    }
    
    // Calculate expected score
    const baseScore = 50;
    const pointsPerBadge = 5;
    final expectedScore = baseScore + (actualUnlockedBadges * pointsPerBadge);
    
    print('\n=== CALCULATION ===');
    print('Base score: $baseScore');
    print('Points per badge: $pointsPerBadge');
    print('Expected score: $expectedScore');
    print('Actual score: $currentScore');
    print('Difference: ${currentScore - expectedScore}');
    
    // Check score history
    final scoreHistorySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('scoreHistory')
        .orderBy('timestamp', descending: true)
        .get();
    
    print('\n=== SCORE HISTORY (${scoreHistorySnapshot.docs.length} entries) ===');
    for (var doc in scoreHistorySnapshot.docs.take(5)) {
      final data = doc.data();
      print('${data['timestamp']}: ${data['badgeName']} (+${data['pointsEarned']} pts) = ${data['newTotal']}');
    }
    
  } catch (e) {
    print('Error diagnosing score: $e');
  }
}

// Run the diagnosis
void main() async {
  await diagnoseScoreIssue();
}
