import 'package:flutter/material.dart' hide Badge;
import '../models/badge.dart';
import '../services/badge_service.dart';
import '../utils/badge_unlock_dialog.dart';

class BadgePopupManager {
  final String uid;
  final BuildContext context;
  
  BadgePopupManager(this.uid, this.context);

  Future<void> checkAndShowNewBadges() async {
    final badgeService = BadgeService(uid);
    final badges = await badgeService.getAllBadges();
    
    // Get recently unlocked badges (unlocked in last 24 hours)
    final recentBadges = badges.where((badge) {
      final now = DateTime.now();
      final unlockTime = badge.unlockedAt;
      if (unlockTime == null) return false;
      return now.difference(unlockTime).inHours <= 24;
    }).toList();
    
    if (recentBadges.isNotEmpty) {
      // Show badges one by one
      for (final badge in recentBadges) {
        await _showBadgePopup(badge);
      }
    }
  }

  Future<void> _showBadgePopup(Badge badge) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BadgeUnlockDialog(badge: badge),
    );
  }
}
