import 'package:awesome_notifications/awesome_notifications.dart';

class KarmaNotification {
  static void init() {
    AwesomeNotifications().initialize(null, [
      NotificationChannel(
        channelKey: 'badge_alerts',
        channelName: 'Badge Alerts',
        channelDescription: 'Unlock & milestone notifications',
        importance: NotificationImportance.High,
      )
    ]);
  }

  static Future<void> milestone(int score) => AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          channelKey: 'badge_alerts',
          title: '🎉 Score Milestone!',
          body: 'Great job! Your Karma Score hit $score.',
        ),
      );
}
