import 'package:flutter/material.dart' hide Badge;
import 'package:lottie/lottie.dart';
import '../models/badge.dart';

class BadgeCard extends StatelessWidget {
  final String title;
  final String icon;
  final bool isUnlocked;
  final Badge? badge;
  final VoidCallback? onTap;

  const BadgeCard({
    super.key,
    required this.title,
    required this.icon,
    required this.isUnlocked,
    this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/$icon',
                  width: 60,
                  animate: isUnlocked,
                  repeat: true,
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 247, 247, 247),
                  ),
                ),
              ],
            ),
            if (!isUnlocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.lock,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
