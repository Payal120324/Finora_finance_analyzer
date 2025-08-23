
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:fl_chart/fl_chart.dart';

class BudgetTrackerPage extends StatefulWidget {
  const BudgetTrackerPage({super.key});

  @override
  State<BudgetTrackerPage> createState() => _BudgetTrackerPageState();
}

class _BudgetTrackerPageState extends State<BudgetTrackerPage> with SingleTickerProviderStateMixin {
  final _budgetController = TextEditingController();
  bool _alertShown = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
  }

  Future<void> _requestNotificationPermission() async {
    if (!await AwesomeNotifications().isNotificationAllowed()) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  void _showBudgetAlert() {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: 'budget_alerts',
        title: '⚠️ Budget Limit Alert!',
        body: 'You’ve spent over 80% of your monthly budget.',
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  Future<void> _updateBudget() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final amount = double.tryParse(_budgetController.text);
    if (amount == null) return;

    String budgetKey = 'budget_${_selectedMonth.year}_${_selectedMonth.month.toString().padLeft(2, '0')}';

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({budgetKey: amount}, SetOptions(merge: true));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating budget: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _resetBudget() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return;
    }

    String budgetKey = 'budget_${_selectedMonth.year}_${_selectedMonth.month.toString().padLeft(2, '0')}';

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Budget'),
        content: Text(
          'Are you sure you want to reset the budget for ${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}?\n\n'
          'This will remove the budget limit for this month.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({budgetKey: FieldValue.delete()});

    setState(() {
      _budgetController.clear();
    });
if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Budget reset successfully')),
    );
}
  }

  Stream<QuerySnapshot> _getMonthlyExpenses(String userId) {
    final startOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final endOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1).subtract(const Duration(days: 1));

    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .where('date', isGreaterThanOrEqualTo: startOfMonth)
        .where('date', isLessThanOrEqualTo: endOfMonth)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in.")),
      );
    }

    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final mediaQuery = MediaQuery.of(context);
    final padding = mediaQuery.padding;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Budget Tracker"),
        elevation: 8,
        shadowColor: Colors.deepPurpleAccent.withAlpha((0.6 * 255).round()),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple, Colors.deepPurpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: isLight
            ? const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFE6E6FA), // Lavender
                    Color(0xFFFFF8E1), // Warm beige/light cream
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              )
            : null,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, padding.bottom + 16),
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
            builder: (context, budgetSnapshot) {
              if (budgetSnapshot.hasError) {
                return Text("Error loading budget: ${budgetSnapshot.error}", style: TextStyle(color: isLight ? Colors.black : Colors.white));
              }

              if (!budgetSnapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final userData = budgetSnapshot.data!.data() as Map<String, dynamic>? ?? {};
              String budgetKey = 'budget_${_selectedMonth.year}_${_selectedMonth.month.toString().padLeft(2, '0')}';
              final budget = (userData[budgetKey] ?? 0).toDouble();

              return StreamBuilder<QuerySnapshot>(
                stream: _getMonthlyExpenses(userId),
                builder: (context, expensesSnapshot) {
                  if (expensesSnapshot.hasError) {
                    return Text("Error loading expenses: ${expensesSnapshot.error}", style: TextStyle(color: isLight ? Colors.black : Colors.white));
                  }

                  if (!expensesSnapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final docs = expensesSnapshot.data!.docs;

                  double totalSpent = 0;
                  for (var doc in docs) {
                    totalSpent += (doc['amount'] as num).toDouble();
                  }

                  final percentUsed = (budget > 0) ? (totalSpent / budget) : 0;

                  if (!_alertShown && percentUsed >= 0.8) {
                    _alertShown = true;
                    _showBudgetAlert();
                  }

                  _animationController.forward(from: 0);

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          elevation: 12,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: BorderSide(
                              color: theme.brightness == Brightness.dark ? Colors.grey : Colors.black,
                              width: 1.5,
                            ),
                          ),
                          margin: EdgeInsets.only(bottom: 16),
                          shadowColor: Colors.deepPurpleAccent.withAlpha((0.3 * 255).round()),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "Set Monthly Budget",
                                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.brightness == Brightness.dark ? Colors.white : Colors.black),
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: theme.brightness == Brightness.dark ? Color(0xFF512DA8) : Color(0xFFD1C4E9),
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: theme.brightness == Brightness.dark ? Color(0xFF311B92) : Color(0xFF673AB7),
                                          width: 2,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      child: TextButton(
                                        onPressed: () async {
                                          final picked = await showDialog<DateTime>(
                                            context: context,
                                            builder: (context) {
                                              int selectedYear = _selectedMonth.year;
                                              int selectedMonth = _selectedMonth.month;
                                              return StatefulBuilder(
                                                builder: (context, setState) {
                                                  return AlertDialog(
                                                    title: const Text('Select Month and Year'),
                                                    content: Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        DropdownButton<int>(
                                                          value: selectedMonth,
                                                          items: List.generate(12, (index) => index + 1)
                                                              .map((month) => DropdownMenuItem(
                                                                    value: month,
                                                                    child: Text(month.toString().padLeft(2, '0')),
                                                                  ))
                                                              .toList(),
                                                          onChanged: (value) {
                                                            if (value != null) {
                                                              setState(() {
                                                                selectedMonth = value;
                                                              });
                                                            }
                                                          },
                                                        ),
                                                        const SizedBox(width: 16),
                                                        DropdownButton<int>(
                                                          value: selectedYear,
                                                          items: List.generate(10, (index) => DateTime.now().year - 5 + index)
                                                              .map((year) => DropdownMenuItem(
                                                                    value: year,
                                                                    child: Text(year.toString()),
                                                                  ))
                                                              .toList(),
                                                          onChanged: (value) {
                                                            if (value != null) {
                                                              setState(() {
                                                                selectedYear = value;
                                                              });
                                                            }
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.of(context).pop(),
                                                        child: const Text('Cancel'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () => Navigator.of(context).pop(DateTime(selectedYear, selectedMonth)),
                                                        child: const Text('OK'),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                          );
                                          if (picked != null) {
                                            setState(() {
                                              _selectedMonth = picked;
                                              _budgetController.text = '';
                                              _alertShown = false;
                                            });
                                          }
                                        },
                                        child: Text(
                                          "${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}",
                                          style: TextStyle(fontSize: 16, color: theme.brightness == Brightness.dark ? Colors.white : Colors.black87),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _budgetController,
                                        decoration: InputDecoration(
                                          prefixText: '₹ ',
                                          hintText: "e.g. 5000",
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(18),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                        ),
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    ElevatedButton(
                                      onPressed: _updateBudget,
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                        backgroundColor: Colors.deepPurpleAccent,
                                      ),
                                      child: const Text(
                                        "Save",
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,color: Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: _resetBudget,
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                      child: const Text(
                                        "Reset",
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,color: Colors.white),
                                      ),
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: isLight ? Colors.black : Colors.grey),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Total Spent this Month: ₹${totalSpent.toStringAsFixed(2)}",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isLight ? Colors.black : Colors.white),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Your Budget: ₹${budget.toStringAsFixed(2)}",
                                  style: TextStyle(fontSize: 16, color: isLight ? Colors.black54 : Colors.white70),
                                ),
                                const SizedBox(height: 20),
                                AnimatedBuilder(
                                  animation: _animation,
                                  builder: (context, child) {
                                    return LinearProgressIndicator(
                                      value: (_animation.value * percentUsed).clamp(0, 1).toDouble(),
                                      color: percentUsed >= 0.8 ? Colors.red : Colors.green,
                                      backgroundColor: Colors.grey[300],
                                      minHeight: 14,
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                if (percentUsed >= 0.8)
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.red[100],
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.red.withAlpha((0.4 * 255).round()),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.warning, color: Colors.red, size: 28),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            "Alert! You've spent over 80% of your budget.",
                                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 16),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                        const SizedBox(height: 20),
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: isLight ? Colors.black : Colors.grey),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Budget Usage",
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isLight ? Colors.black : Colors.white),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 200,
                                  child: PieChart(
                                    PieChartData(
                                      sectionsSpace: 4,
                                      centerSpaceRadius: 40,
                                      sections: [
                                        PieChartSectionData(
                                          color: Colors.green,
                                          value: (budget - totalSpent).clamp(0, budget).toDouble(),
                                          title: 'Remaining\n₹${(budget - totalSpent).clamp(0, budget).toStringAsFixed(2)}',
                                          radius: 60,
                                          titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                        PieChartSectionData(
                                          color: Colors.red,
                                          value: totalSpent.clamp(0, budget).toDouble(),
                                          title: 'Spent\n₹${totalSpent.clamp(0, budget).toStringAsFixed(2)}',
                                          radius: 60,
                                          titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                           ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  ),
),
      ),
    );
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
