import 'package:shared_preferences/shared_preferences.dart';

class UserSessionService {
  static const String _firstLoginDateKey = 'first_login_date';
  static const String _lastLoginDateKey = 'last_login_date';
  static const String _isNewUserKey = 'is_new_user';

  /// Check if user is new (first time logging in)
  Future<bool> isNewUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isNewUserKey) ?? true;
  }

  /// Record user login and determine if it's their first Monday login
  Future<void> recordUserLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final isNew = await isNewUser();
    
    // Record first login date if this is a new user
    if (isNew) {
      await prefs.setString(_firstLoginDateKey, now.toIso8601String());
      await prefs.setBool(_isNewUserKey, false);
    }
    
    // Always update last login date
    await prefs.setString(_lastLoginDateKey, now.toIso8601String());
  }

  /// Get the user's first login date
  Future<DateTime?> getFirstLoginDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString(_firstLoginDateKey);
    if (dateString != null) {
      return DateTime.parse(dateString);
    }
    return null;
  }

  /// Get the user's last login date
  Future<DateTime?> getLastLoginDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString(_lastLoginDateKey);
    if (dateString != null) {
      return DateTime.parse(dateString);
    }
    return null;
  }

  /// Check if user logged in on Monday
  bool isMondayLogin(DateTime loginDate) {
    return loginDate.weekday == DateTime.monday;
  }

  /// Check if user logged in mid-week (Tuesday to Sunday)
  bool isMidWeekLogin(DateTime loginDate) {
    return loginDate.weekday >= DateTime.tuesday && 
           loginDate.weekday <= DateTime.sunday;
  }

  /// Check if user should see challenges (new user on Monday)
  Future<bool> shouldShowChallenges() async {
    final firstLoginDate = await getFirstLoginDate();
    final lastLoginDate = await getLastLoginDate();
    
    if (firstLoginDate == null || lastLoginDate == null) {
      return false;
    }

    // User should see challenges if:
    // 1. This is their first login, AND
    // 2. They logged in on a Monday
    final isFirstLogin = firstLoginDate.isAtSameMomentAs(lastLoginDate);
    return isFirstLogin && isMondayLogin(firstLoginDate);
  }

  /// Check if user should see tip card (mid-week login)
  Future<bool> shouldShowTipCard() async {
    final firstLoginDate = await getFirstLoginDate();
    final lastLoginDate = await getLastLoginDate();
    
    if (firstLoginDate == null || lastLoginDate == null) {
      return false;
    }

    // User should see tip card if:
    // 1. This is their first login, AND
    // 2. They logged in mid-week (Tuesday to Sunday)
    final isFirstLogin = firstLoginDate.isAtSameMomentAs(lastLoginDate);
    return isFirstLogin && isMidWeekLogin(firstLoginDate);
  }

  /// Reset user session (for testing purposes)
  Future<void> resetUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_firstLoginDateKey);
    await prefs.remove(_lastLoginDateKey);
    await prefs.remove(_isNewUserKey);
  }
}
