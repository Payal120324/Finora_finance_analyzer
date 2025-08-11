import 'package:flutter/material.dart';
import '../models/karma_mission.dart';

class MissionCard extends StatelessWidget {
  final KarmaMission mission;
  const MissionCard({super.key, required this.mission});

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: Icon(
            mission.done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: mission.done ? Colors.green : Colors.grey,
          ),
          title: Text(mission.title),
          subtitle: Text(mission.description),
        ),
      );
}
