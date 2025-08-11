import 'package:cloud_firestore/cloud_firestore.dart';

class KarmaEvent {
  final DateTime date;
  final int delta;
  final String reason;

  KarmaEvent({required this.date, required this.delta, required this.reason});

  Map<String, dynamic> toMap() => {
        'date': date,
        'delta': delta,
        'reason': reason,
      };

  factory KarmaEvent.fromMap(Map<String, dynamic> m) => KarmaEvent(
        date: (m['date'] as Timestamp).toDate(),
        delta: m['delta'],
        reason: m['reason'],
      );
}
