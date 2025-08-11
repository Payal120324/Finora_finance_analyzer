import 'package:flutter/material.dart' hide Badge;
import 'package:lottie/lottie.dart';
import '../services/badge_service.dart';
import '../models/badge.dart';
import '../widgets/badge_card.dart';
import '../badges/badge_rules.dart';

class BadgeGalleryScreen extends StatelessWidget {
  final String uid;
  const BadgeGalleryScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('🏆 Badge Gallery')),
        body: StreamBuilder<List<Badge>>(
          stream: BadgeService(uid).stream(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(child: Text('Error loading badges: ${snap.error}'));
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final unlocked = {for (var b in snap.data!) b.id: b};

            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.0, // square boxes
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: BadgeRules.all.length,
                itemBuilder: (context, index) {
                  final rule = BadgeRules.all[index];
                  final badge = unlocked[rule.id];
                  final level = index + 1;

                  return BadgeCard(
                    title: 'Lv $level · ${rule.title}',
                    icon: rule.icon,
                    isUnlocked: badge != null,
                    badge: badge,
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) {
                        final screenHeight = MediaQuery.of(context).size.height;
                        final screenWidth = MediaQuery.of(context).size.width;

                        return SafeArea(
                          child: Container(
                            constraints: BoxConstraints(
                              maxHeight: screenHeight * 0.85,
                            ),
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Lottie Animation (safely constrained)
                                    SizedBox(
                                      width: screenWidth * 0.6,
                                      height: 150,
                                      child: Lottie.asset(
                                        'assets/${rule.icon}',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Badge Title
                                    Text(
                                      rule.title,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),

                                    // Unlock Info
                                    Text(
                                      badge != null && badge.unlockedAt != null
                                          ? 'Unlocked on ${badge.unlockedAt!.toLocal().toString().split(' ')[0]}'
                                          : 'Not unlocked yet. Check rule in app!',
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      );
}
