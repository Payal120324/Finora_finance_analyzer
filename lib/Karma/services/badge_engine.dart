import 'package:flutter/material.dart' hide Badge;
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../badges/badge_rules.dart';
import '../models/badge.dart';
import 'badge_service.dart';
import 'badge_context_builder.dart';
import '../utils/badge_unlock_dialog.dart';

class BadgeEngine {
  final String uid;
  final BuildContext context;
  BadgeEngine(this.uid, this.context);

  Future<void> evaluate() async {
    final svc = BadgeService(uid);
    final firestore = FirebaseFirestore.instance;
    final contextBuilder = BadgeContextBuilder(uid);

    // Build the context with current metrics
    final ctx = await contextBuilder.buildContext();
    print('🔍 BadgeEngine.evaluate: Context built: $ctx');
    
    for (final rule in BadgeRules.all) {
      final unlocked = await svc.isBadgeUnlocked(rule.id);
      final shouldUnlock = rule.shouldUnlock(ctx);
      
      print('🔍 BadgeEngine.evaluate: Checking rule ${rule.id} (${rule.title})');
      print('🔍 BadgeEngine.evaluate: Current unlocked status: $unlocked');
      print('🔍 BadgeEngine.evaluate: Should unlock: $shouldUnlock');
      
      if (shouldUnlock && !unlocked) {
        print('🔍 BadgeEngine.evaluate: UNLOCKING badge ${rule.id}');
        await svc.unlockBadge(rule.id);

        // Get the badge data to show in dialog
        final badge = Badge(
          id: rule.id,
          name: rule.title,
          description: rule.title,
          type: BadgeType.bronze,
          icon: rule.icon,
          unlockedAt: DateTime.now(),
          isUnlocked: true,
        );

        // Increment karma score by 5 points
        try {
          await firestore.collection('users').doc(uid).update({
            'karmaScore': FieldValue.increment(5),
            'totalBadgesUnlocked': FieldValue.increment(1),
            'score': FieldValue.increment(5), // Also update the main score field
          });
        } catch (e) {
          print('Error incrementing karma score: $e');
        }

        // Show dialog
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (_) => BadgeUnlockDialog(badge: badge),
          );
        }

        // Notification
        try {
          await AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
              channelKey: 'badge_alerts',
              title: '🏅 New Badge!',
              body: 'You leveled up: ${badge.name} (+5 karma points)',
            ),
          );
        } catch (e) {
          // ignore notification errors
        }
      } else if (rule.shouldRevoke(ctx) && unlocked) {
        // Note: Badge revocation is not implemented in the current BadgeService
        // This would require additional implementation
        print('Badge revocation requested for ${rule.id} but not implemented');
      }
    }
  }
}
