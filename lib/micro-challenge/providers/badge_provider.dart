import 'package:flutter/foundation.dart';
import '../services/badge_service.dart';
import '../models/badge.dart';

class BadgeProvider extends ChangeNotifier {
  final BadgeService _badgeService = BadgeService();
  List<Badge> _badges = [];
  bool _isLoading = false;
  String? _error;

  List<Badge> get badges => _badges;
  bool get isLoading => _isLoading;
  String? get error => _error;

  BadgeProvider() {
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _badges = await _badgeService.getAllBadgesWithStatus();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshBadges() async {
    await _loadBadges();
  }

  Future<void> unlockBadgeForChallenge(String challengeId) async {
    try {
      await _badgeService.unlockBadge(challengeId);
      await refreshBadges(); // Refresh badges after unlocking
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> resetAllBadges() async {
    try {
      await _badgeService.resetAllBadges();
      await refreshBadges();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
