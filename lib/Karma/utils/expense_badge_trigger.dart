import 'package:flutter/material.dart';
import '../services/badge_engine.dart';

class ExpenseBadgeTrigger {
  final String uid;
  final BuildContext context;

  ExpenseBadgeTrigger(this.uid, this.context);

  Future<void> triggerAfterExpense() async {
    final badgeEngine = BadgeEngine(uid, context);
    await badgeEngine.evaluate();
  }
}
