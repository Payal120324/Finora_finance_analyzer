import 'package:flutter/material.dart';

class StreakBar extends StatelessWidget {
  final int streak;
  const StreakBar({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final filled = i < streak;
        return Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled ? Colors.green : Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(days[i], style: TextStyle(color: filled ? Colors.white : Colors.black)),
        );
      }),
    );
  }
}
