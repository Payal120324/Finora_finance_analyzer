import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class BadgeContextBuilder {
  final String uid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  BadgeContextBuilder(this.uid);

  Future<Map<String, dynamic>> buildContext() async {
    // Validate UID before proceeding
    if (uid.isEmpty) {
      print('BadgeContextBuilder: Invalid UID provided');
      return _getDefaultContext();
    }

    try {
      final userDoc = _firestore.collection('users').doc(uid);
      
      // Check if user document exists
      final userDocSnapshot = await userDoc.get();
      if (!userDocSnapshot.exists) {
        print('BadgeContextBuilder: User document not found for UID: $uid');
        return _getDefaultContext();
      }

      // Get expense data from both expenses and logs collections
      final expensesSnapshot = await userDoc.collection('expenses').get();
      final logsSnapshot = await userDoc.collection('logs').get();
      final totalExpenses = expensesSnapshot.docs.length + logsSnapshot.docs.length;
      
      // Get logs data for distinct days (reuse logsSnapshot)
      final distinctDays = <String>{};
      for (var doc in logsSnapshot.docs) {
        final data = doc.data();
        final date = data['date'] as Timestamp?;
        if (date != null) {
          distinctDays.add(date.toDate().toIso8601String().substring(0, 10));
        }
      }
      
      // Get user data
      final userData = userDocSnapshot.data() ?? {};
      
      // Get budget data
      final budgetSnapshot = await userDoc.collection('budget').get();
      final monthsUnderBudget = budgetSnapshot.docs.where((doc) => doc.data()['underBudget'] == true).length;
      
      // Get bills data
      final billsSnapshot = await userDoc.collection('bills').get();
      final billsPaid = billsSnapshot.docs.where((doc) => doc.data()['paid'] == true).length;
      final missedBills = billsSnapshot.docs.where((doc) => doc.data()['paid'] == false).length;
      
      // Get goals data
      final goalsSnapshot = await userDoc.collection('goals').get();
      final goalsDone = goalsSnapshot.docs.where((doc) => doc.data()['completed'] == true).length;
      
      // Get spending data for no-spend days
      final spendingSnapshot = await userDoc.collection('spending').get();
      final noSpendDays = spendingSnapshot.docs.where((doc) => doc.data()['amount'] == 0).length;
      
      // Get needs percentage
      final needsDoc = await userDoc.collection('stats').doc('needsPct').get();
      final needsPct = needsDoc.exists ? (needsDoc.data()?['value'] ?? 0) : 0;
      
      // Get exports count
      final exportsSnapshot = await userDoc.collection('exports').get();
      final exports = exportsSnapshot.docs.length;
      
      // Get tips used
      final tipsSnapshot = await userDoc.collection('tipsUsed').get();
      final tipsUsed = tipsSnapshot.docs.length;
      
      // Get missions done
      final missionsSnapshot = await userDoc.collection('missions').get();
      final missionsDone = missionsSnapshot.docs.where((doc) => doc.data()['completed'] == true).length;
      
      // Get badges unlocked in last 7 days
      final badgesSnapshot = await userDoc.collection('badges').get();
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(Duration(days: 7));
      final badgesUnlockedLast7 = badgesSnapshot.docs.where((doc) {
        final unlockedAt = doc.data()['unlockedAt'] as Timestamp?;
        return unlockedAt != null && unlockedAt.toDate().isAfter(sevenDaysAgo);
      }).length;
      
      // Get score days 90
      final scoreDays90Snapshot = await userDoc.collection('scoreDays90').get();
      final scoreDays90 = scoreDays90Snapshot.docs.length;
      
      // Get referrals
      final referralsSnapshot = await userDoc.collection('referrals').get();
      final referrals = referralsSnapshot.docs.length;

      return {
        'totalExpenses': totalExpenses,
        'totalDistinctLogDays': distinctDays.length,
        'monthsUnderBudget': monthsUnderBudget,
        'billsPaid': billsPaid,
        'missedBills': missedBills,
        'goalsDone': goalsDone,
        'score': userData['score'] ?? 0,
        'streak': userData['streak'] ?? 0,
        'noSpendDays': noSpendDays,
        'needsPct': needsPct,
        'exports': exports,
        'tipsUsed': tipsUsed,
        'missionsDone': missionsDone,
        'badgesUnlockedLast7': badgesUnlockedLast7,
        'scoreDays90': scoreDays90,
        'referrals': referrals,
      };
    } catch (e) {
      print('❌ BadgeContextBuilder: Error building context - $e');
      return _getDefaultContext();
    }
  }

  Map<String, dynamic> _getDefaultContext() {
    return {
      'totalExpenses': 0,
      'totalDistinctLogDays': 0,
      'monthsUnderBudget': 0,
      'billsPaid': 0,
      'missedBills': 0,
      'goalsDone': 0,
      'score': 0,
      'streak': 0,
      'noSpendDays': 0,
      'needsPct': 0,
      'exports': 0,
      'tipsUsed': 0,
      'missionsDone': 0,
      'badgesUnlockedLast7': 0,
      'scoreDays90': 0,
      'referrals': 0,
    };
  }
}
