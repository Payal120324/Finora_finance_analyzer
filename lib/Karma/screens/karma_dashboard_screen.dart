import 'package:flutter/material.dart' hide Badge;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/karma_service.dart';
import '../services/mission_service.dart';
import '../widgets/karma_score_meter.dart';
import '../widgets/streak_bar.dart';
import '../widgets/mission_card.dart';
import '../widgets/advice_card.dart';
import '../models/karma_metrics.dart';
import '../models/karma_mission.dart';
import '../services/badge_engine.dart';
import '../services/badge_service.dart';

class KarmaDashboardScreen extends StatefulWidget {
  final String uid;
  const KarmaDashboardScreen({super.key, required this.uid});

  @override
  State<KarmaDashboardScreen> createState() => _KarmaDashboardScreenState();
}

class _KarmaDashboardScreenState extends State<KarmaDashboardScreen> {
  late final KarmaService kSvc;
  late final MissionService mSvc;
  late final BadgeService bSvc;

  bool _invalidUid = false;

  @override
  void initState() {
    super.initState();
    if (widget.uid.isEmpty) {
      _invalidUid = true;
      return;
    }
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || currentUser.uid != widget.uid) {
        _invalidUid = true;
        return;
      }
    } catch (e) {
      _invalidUid = true;
      return;
    }

    kSvc = KarmaService(widget.uid);
    mSvc = MissionService(widget.uid);
    bSvc = BadgeService(widget.uid);
    
    _migrateExistingBadges();
  }

  Future<void> _migrateExistingBadges() async {
    final firestore = FirebaseFirestore.instance;
    
    try {
      final userDoc = await firestore.collection('users').doc(widget.uid).get();
      if (!userDoc.exists) return;
      
      final badgesSnapshot = await firestore
          .collection('users')
          .doc(widget.uid)
          .collection('badges')
          .where('isUnlocked', isEqualTo: true)
          .get();
      
      final unlockedBadgeCount = badgesSnapshot.docs.length;
      final userData = userDoc.data() ?? {};
      final hasMigrated = userData['hasMigratedBadges'] ?? false;
      
      if (unlockedBadgeCount > 0 && !hasMigrated) {
        await firestore.collection('users').doc(widget.uid).update({
          'totalBadgesUnlocked': unlockedBadgeCount,
          'hasMigratedBadges': true,
        });
      } else if (unlockedBadgeCount > 0 && hasMigrated) {
        // Already migrated
      } else {
        await firestore.collection('users').doc(widget.uid).update({
          'hasMigratedBadges': true,
        });
      }
    } catch (e) {
      print('Error during karma migration: $e');
    }
  }

  Future<Map<String, dynamic>> _buildContextMap() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
      if (!doc.exists) {
        print('User document does not exist for uid: ${widget.uid}');
        return {};
      }
      final data = doc.data()!;
      
      // Count unlocked badges
      final badgesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('badges')
          .where('unlocked', isEqualTo: true)
          .get();
      
      final unlockedBadgeCount = badgesSnapshot.docs.length;
      
      // Count total expenses from logs
      final logsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('logs')
          .get();
      
      int totalExpenses = 0;
      for (var logDoc in logsSnapshot.docs) {
        final logData = logDoc.data();
        if (logData['amount'] != null) {
          totalExpenses += (logData['amount'] as num).toInt();
        }
      }
      
      // Use the actual score from Firestore
      final actualScore = (data['karmaScore'] ?? data['score'] ?? 50).clamp(0, 100);
      
      return {
        'totalExpenses': totalExpenses,
        'totalLogs': data['totalLogs'] ?? logsSnapshot.docs.length,
        'totalDistinctLogDays': data['totalDistinctLogDays'] ?? 0,
        'monthsUnderBudget': data['monthsUnderBudget'] ?? 0,
        'billsPaid': data['billsPaid'] ?? 0,
        'missedBills': data['missedBills'] ?? 0,
        'goalsDone': data['goalsDone'] ?? 0,
        'noSpendDays': data['noSpendDays'] ?? 0,
        'needsPct': data['needsPct'] ?? 0,
        'streak': data['streak'] ?? 0,
        'exports': data['exports'] ?? 0,
        'tipsUsed': data['tipsUsed'] ?? 0,
        'missionsDone': data['missionsDone'] ?? 0,
        'badgesUnlockedLast7': data['badgesUnlockedLast7'] ?? 0,
        'score': actualScore,
        'scoreDays90': data['scoreDays90'] ?? 0,
        'referrals': data['referrals'] ?? 0,
        'totalBadgesUnlocked': unlockedBadgeCount,
        'budgetUsed': data['budgetUsed'] ?? 0,
      };
    } catch (e) {
      print('Error fetching user data from Firestore: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_invalidUid) {
      return Scaffold(
        appBar: AppBar(title: const Text('Karma Dashboard')),
        body: const Center(
          child: Text(
            'Invalid user ID. Please log in again.',
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Karma Dashboard')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _buildContextMap(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Error loading metrics: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final contextMap = snap.data!;
          final m = KarmaMetrics(
            score: (contextMap['score'] ?? 0) == 0 ? 50 : contextMap['score'],
            streak: contextMap['streak'] ?? 0,
            budgetUsed: contextMap['budgetUsed'] ?? 0,
            goalsDone: contextMap['goalsDone'] ?? 0,
          );
          final advice = _advice(m);

          // Evaluate badges asynchronously
          Future.microtask(() async {
            print('🔍 KarmaDashboard.build: Starting badge evaluation');
            final engine = BadgeEngine(widget.uid, context);
            await engine.evaluate();
            print('🔍 KarmaDashboard.build: Badge evaluation completed');
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KarmaScoreMeter(score: m.score),
                const SizedBox(height: 16),
                StreakBar(streak: m.streak.clamp(0, 7)),
                const SizedBox(height: 16),
                AdviceCard(advice: advice),
                const SizedBox(height: 16),
                Text('Missions', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: mSvc.streamMissions(),
                  builder: (context, msnap) {
                    if (msnap.hasError) {
                      return Center(child: Text('Error loading missions: ${msnap.error}'));
                    }
                    if (!msnap.hasData) {
                      return const CircularProgressIndicator();
                    }
                    if (msnap.data!.isEmpty) {
                      return const Text('No missions available for this week.');
                    }
                    return Column(children: msnap.data!.map((m) {
                      final mission = KarmaMission(
                        id: m['id'] ?? '',
                        title: m['title'] ?? 'Untitled',
                        description: m['description'] ?? '',
                        done: m['done'] ?? false,
                      );
                      return GestureDetector(
                        onTap: () async {
                          if (!(m['done'] ?? false)) {
                            await mSvc.completeMission(mission.id);
                            setState(() {}); // Refresh after mission completion
                          }
                        },
                        child: MissionCard(mission: mission),
                      );
                    }).toList());
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  String _advice(KarmaMetrics m) {
    if (m.score < 50) return 'Score low. Log daily & stay under budget for a boost.';
    if (m.score < 80) return 'Great! Hit a 7-day streak to enter healthy zone.';
    return 'Excellent! Maintain habits & consider raising your saving goal';
  }
}
