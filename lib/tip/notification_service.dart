import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';

class NotificationService {
  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'daily_tip_channel',
          channelName: 'Daily Tips',
          channelDescription: 'Notifications for daily financial tips',
          defaultColor:  Color(0xFF4CAF50),
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: true,
        )
      ],
      debug: true,
    );
  }

  static Future<void> show(String title, String body) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: 'daily_tip_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }
}
