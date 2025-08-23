import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../models/weekly_challenge.dart';

class WeeklyChallengeCard extends StatelessWidget {
  final WeeklyChallenge challenge;
  final VoidCallback? onComplete;

  const WeeklyChallengeCard({
    super.key,
    required this.challenge,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 120,
          maxHeight: 300, // Prevent overflow
        ),
        child: Padding(
          padding: const EdgeInsets.all(12), // Reduced padding
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Challenge Animation - reduced height
              SizedBox(
                height: 80, // Reduced from 120
                child: Lottie.asset(
                  challenge.animationPath,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 8), // Reduced from 16
              
              // Challenge Title - smaller font
              Text(
                challenge.title,
                style: const TextStyle(
                  fontSize: 16, // Reduced from 20
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4), // Reduced from 8
              
              // Challenge Description - smaller font
              Text(
                challenge.description,
                style: const TextStyle(
                  fontSize: 12, // Reduced from 14
                  color: Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6), // Reduced from 8
              
              // Difficulty and Category - more compact
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Reduced padding
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(8), // Reduced from 12
                    ),
                    child: Text(
                      '${challenge.difficulty}/5',
                      style: const TextStyle(fontSize: 11, color: Colors.blue), // Reduced from 12
                    ),
                  ),
                  const SizedBox(width: 4), // Reduced from 8
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Reduced padding
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8), // Reduced from 12
                    ),
                    child: Text(
                      challenge.category,
                      style: const TextStyle(fontSize: 11, color: Colors.green), // Reduced from 12
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8), // Reduced from 16
              
              // Badge Preview - slightly larger but still compact
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      challenge.badgeIcon,
                      style: const TextStyle(fontSize: 18), // Increased from 16
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        challenge.badgeName,
                        style: const TextStyle(
                          fontSize: 13, // Increased from 12
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(), // Takes remaining space
              
              // Complete Button - more compact
              SizedBox(
                width: double.infinity,
                height: 36, // Reduced height
                child: ElevatedButton(
                  onPressed: onComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Reduced padding
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18), // Reduced from 24
                    ),
                  ),
                  child: const Text(
                    'Complete',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold), // Reduced from 16
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
