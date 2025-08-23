import 'dart:convert';
import 'package:flutter/services.dart';

class TipsService {
  Future<List<String>> loadTips() async {
    final String jsonString = await rootBundle.loadString('assets/financial_tips.json');
    final List<dynamic> data = jsonDecode(jsonString);
    return List<String>.from(data);
  }
}
