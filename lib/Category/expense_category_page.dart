// ignore_for_file: unused_field, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'expense_service.dart';

class ExpenseCategoryPage extends StatefulWidget {
  const ExpenseCategoryPage({super.key});

  @override
  State<ExpenseCategoryPage> createState() => _ExpenseCategoryPageState();
}

class _ExpenseCategoryPageState extends State<ExpenseCategoryPage> with SingleTickerProviderStateMixin {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategory;

  late AnimationController _animationController;
  late Animation<double> _buttonScaleAnimation;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Food', 'icon': Icons.fastfood, 'color': Colors.redAccent},
    {'name': 'Transport', 'icon': Icons.directions_car, 'color': Colors.blueAccent},
    {'name': 'Shopping', 'icon': Icons.shopping_bag, 'color': Colors.pinkAccent},
    {'name': 'Entertainment', 'icon': Icons.movie, 'color': Colors.purpleAccent},
    {'name': 'Health', 'icon': Icons.health_and_safety, 'color': Colors.greenAccent},
    {'name': 'Education', 'icon': Icons.school, 'color': Colors.indigoAccent},
    {'name': 'Travel', 'icon': Icons.flight, 'color': Colors.tealAccent},
    {'name': 'Utilities', 'icon': Icons.lightbulb, 'color': Colors.amberAccent},
    {'name': 'Others', 'icon': Icons.more_horiz, 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.95,
      upperBound: 1.0,
    );
    _buttonScaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submitExpense() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in")),
        );
      }
      return;
    }
    final amount = double.tryParse(_amountController.text);
    if (_selectedCategory == null || amount == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Enter category and valid amount")),
        );
      }
      return;
    }

    final result = await ExpenseService.addExpense(
      userId: userId,
      category: _selectedCategory!,
      amount: amount,
      note: _noteController.text,
      date: _selectedDate,
    );

    if (mounted) {
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Expense added successfully")),
        );
        setState(() {
          _amountController.clear();
          _noteController.clear();
          _selectedCategory = null;
          _selectedDate = DateTime.now();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $result")),
        );
      }
    }
  }

  Widget _buildCategoryIcon(Map<String, dynamic> cat) {
    return Container(
      decoration: BoxDecoration(
        color: (cat['color'] as Color).withValues(alpha: 0.25),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (cat['color'] as Color).withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Icon(cat['icon'], color: cat['color'], size: 28),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        backgroundColor: Colors.purple,
        elevation: 8,
        shadowColor: Colors.purpleAccent.withValues(alpha: 0.6),
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isLargeScreen = width > 600;
            final horizontalPadding = isLargeScreen ? 32.0 : 20.0;
            final verticalPadding = isLargeScreen ? 24.0 : 16.0;
            final mediaQuery = MediaQuery.of(context);
            final availableHeight = mediaQuery.size.height - mediaQuery.padding.top - kToolbarHeight;
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: availableHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
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
                          margin: EdgeInsets.only(bottom: verticalPadding),
                          shadowColor: Colors.deepPurpleAccent.withValues(alpha: 0.3),
                          child: Padding(
                            padding: EdgeInsets.all(verticalPadding),
                            child: Column(
                              children: [
                                DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    labelText: 'Category',
                                    labelStyle: theme.textTheme.bodySmall?.copyWith(color: Colors.deepPurpleAccent),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 3),
                                    ),
                                  ),
                                  value: _selectedCategory,
                                  onChanged: (val) => setState(() => _selectedCategory = val),
                                  items: _categories
                                      .map<DropdownMenuItem<String>>((cat) => DropdownMenuItem<String>(
                                            value: cat['name'] as String,
                                            child: Row(
                                              children: [
                                                _buildCategoryIcon(cat),
                                                const SizedBox(width: 16),
                                                Text(
                                                  cat['name'],
                                                style: theme.textTheme.bodyMedium?.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                    color: Colors.deepPurpleAccent,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ))
                                      .toList(),
                                ),
                                SizedBox(height: verticalPadding),
                                TextField(
                                  controller: _amountController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Amount',
                                    labelStyle: theme.textTheme.bodySmall?.copyWith(color: Colors.deepPurpleAccent),
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.only(left: 12, right: 8),
                                      child: Text('₹',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.deepPurpleAccent,
                                          )),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 3),
                                    ),
                                  ),
                                ),
                                SizedBox(height: verticalPadding),
                                TextField(
                                  controller: _noteController,
                                  decoration: InputDecoration(
                                    labelText: 'Note (optional)',
                                    labelStyle: theme.textTheme.bodySmall?.copyWith(color: Colors.deepPurpleAccent),
                                    prefixIcon: const Icon(Icons.note, color: Colors.deepPurpleAccent),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 3),
                                    ),
                                  ),
                                ),
                                SizedBox(height: verticalPadding),
                                ElevatedButton(
                                  onPressed: _submitExpense,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurpleAccent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    elevation: 8,
                                    shadowColor: Colors.deepPurpleAccent.withValues(alpha: 0.7),
                                  ),
                                  child: const Text('Add Expense'),
                                ),
                                SizedBox(height: verticalPadding),
                                Row(
                                  children: [
                                    Text(
                                      'Date: ${DateFormat.yMMMd().format(_selectedDate)}',
                                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.deepPurpleAccent.shade700),
                                    ),
                                    const SizedBox(width: 16),
                                    ElevatedButton.icon(
                                      onPressed: _pickDate,
                                      icon: const Icon(Icons.calendar_today),
                                      label: const Text('Pick Date'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.deepPurpleAccent,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        elevation: 8,
                                        shadowColor: Colors.deepPurpleAccent.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(
                          thickness: 2,
                          color: Colors.deepPurpleAccent,
                          height: 32,
                        ),
                        SizedBox(
                          height: 300,
                          child: Card(
                            elevation: 12,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                              side: BorderSide(
                                color: theme.brightness == Brightness.dark ? Colors.grey : Colors.black,
                                width: 1.5,
                              ),
                            ),
                            shadowColor: Colors.deepPurpleAccent.withValues(alpha: 0.3),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Expenses',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurpleAccent,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: StreamBuilder(
                                      stream: () {
                                        final userId = FirebaseAuth.instance.currentUser?.uid;
                                        if (userId == null) {
                                          return const Stream.empty();
                                        }
                                        return ExpenseService.getExpensesStream(userId);
                                      }(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const Center(child: CircularProgressIndicator());
                                        }
                                        if (snapshot.hasError) {
                                          return Center(child: Text('Error: \${snapshot.error}'));
                                        }
                                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                          return Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.inbox, size: 72, color: Colors.deepPurpleAccent.shade100),
                                                const SizedBox(height: 16),
                                                Text(
                                                  'No expenses added yet.',
                                                  style: theme.textTheme.bodyLarge?.copyWith(color: Colors.deepPurpleAccent.shade200),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                        final expenses = snapshot.data!.docs;
                                        return ListView.builder(
                                          itemCount: expenses.length,
                                          itemBuilder: (context, index) {
                                            final expense = expenses[index];
                                            final data = expense.data() as Map<String, dynamic>;
                                            final category = data['category'] ?? '';
                                            final amount = (data['amount'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00';
                                            final note = data['note'] ?? '';
                                            final dateTimestamp = data['date'];
                                            String formattedDate = '';
                                            if (dateTimestamp is Timestamp) {
                                              final date = dateTimestamp.toDate();
                                              formattedDate = DateFormat.yMMMd().format(date);
                                            } else if (dateTimestamp is DateTime) {
                                              formattedDate = DateFormat.yMMMd().format(dateTimestamp);
                                            }
                                            final categoryData = _categories.firstWhere(
                                              (cat) => cat['name'] == category,
                                              orElse: () => {'icon': Icons.help, 'color': Colors.grey},
                                            );
                                            return Card(
                                              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(24),
                                              ),
                                              elevation: 10,
                                              shadowColor: Colors.deepPurpleAccent.withValues(alpha: 0.4),
                                              child: ListTile(
                                                leading: Container(
                                                  decoration: BoxDecoration(
                                                    color: (categoryData['color'] as Color).withValues(alpha: 0.4),
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: (categoryData['color'] as Color).withValues(alpha: 0.5),
                                                        blurRadius: 8,
                                                        offset: const Offset(0, 4),
                                                      ),
                                                    ],
                                                  ),
                                                  padding: const EdgeInsets.all(14),
                                                  child: Icon(
                                                    categoryData['icon'] as IconData,
                                                    color: categoryData['color'] as Color,
                                                    size: 32,
                                                  ),
                                                ),
                                                title: Text(
                                                  '₹$amount - $category',
                                                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                                                ),
                                                subtitle: Padding(
                                                  padding: const EdgeInsets.only(top: 8),
                                                  child: Text(
                                                    '$note\nDate: $formattedDate',
                                                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.deepPurpleAccent.shade200),
                                                  ),
                                                ),
                                                isThreeLine: true,
                                                trailing: IconButton(
                                                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                                                  onPressed: () async {
                                                    final userId = FirebaseAuth.instance.currentUser?.uid;
                                                    if (userId == null) {
                                                      if (mounted) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          const SnackBar(content: Text("User not logged in")),
                                                        );
                                                      }
                                                      return;
                                                    }
                                                    final confirm = await showDialog<bool>(
                                                      context: context,
                                                      builder: (dialogContext) => AlertDialog(
                                                        title: const Text('Confirm Delete'),
                                                        content: const Text('Are you sure you want to delete this expense?'),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () => Navigator.of(dialogContext).pop(false),
                                                            child: const Text('Cancel'),
                                                          ),
                                                          TextButton(
                                                            onPressed: () => Navigator.of(dialogContext).pop(true),
                                                            child: const Text('Delete'),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                    if (confirm == true && mounted) {
                                                      final error = await ExpenseService.deleteExpense(userId, expense.id);
                                                      if (mounted) {
                                                        if (error != null) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(content: Text('Error deleting expense: $error')),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(content: Text('Expense deleted successfully')),
                                                          );
                                                        }
                                                      }
                                                    }
                                                  },
                                                ),
                                              ),
                                            );
                                          },
                                          shrinkWrap: true,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],

                  ),
                ),
              ),
            ),
          );
        },
      ),
      ),
    );
    
  }
}
