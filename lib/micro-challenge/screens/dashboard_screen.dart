import 'package:flutter/material.dart';
import '../services/weekly_challenge_service.dart';
import '../services/user_session_service.dart';
import '../models/weekly_challenge.dart';
import '../widgets/weekly_challenge_card.dart';
import '../widgets/weekly_badge_popup.dart';
import '../widgets/tip_card.dart';
import '../widgets/tip_card_widget.dart';
import '../models/badge.dart' as app_badge;

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  final WeeklyChallengeService _weeklyChallengeService = WeeklyChallengeService();
  final UserSessionService _userSessionService = UserSessionService();
  late Future<WeeklyChallenge> _currentChallenge;
  late Future<bool> _isCompleted;
  bool _showWelcomeTip = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChallenge();
    _checkUserSession();
  }

  Future<void> _checkUserSession() async {
    // Record user login and check if they should see welcome tip
    await _userSessionService.recordUserLogin();
    final shouldShowTipCard = await _userSessionService.shouldShowTipCard();
    setState(() {
      _showWelcomeTip = shouldShowTipCard;
      _isLoading = false;
    });
  }

  void _loadChallenge() {
    _currentChallenge = _weeklyChallengeService.getCurrentWeeklyChallenge();
    _currentChallenge.then((challenge) {
      setState(() {
        _isCompleted = _weeklyChallengeService.isChallengeCompleted(challenge.id);
      });
    });
  }

  void _handleComplete(WeeklyChallenge challenge) async {
    await _weeklyChallengeService.markChallengeCompleted(challenge.id);
    
    // Show badge popup
    if (mounted) {
      WeeklyBadgePopup.show(context, challenge);
    }
    
    // Refresh state
    setState(() {
      _isCompleted = _weeklyChallengeService.isChallengeCompleted(challenge.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_showWelcomeTip) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Welcome to Challenges!'),
        ),
        body: TipCardWidget(
          onDismiss: () {
            setState(() {
              _showWelcomeTip = false;
            });
          },
          onLearnMore: () {
            // Handle learn more action
          },
        ),
      );
    }

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
                
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      if (isCompleted)
                        Column(
                          children: [
                            const Text(
                              '💡 Financial Tip',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TipCard(
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
                              onClose: () {},
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: WeeklyChallengeCard(
                          challenge: challenge,
                          onComplete: isCompleted ? null : () => _handleComplete(challenge),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
