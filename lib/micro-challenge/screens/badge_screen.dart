import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../services/weekly_challenge_service.dart';
import '../services/badge_service.dart';

class BadgeScreen extends StatefulWidget {
  const BadgeScreen({super.key});

  @override
  State<BadgeScreen> createState() => _BadgeScreenState();
}

class _BadgeScreenState extends State<BadgeScreen> {
  final WeeklyChallengeService _challengeService = WeeklyChallengeService();
  final BadgeService _badgeService = BadgeService();
  late List<dynamic> _badges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    try {
      final challenges = _challengeService.getAllChallenges();
      final badgesWithStatus = await Future.wait(
        challenges.map((challenge) async {
          final isUnlocked = await _badgeService.isBadgeUnlocked(challenge.badgeId);
          return {
            'id': challenge.badgeId,
            'name': challenge.badgeName,
            'icon': challenge.badgeIcon,
            'description': challenge.description,
            'title': challenge.title,
            'isUnlocked': isUnlocked,
            'animationPath': challenge.animationPath,
            'difficulty': challenge.difficulty,
            'category': challenge.category,
          };
        }),
      );
      
      setState(() {
        _badges = badgesWithStatus;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading badges: $e');
    }
  }

  Color _getDifficultyColor(int difficulty) {
    switch (difficulty) {
      case 1:
      case 2:
        return Colors.green;
      case 3:
        return Colors.orange;
      case 4:
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Financial Achievement Badges',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBadges,
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _badges.length,
                itemBuilder: (context, index) {
                  final badge = _badges[index];
                  return _buildBadgeCard(badge);
                },
              ),
            ),
    );
  }

  Widget _buildBadgeCard(Map<String, dynamic> badge) {
    final isUnlocked = badge['isUnlocked'] as bool;
    
    return GestureDetector(
      onTap: () => _showBadgeDetails(badge),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha : 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isUnlocked 
                        ? _getDifficultyColor(badge['difficulty']).withValues(alpha : 0.2)
                        : Colors.grey.withValues(alpha : 0.1),
                  ),
                ),
                if (isUnlocked && badge['animationPath'] != null)
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: Lottie.asset(
                      badge['animationPath'],
                      fit: BoxFit.contain,
                    ),
                  )
                else
                  Text(
                    badge['icon'] as String,
                    style: const TextStyle(fontSize: 40),
                  ),
                if (!isUnlocked)
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha : 0.5),
                    ),
                    child: const Icon(
                      Icons.lock,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              badge['name'] as String,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getDifficultyColor(badge['difficulty']).withValues(alpha : 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Level ${badge['difficulty']}',
                style: TextStyle(
                  fontSize: 10,
                  color: _getDifficultyColor(badge['difficulty']),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBadgeDetails(Map<String, dynamic> badge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (badge['isUnlocked'] as bool)
                          ? _getDifficultyColor(badge['difficulty']).withValues(alpha : 0.2)
                          : Colors.grey.withValues(alpha : 0.1),
                    ),
                  ),
                  if ((badge['isUnlocked'] as bool) && badge['animationPath'] != null)
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Lottie.asset(
                        badge['animationPath'],
                        fit: BoxFit.contain,
                      ),
                    )
                  else
                    Text(
                      badge['icon'] as String,
                      style: const TextStyle(fontSize: 60),
                    ),
                  if (!(badge['isUnlocked'] as bool))
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha : 0.5),
                      ),
                      child: const Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                badge['name'] as String,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                badge['title'] as String,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getDifficultyColor(badge['difficulty']).withValues(alpha : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Difficulty: Level ${badge['difficulty']}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getDifficultyColor(badge['difficulty']),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                badge['description'] as String,
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Category: ${badge['category']}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}