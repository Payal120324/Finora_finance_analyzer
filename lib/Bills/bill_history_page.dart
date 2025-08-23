import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BillHistoryPage extends StatelessWidget {
  const BillHistoryPage({super.key});

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Electricity':
        return Icons.electric_bolt;
      case 'WiFi':
        return Icons.wifi;
      case 'Rent':
        return Icons.home;
      case 'Water':
        return Icons.water;
      case 'Streaming':
        return Icons.tv;
      default:
        return Icons.receipt_long;
    }
  }

  Future<void> _deleteBill(BuildContext context, String userId, String billId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('bills')
          .doc(billId)
          .delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill deleted successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete bill: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.black : null;

    return Scaffold(
      appBar: AppBar(title: const Text("Bill History")),
      body: Builder(
        builder: (builderContext) {
          final mediaQuery = MediaQuery.of(builderContext);
          final padding = mediaQuery.padding;
          return Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, padding.bottom + 16),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('bills')
                  .where('status', whereIn: ['Paid', 'Overdue'])
                  .orderBy('due_date', descending: true)
                  .limit(30)
                  .snapshots(),
              builder: (streamContext, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final bills = snapshot.data!.docs;

                if (bills.isEmpty) {
                  return const Center(child: Text("No bills history yet."));
                }

                return ListView.builder(
                  itemCount: bills.length,
                  itemBuilder: (context, index) {
                    final bill = bills[index];
                    final isOverdue = bill['status'] == "Overdue";

                    return Card(
                      color: isOverdue ? Colors.red[100] : Colors.green[100],
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: Icon(
                          _getCategoryIcon(bill['category']),
                          color: isOverdue ? Colors.red : Colors.green,
                        ),
                        title: Text(
                          bill['name'],
                          style: TextStyle(color: textColor),
                        ),
                        subtitle: Text(
                          '${bill['status']} on ${bill['due_date'].toDate().toString().split(' ')[0]} | ₹${bill['amount']}',
                          style: TextStyle(color: textColor),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            if (userId != null) {
                              _deleteBill(context, userId, bill.id);
                            }
                          },
                          tooltip: 'Delete Bill',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
