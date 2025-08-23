import 'package:flutter/material.dart' hide Badge;
import '../models/badge.dart';

class BadgePopup extends StatelessWidget {
  final Badge badge;
  const BadgePopup({super.key, required this.badge});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (badge.isUnlocked) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(badge.name),
              content: Text(badge.description),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))
              ],
            ),
          );
        }
      },
      child: Opacity(
        opacity: badge.isUnlocked ? 1.0 : 0.4,
        child: Column(
          children: [
            Text(
              badge.icon,
              style: const TextStyle(fontSize: 48),
            ),
            Text(badge.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
