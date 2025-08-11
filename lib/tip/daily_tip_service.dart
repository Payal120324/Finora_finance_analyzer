import 'dart:convert';
import 'package:flutter/services.dart';

class DailyTipService {
  static Future<String> getTodayTip() async {
    final raw = await rootBundle.loadString('assets/financial_tips.json');
    final List<dynamic> tips = json.decode(raw);
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    final index = dayOfYear % tips.length;
    return tips[index];
  }
}
