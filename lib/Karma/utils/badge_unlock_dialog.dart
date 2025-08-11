import 'package:flutter/material.dart' hide Badge;
import 'package:lottie/lottie.dart';
import '../models/badge.dart';

class BadgeUnlockDialog extends StatelessWidget {
  final Badge badge;
  const BadgeUnlockDialog({super.key, required this.badge});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('🎉 Achievement Unlocked!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Lottie.asset('assets/animations/success.json', width: 120),
          const SizedBox(height: 10),
          Image.asset('assets/badges/${badge.icon}', width: 60),
          const SizedBox(height: 8),
          Text(badge.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Awesome!'),
        ),
      ],
    );
  }
}
