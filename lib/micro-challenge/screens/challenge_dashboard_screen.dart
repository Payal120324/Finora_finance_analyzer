import 'package:flutter/material.dart';
import '../models/weekly_challenge.dart';
import '../services/weekly_challenge_service.dart';
import '../widgets/countdown_timer_widget.dart';
import '../widgets/unlocked_badge_display.dart';
import '../widgets/weekly_challenge_card.dart';
import '../models/badge.dart' as app_badge;

class ChallengeDashboardScreen extends StatefulWidget {
  const ChallengeDashboardScreen({super.key});

  @override
  State<ChallengeDashboardScreen> createState() => _ChallengeDashboardScreenState();
}

class _ChallengeDashboardScreenState extends State<ChallengeDashboardScreen> {
  final WeeklyChallengeService _weeklyChallengeService = WeeklyChallengeService();
  late Future<WeeklyChallenge> _currentChallenge;
  late Future<bool> _isCompleted;
  DateTime _nextMonday = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadChallenge();
    _calculateNextMonday();
  }

  void _calculateNextMonday() {
    final now = DateTime.now();
    final daysUntilMonday = (8 - now.weekday) % 7;
    if (daysUntilMonday == 0) {
      _nextMonday = now.add(const Duration(days: 7));
    } else {
      _nextMonday = now.add(Duration(days: daysUntilMonday));
    }
  }

  void _loadChallenge() {
    _currentChallenge = _weeklyChallengeService.getCurrentWeeklyChallenge();
    _isCompleted = _currentChallenge.then((challenge) {
      return _weeklyChallengeService.isChallengeCompleted(challenge.id);
    });
  }

  void _handleComplete(WeeklyChallenge challenge) async {
    await _weeklyChallengeService.markChallengeCompleted(challenge.id);
    
    // Show badge popup
    if (mounted) {
      _showBadgeUnlockedDialog(challenge);
    }
    
    // Refresh state
    setState(() {
      _isCompleted = _weeklyChallengeService.isChallengeCompleted(challenge.id);
    });
  }

  void _showBadgeUnlockedDialog(WeeklyChallenge challenge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('🎉 Challenge Completed!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              challenge.badgeName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    challenge.badgeIcon,
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    challenge.description,
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Challenge'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _loadChallenge();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<WeeklyChallenge>(
        future: _currentChallenge,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final challenge = snapshot.data!;
            return FutureBuilder<bool>(
              future: _isCompleted,
              builder: (context, completedSnapshot) {
                final isCompleted = completedSnapshot.data ?? false;
                
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Countdown Timer
                        CountdownTimerWidget(
                          nextMonday: _nextMonday,
                          onTimerComplete: () {
                            setState(() {
                              _loadChallenge();
                              _calculateNextMonday();
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Completed Section - Only show badge when completed
                        if (isCompleted) ...[
                          const SizedBox(height: 16),
                          UnlockedBadgeDisplay(
                            badge: app_badge.Badge(
                              id: challenge.badgeId,
                              name: challenge.badgeName,
                              description: challenge.description,
                              title: challenge.badgeName,
                              icon: challenge.badgeIcon,
                              animationPath: challenge.animationPath,
                              difficulty: challenge.difficulty,
                              category: challenge.category,
                              isUnlocked: true,
                            ),
                            onTap: () {
                              _showBadgeUnlockedDialog(challenge);
                            },
                          ),
                        ] else ...[
                          // Challenge Card - Only show when not completed
                          WeeklyChallengeCard(
                            challenge: challenge,
                            onComplete: () => _handleComplete(challenge),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  // ignore: unused_element
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Budgeting':
        return Colors.blue;
      case 'Saving':
        return Colors.green;
      case 'Tracking':
        return Colors.purple;
      case 'Food':
        return Colors.orange;
      case 'Digital':
        return Colors.red;
      case 'Audit':
        return Colors.teal;
      case 'Control':
        return Colors.indigo;
      case 'Method':
        return Colors.pink;
      case 'Education':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
}
