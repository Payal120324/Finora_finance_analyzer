import 'package:flutter/material.dart';
import '../services/karma_service.dart';
import '../models/karma_event.dart';

class KarmaLogScreen extends StatelessWidget {
  final String uid;
  const KarmaLogScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Score Timeline')),
        body: StreamBuilder<List<KarmaEvent>>(
          stream: KarmaService(uid).streamEvents(limit: 50),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final events = snap.data!;
            return ListView.separated(
              itemCount: events.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (context, i) {
                final e = events[i];
                final color = e.delta >= 0 ? Colors.green : Colors.red;
                final sign = e.delta >= 0 ? '+' : '';
                return ListTile(
                  leading: Icon(Icons.circle, size: 10, color: color),
                  title: Text(e.reason),
                  trailing: Text('$sign${e.delta}', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                  subtitle: Text(e.date.toLocal().toString().split(' ')[0]),
                );
              },
            );
          },
        ),
      );
}
