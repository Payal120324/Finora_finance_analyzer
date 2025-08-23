import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'SavingGoal.dart';
import 'SavingGoalService.dart';

class GoalListScreen extends StatefulWidget {
  final String userId;
  const GoalListScreen({super.key, required this.userId});

  @override
  // ignore: library_private_types_in_public_api
  _GoalListScreenState createState() => _GoalListScreenState();
}

class _GoalListScreenState extends State<GoalListScreen> {
  Stream<List<SavingGoal>> _goalsStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('goals')
        .where('completed', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
.map((doc) => SavingGoal.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> _deleteGoal(String goalId) async {
    await SavingGoalService().deleteGoal(widget.userId, goalId);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.black : null;

    return Scaffold(
      appBar: AppBar(title: const Text('My Saving Goals')),
      body: StreamBuilder<List<SavingGoal>>(
        stream: _goalsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final goals = snapshot.data!;
          if (goals.isEmpty) {
            return const Center(child: Text('No saving goals yet.'));
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: ListView.builder(
              itemCount: goals.length,
              itemBuilder: (context, index) {
                final goal = goals[index];
                final monthsLeft = goal.targetDate.difference(DateTime.now()).inDays ~/ 30;
                final remaining = goal.amount - goal.savedSoFar;
                final perMonth = monthsLeft > 0 ? (remaining / monthsLeft) : remaining;
                final progress = goal.savedSoFar / goal.amount;
                final isCompleted = goal.savedSoFar >= goal.amount;

                return Card(
                  color: isCompleted ? Colors.green[100] : Colors.white,
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(
                      goal.title,
                      style: TextStyle(color: textColor),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Target: ₹${goal.amount.toStringAsFixed(2)}",
                          style: TextStyle(color: textColor),
                        ),
                        Text(
                          "Saved: ₹${goal.savedSoFar.toStringAsFixed(2)}",
                          style: TextStyle(color: textColor),
                        ),
                        Text(
                          "Monthly Needed: ₹${perMonth.toStringAsFixed(2)}",
                          style: TextStyle(color: textColor),
                        ),
                        SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.deepPurpleAccent.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurpleAccent),
                          minHeight: 6,
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Delete Goal',
                      onPressed: () async {
                        await _deleteGoal(goal.id);
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
