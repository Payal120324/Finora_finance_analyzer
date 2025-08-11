import 'package:cloud_firestore/cloud_firestore.dart';

class BadgeInitializer {
  final String uid;
  
  BadgeInitializer(this.uid);

  /// Initialize all badges as locked for new users
  Future<void> initializeBadgesForNewUser() async {
    final firestore = FirebaseFirestore.instance;
    final userDoc = firestore.collection('users').doc(uid);
    
    try {
      // Check if user document exists, create if not
      final userSnapshot = await userDoc.get();
      
      if (!userSnapshot.exists) {
        // Create new user document with default values
        await userDoc.set({
          'uid': uid,
          'createdAt': FieldValue.serverTimestamp(),
          'karmaScore': 50,
          'totalBadgesUnlocked': 0,
          'totalLogs': 0,
          'monthsUnderBudget': 0,
          'billsPaid': 0,
          'goalsDone': 0,
          'score': 50,
          'hasInitializedBadges': true,
          'isNewUser': true,
        });
        print('Created new user document and initialized badges for: $uid');
        return;
      }
      
      // Check if badges have already been initialized
      final userData = userSnapshot.data() ?? {};
      
      if (userData['hasInitializedBadges'] == true) {
        print('Badges already initialized for user: $uid');
        return;
      }
      
      // Initialize missing fields for existing user
      await userDoc.update({
        'hasInitializedBadges': true,
        'totalBadgesUnlocked': userData['totalBadgesUnlocked'] ?? 0,
        'karmaScore': userData['karmaScore'] ?? 50,
        'totalLogs': userData['totalLogs'] ?? 0,
        'monthsUnderBudget': userData['monthsUnderBudget'] ?? 0,
        'billsPaid': userData['billsPaid'] ?? 0,
        'goalsDone': userData['goalsDone'] ?? 0,
        'score': userData['score'] ?? 50,
      });
      
      print('Successfully initialized badges for existing user: $uid');
    } catch (e) {
      print('Error initializing badges for new user: $e');
      throw Exception('Failed to initialize badges');
    }
  }

  /// Check if user is new and needs badge initialization
  Future<bool> isNewUser() async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
    final snapshot = await userDoc.get();
    
    if (!snapshot.exists) return true;
    
    final data = snapshot.data() ?? {};
    return data['hasInitializedBadges'] != true;
  }

  /// Get the count of unlocked badges
  Future<int> getUnlockedBadgeCount() async {
    final badgesSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('badges')
        .where('isUnlocked', isEqualTo: true)
        .get();
    
    return badgesSnapshot.docs.length;
  }
}
