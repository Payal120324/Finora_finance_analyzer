import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseIntegrationTest {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Reset all user data for testing
  Future<void> resetAllUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        return;
      }

      print('🧹 Resetting all user data for user: ${user.uid}');

      // Reset badges
      final badgesSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('badges')
          .get();
      
      final batch1 = _firestore.batch();
      for (final doc in badgesSnapshot.docs) {
        batch1.delete(doc.reference);
      }
      await batch1.commit();
      print('✅ Badges reset');

      // Reset challenges
      final challengesSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('challenges')
          .get();
      
      final batch2 = _firestore.batch();
      for (final doc in challengesSnapshot.docs) {
        batch2.delete(doc.reference);
      }
      await batch2.commit();
      print('✅ Challenges reset');

      // Reset user data
      final userDataSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('user_data')
          .get();
      
      final batch3 = _firestore.batch();
      for (final doc in userDataSnapshot.docs) {
        batch3.delete(doc.reference);
      }
      await batch3.commit();
      print('✅ User data reset');

      print('🎉 All user data has been reset successfully!');
      print('📋 New users will now start with:');
      print('   - All badges locked');
      print('   - No challenges completed');
      print('   - Fresh weekly challenge selection');

    } catch (e) {
      print('❌ Error resetting user data: $e');
    }
  }

  // Check current user data status
  Future<void> checkUserDataStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        return;
      }

      print('📊 Checking data status for user: ${user.uid}');

      // Check badges
      final badgesSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('badges')
          .get();
      print('   Badges: ${badgesSnapshot.docs.length} unlocked');

      // Check challenges
      final challengesSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('challenges')
          .get();
      print('   Challenges: ${challengesSnapshot.docs.length} completed');

      // Check user data
      final userDataSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('user_data')
          .get();
      print('   User data: ${userDataSnapshot.docs.length} documents');

    } catch (e) {
      print('❌ Error checking user data status: $e');
    }
  }
}
