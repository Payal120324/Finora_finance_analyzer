import 'package:flutter/material.dart' hide Badge;
import '../models/badge.dart';

class BadgeTile extends StatelessWidget {
  final Badge badge;
  const BadgeTile({super.key, required this.badge});

  String _formatDate(dynamic date) {
    if (date == null) return "Not yet unlocked";
    
    DateTime parsedDate;
    if (date is String) {
      try {
        parsedDate = DateTime.parse(date);
      } catch (e) {
        return "Invalid date";
      }
    } else if (date is DateTime) {
      parsedDate = date;
    } else {
      return "Invalid date";
    }
    
    return "Unlocked on ${parsedDate.toLocal().toString().split(' ')[0]}";
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Image.asset('assets/badges/${badge.icon}', width: 40),
      title: Text(badge.name),
      subtitle: Text(_formatDate(badge.unlockedAt)),
    );
  }
}
