import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseService {
  static CollectionReference _expensesCollection(String userId) =>
      FirebaseFirestore.instance.collection('users').doc(userId).collection('expenses');

  static Future<String?> addExpense({
    required String userId,
    required String category,
    required double amount,
    String? note,
    required DateTime date,
  }) async {
    try {
      await _expensesCollection(userId).add({
        'category': category,
        'amount': amount,
        'note': note ?? '',
        'date': Timestamp.fromDate(date),
      });
      return null; // success
    } catch (e) {
      return e.toString();
    }
  }

  static Stream<QuerySnapshot> getExpensesStream(String userId) {
    return _expensesCollection(userId).orderBy('date', descending: true).snapshots();
  }

  static Future<String?> deleteExpense(String userId, String expenseId) async {
    try {
      await _expensesCollection(userId).doc(expenseId).delete();
      return null; // success
    } catch (e) {
      return e.toString();
    }
  }
}
