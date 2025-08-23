
import 'package:cloud_firestore/cloud_firestore.dart';

class SavingGoal {
  final String id;
  final String title;
  final double amount;
  final double savedSoFar;
  final DateTime targetDate;
  final bool completed;

  SavingGoal({
    required this.id,
    required this.title,
    required this.amount,
    required this.savedSoFar,
    required this.targetDate,
    this.completed = false,
  });

  factory SavingGoal.fromMap(String id, Map<String, dynamic> data) {
    return SavingGoal(
      id: id,
      title: data['title'],
      amount: data['amount'].toDouble(),
      savedSoFar: data['savedSoFar'].toDouble(),
      targetDate: (data['targetDate'] as Timestamp).toDate(),
      completed: data['completed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "title": title,
      "amount": amount,
      "savedSoFar": savedSoFar,
      "targetDate": targetDate,
      "completed": completed,
      "createdAt": DateTime.now(),
    };
  }
}
