import 'package:flutter/material.dart';

class AdviceCard extends StatelessWidget {
  final String advice;
  const AdviceCard({super.key, required this.advice});

  @override
  Widget build(BuildContext context) => Card(
        color: Colors.blue[50],
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.lightbulb, color: Colors.blue),
              const SizedBox(width: 10),
              Expanded(child: Text(advice, style: const TextStyle(color: Colors.black))),
            ],
          ),
        ),
      );
}
