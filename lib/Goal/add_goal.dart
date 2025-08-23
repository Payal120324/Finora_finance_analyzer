import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'SavingGoal.dart';
import 'SavingGoalService.dart';
import 'goal_success_dialog.dart';

class AddGoalScreen extends StatefulWidget {
  final String userId;
  const AddGoalScreen({super.key, required this.userId});

  @override
  // ignore: library_private_types_in_public_api
  _AddGoalScreenState createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _targetDate;

  List<SavingGoal> _goals = [];
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fetchGoals();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _fetchGoals() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final goals = await SavingGoalService().fetchGoals(widget.userId, completed: false);
     // print('Fetched ${goals.length} active goals');
      setState(() {
        _goals = goals;
        _isLoading = false;
      });
      _animationController.forward(from: 0);
    } catch (e) {
      //print('Error fetching goals: $e');
      setState(() {
        _isLoading = false;
      });
      if(mounted){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load goals: $e')),
      );
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _targetDate = picked;
      });
    }
  }

  Future<void> _saveGoal() async {
    if (_titleController.text.isEmpty ||
        _amountController.text.isEmpty ||
        _targetDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All fields are required.')),
      );
      return;
    }

    final goal = SavingGoal(
      id: '',
      title: _titleController.text.trim(),
      amount: double.parse(_amountController.text),
      savedSoFar: 0,
      targetDate: _targetDate!,
    );

    await SavingGoalService().addGoal(widget.userId, goal);
    _titleController.clear();
    _amountController.clear();
    setState(() {
      _targetDate = null;
    });
    await _fetchGoals();
  }

  Future<bool?> _confirmDelete() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Goal'),
        content: Text('Are you sure you want to delete this goal?'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();
    final theme = Theme.of(context);
    // final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isLight = theme.brightness == Brightness.light;
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final height = mediaQuery.size.height;
    final paddingTop = mediaQuery.padding.top;
    final isLargeScreen = width > 600;
    final horizontalPadding = isLargeScreen ? width * 0.05 : width * 0.04;
    final verticalPadding = isLargeScreen ? height * 0.03 : height * 0.02;
    final availableHeight = height - paddingTop - kToolbarHeight;

    return Scaffold(
      appBar: AppBar(
        title: Text('Add Saving Goal', style: textTheme.titleLarge),
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
        child: Padding(
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
                        borderRadius: BorderRadius.circular(width * 0.06),
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
                            TextField(
                              controller: _titleController,
                              decoration: InputDecoration(
                                labelText: "Goal Title",
                                labelStyle: textTheme.bodySmall?.copyWith(color: Colors.deepPurpleAccent),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(width * 0.045),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(width * 0.045),
                                  borderSide: BorderSide(color: Colors.deepPurpleAccent, width: 3),
                                ),
                                prefixIcon: Icon(Icons.flag, color: Colors.deepPurpleAccent),
                              ),
                              style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: verticalPadding),
                            TextField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: "Target Amount (₹)",
                                labelStyle: textTheme.bodySmall?.copyWith(color: Colors.deepPurpleAccent),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(width * 0.045),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(width * 0.045),
                                  borderSide: BorderSide(color: Colors.deepPurpleAccent, width: 3),
                                ),
                                prefixIcon: Icon(Icons.attach_money, color: Colors.deepPurpleAccent),
                              ),
                              style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: verticalPadding),
                            InkWell(
                              onTap: _pickDate,
                              borderRadius: BorderRadius.circular(width * 0.045),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Target Date',
                                  labelStyle: textTheme.bodySmall?.copyWith(color: Colors.deepPurpleAccent),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(width * 0.045),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(width * 0.045),
                                    borderSide: BorderSide(color: Colors.deepPurpleAccent, width: 3),
                                  ),
                                  prefixIcon: Icon(Icons.calendar_today, color: Colors.deepPurpleAccent),
                                ),
                                child: Text(
                                  _targetDate == null ? 'Pick Target Date' : dateFormat.format(_targetDate!),
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: _targetDate == null ? theme.colorScheme.onSurfaceVariant : Colors.deepPurpleAccent.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: verticalPadding),
                            ElevatedButton(
                              onPressed: _saveGoal,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurpleAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(width * 0.045)),
                                padding: EdgeInsets.symmetric(horizontal: width * 0.1, vertical: height * 0.02),
                                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                elevation: 8,
                                shadowColor: Colors.deepPurpleAccent.withValues(alpha: 0.7),
                              ),
                              child: const Text('Save Goal'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Divider(
                      thickness: 2,
                      color: Colors.deepPurpleAccent,
                      height: height * 0.04,
                    ),
SizedBox(
  height: isLargeScreen ? height * 0.6 : height * 0.5,
  child: Card(
                        elevation: 12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(width * 0.06),
                          side: BorderSide(
                            color: theme.brightness == Brightness.dark ? Colors.grey : Colors.black,
                            width: 1.5,
                          ),
                        ),
                        shadowColor: Colors.deepPurpleAccent.withValues(alpha: 0.3),
                        child: Padding(
                          padding: EdgeInsets.all(width * 0.045),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Saving Goals',
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurpleAccent,
                                ),
                              ),
                              SizedBox(height: height * 0.02),
                              Expanded(
                                child: _isLoading
                                    ? Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent))
                                    : _goals.isEmpty
                                        ? Center(
                                            child: Text(
                                              'No saving goals yet.',
                                              style: textTheme.bodyLarge?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.deepPurpleAccent,
                                              ),
                                            ),
                                          )
                                        : FadeTransition(
                                            opacity: _fadeAnimation,
                                            child: ListView.separated(
                                              itemCount: _goals.length,
                                              separatorBuilder: (context, index) => Divider(color: Colors.deepPurpleAccent.withValues(alpha: 0.3), thickness: 1),
                                              itemBuilder: (context, index) {
                                                final goal = _goals[index];
final totalMonthsCalc = (goal.targetDate.year - DateTime.now().year) * 12 + (goal.targetDate.month - DateTime.now().month);
// final remaining = goal.amount - goal.savedSoFar;
// final progress = (goal.amount > 0) ? (goal.savedSoFar / goal.amount) : 0.0;
// final savedMonthly = goal.savedSoFar / (DateTime.now().difference(goal.targetDate.subtract(Duration(days: totalMonthsCalc * 30))).inDays / 30).clamp(1, double.infinity);
final dateFormat = DateFormat.yMMMd();
final perMonth = (goal.amount == goal.savedSoFar) ? 0 : (totalMonthsCalc > 0 ? (goal.amount / totalMonthsCalc) : goal.amount);
return Card(
  margin: EdgeInsets.symmetric(vertical: height * 0.015, horizontal: width * 0.02),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(width * 0.06),
    side: BorderSide(
      color: theme.brightness == Brightness.dark ? Colors.grey : Colors.black,
      width: 1.5,
    ),
  ),
  elevation: 10,
  shadowColor: Colors.deepPurpleAccent.withValues(alpha: 0.4),
  child: Padding(
    padding: EdgeInsets.all(width * 0.045),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
Text(goal.title, style: textTheme.titleMedium?.copyWith(color: Colors.deepPurpleAccent, fontWeight: FontWeight.w700)),
        SizedBox(height: height * 0.01),
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text("Target: ₹${goal.amount.toStringAsFixed(2)}", style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
    SizedBox(height: 4),
    Text("Saved: ₹${goal.savedSoFar.toStringAsFixed(2)}", style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
  ],
),
        SizedBox(height: height * 0.01),
        Text("Target Date: ${dateFormat.format(goal.targetDate)}", style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        SizedBox(height: height * 0.01),
Text("Monthly Needed: ₹${perMonth.toStringAsFixed(2)}", style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
SizedBox(height: height * 0.01),
Text("Saved Monthly: ₹${(goal.savedSoFar / (DateTime.now().difference(goal.targetDate.subtract(Duration(days: totalMonthsCalc * 30))).inDays / 30).clamp(1, double.infinity)).toStringAsFixed(2)}", style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.green)),
        SizedBox(height: height * 0.015),
        ClipRRect(
          borderRadius: BorderRadius.circular(width * 0.03),
          child: LinearProgressIndicator(
            value: (goal.amount > 0) ? (goal.savedSoFar / goal.amount) : 0.0,
            minHeight: height * 0.02,
            backgroundColor: Colors.deepPurpleAccent.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurpleAccent),
          ),
        ),
        SizedBox(height: height * 0.015),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: Icon(Icons.check_circle, color: Colors.green.shade700, size: width * 0.08),
              tooltip: 'Mark as Complete',
              onPressed: () async {
                await SavingGoalService().updateGoalCompleted(widget.userId, goal.id, true);
                await showDialog(
                  // ignore: use_build_context_synchronously
                  context: context,
                  builder: (context) => const SuccessDialog(),
                );
                await Future.delayed(Duration(milliseconds: 500));
                await _fetchGoals();
              },
            ),
            SizedBox(width: width * 0.03),
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue.shade700, size: width * 0.08),
              tooltip: 'Update Saved Amount',
              onPressed: () async {
                final TextEditingController updateController = TextEditingController(text: goal.savedSoFar.toStringAsFixed(2));
                final updated = await showDialog<double>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Update Saved Amount'),
                    content: TextField(
                      controller: updateController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Saved Amount',
                        prefixText: '₹',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(null),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          final value = double.tryParse(updateController.text);
                          if (value != null) {
                            Navigator.of(context).pop(value);
                          }
                        },
                        child: Text('Update'),
                      ),
                    ],
                  ),
                );
if (updated != null) {
  final newSavedAmount = goal.savedSoFar + updated;
  await SavingGoalService().updateSavedAmount(widget.userId, goal.id, newSavedAmount);
  await _fetchGoals();
  setState(() {});
}
              },
            ),
            SizedBox(width: width * 0.03),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red.shade700, size: width * 0.08),
              tooltip: 'Delete Goal',
              onPressed: () async {
                final confirmed = await _confirmDelete();
                if (confirmed == true) {
                  await SavingGoalService().deleteGoal(widget.userId, goal.id);
                  await _fetchGoals();
                }
              },
            ),
          ],
        ),
      ],
    ),
  ),
);
                                              },
                                            ),
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
        ),
      ),
    );
  }
}
