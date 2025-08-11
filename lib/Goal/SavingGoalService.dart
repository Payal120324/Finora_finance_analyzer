import 'package:cloud_firestore/cloud_firestore.dart';
import 'SavingGoal.dart';

class SavingGoalService {
  final CollectionReference users = FirebaseFirestore.instance.collection('users');

  Future<void> addGoal(String userId, SavingGoal goal) async {
    await users.doc(userId).collection('goals').add(goal.toMap());
  }

  Future<List<SavingGoal>> fetchGoals(String userId, {bool? completed}) async {
    Query query = users.doc(userId).collection('goals');
    if (completed != null) {
      query = query.where('completed', isEqualTo: completed);
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => SavingGoal.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
  }

  Future<void> updateSavedAmount(String userId, String goalId, double newSavedAmount) async {
    await users.doc(userId).collection('goals').doc(goalId).update({"savedSoFar": newSavedAmount});
  }

  Future<void> updateGoalCompleted(String userId, String goalId, bool completed) async {
    await users.doc(userId).collection('goals').doc(goalId).update({"completed": completed});
  }

  Future<void> deleteGoal(String userId, String goalId) async {
    await users.doc(userId).collection('goals').doc(goalId).delete();
  }
}
