import 'dart:async';
import '../models/karma_metrics.dart';
import '../models/karma_event.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class KarmaService {
  final String uid;
  final StreamController<KarmaMetrics> _controller = StreamController<KarmaMetrics>.broadcast();
  late final StreamSubscription<DocumentSnapshot<Map<String, dynamic>>> _summarySubscription;

  KarmaService(this.uid) {
    final summaryDoc = FirebaseFirestore.instance.collection('users').doc(uid).collection('karma').doc('summary');
    _summarySubscription = summaryDoc.snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        final metrics = KarmaMetrics(
          score: data['score'] ?? 0,
          streak: data['streak'] ?? 0,
          goalsDone: data['goalsDone'] ?? 0,
          budgetUsed: data['budgetUsed'] ?? 0,
        );
        _controller.add(metrics);
      } else {
        _controller.add(KarmaMetrics.empty());
      }
    });
  }

  Stream<List<KarmaEvent>> streamEvents({int limit = 50}) {
    final eventsCol = FirebaseFirestore.instance.collection('users').doc(uid).collection('karma').doc('events').collection('events');
    return eventsCol
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => KarmaEvent.fromMap(doc.data())).toList());
  }

  Future<void> createDefaultUserDocument() async {
    final userDocRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final doc = await userDocRef.get();
    if (!doc.exists) {
      await userDocRef.set({
        'score': 50, // Start new users with 50 karma score
        'streak': 0,
        'budgetUsed': 0,
        'goalsDone': 0,
        'totalLogs': 0,
        'totalDistinctLogDays': 0,
        'monthsUnderBudget': 0,
        'billsPaid': 0,
        'missedBills': 0,
        'noSpendDays': 0,
        'needsPct': 0,
        'exports': 0,
        'tipsUsed': 0,
        'missionsDone': 0,
        'badgesUnlockedLast7': 0,
        'scoreDays90': 0,
        'referrals': 0,
        'totalBadgesUnlocked': 0,
        'hasInitializedBadges': false, // Flag to track badge initialization
        'isNewUser': true, // Flag to identify new users
      });
    }
  }

  Stream<KarmaMetrics> streamMetrics() {
    return _controller.stream;
  }

  Future<void> updateScore(int delta) async {
    final summaryDoc = FirebaseFirestore.instance.collection('users').doc(uid).collection('karma').doc('summary');
    await FirebaseFirestore.instance.runTransaction((txn) async {
      final summarySnap = await txn.get(summaryDoc);
      var currentScore = 0;
      if (summarySnap.exists) {
        final summaryData = summarySnap.data()!;
        currentScore = summaryData['score'] ?? 0;
      }
      final newScore = (currentScore + delta).clamp(0, 100);
      txn.update(summaryDoc, {'score': newScore});
    });
  }

  Future<int> getTotalLogs() async {
    final logsCol = FirebaseFirestore.instance.collection('users').doc(uid).collection('logs');
    final snapshot = await logsCol.get();
    return snapshot.docs.length;
  }

  Future<int> getTotalDistinctLogDays() async {
    final logsCol = FirebaseFirestore.instance.collection('users').doc(uid).collection('logs');
    final snapshot = await logsCol.get();
    final distinctDays = <String>{};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final date = data['date'] as Timestamp?;
      if (date != null) {
        distinctDays.add(date.toDate().toIso8601String().substring(0, 10));
      }
    }
    return distinctDays.length;
  }

  Future<int> getMonthsUnderBudget() async {
    final budgetCol = FirebaseFirestore.instance.collection('users').doc(uid).collection('budget');
    final snapshot = await budgetCol.where('underBudget', isEqualTo: true).get();
    return snapshot.docs.length;
  }

  Future<int> getBillsPaid() async {
    final billsCol = FirebaseFirestore.instance.collection('users').doc(uid).collection('bills');
    final snapshot = await billsCol.where('paid', isEqualTo: true).get();
    return snapshot.docs.length;
  }

  Future<int> getMissedBills() async {
    final billsCol = FirebaseFirestore.instance.collection('users').doc(uid).collection('bills');
    final snapshot = await billsCol.where('paid', isEqualTo: false).get();
    return snapshot.docs.length;
  }

  Future<int> getNoSpendDays() async {
    final spendCol = FirebaseFirestore.instance.collection('users').doc(uid).collection('spending');
    final snapshot = await spendCol.where('amount', isEqualTo: 0).get();
    return snapshot.docs.length;
  }

  Future<int> getNeedsPct() async {
    final needsDoc = FirebaseFirestore.instance.collection('users').doc(uid).collection('stats').doc('needsPct');
    final snapshot = await needsDoc.get();
    if (snapshot.exists) {
      final data = snapshot.data()!;
      return data['value'] ?? 0;
    }
    return 0;
  }

  Future<int> getExports() async {
    final exportsCol = FirebaseFirestore.instance.collection('users').doc(uid).collection('exports');
    final snapshot = await exportsCol.get();
    return snapshot.docs.length;
  }

  Future<int> getTipsUsed() async {
    final tipsCol = FirebaseFirestore.instance.collection('users').doc(uid).collection('tipsUsed');
    final snapshot = await tipsCol.get();
    return snapshot.docs.length;
  }

  Future<int> getScoreDays90() async {
    final scoreCol = FirebaseFirestore.instance.collection('users').doc(uid).collection('scoreDays90');
    final snapshot = await scoreCol.get();
    return snapshot.docs.length;
  }

  Future<int> getReferrals() async {
    final referralsCol = FirebaseFirestore.instance.collection('users').doc(uid).collection('referrals');
    final snapshot = await referralsCol.get();
    return snapshot.docs.length;
  }

  void dispose() {
    _summarySubscription.cancel();
    _controller.close();
  }
}
