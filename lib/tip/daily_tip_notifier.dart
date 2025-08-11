import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'daily_tip_service.dart';

class DailyTipNotifier {
  static Future<void> showIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastShownDate = prefs.getString('lastTipShownDate');
    if (lastShownDate == today) return;

    final tip = await DailyTipService.getTodayTip();

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 100,
        channelKey: 'daily_tip_channel',
        title: '💡 Daily Financial Tip',
        body: tip,
        notificationLayout: NotificationLayout.Default,
      ),
    );

    await prefs.setString('lastTipShownDate', today);
  }
}
