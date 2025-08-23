import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'success_dialog.dart';

class BillReminderPage extends StatefulWidget {
  const BillReminderPage({super.key});

  @override
  State<BillReminderPage> createState() => _BillReminderPageState();
}

class _BillReminderPageState extends State<BillReminderPage> with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _selectedDueDate;
  String? _selectedCategory;
  String? _selectedRepeatCycle;
  Key _streamKey = UniqueKey();

  final List<String> _categories = [
    'Electricity', 'WiFi', 'Rent', 'Water', 'Streaming', 'Gas', 'Phone', 'Credit Card', 'Insurance', 'Maintenance'
  ];

  final List<String> _repeatOptions = [
    'None', 'Monthly', 'Yearly'
  ];

  late AnimationController _animationController;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _checkOverdueBills();
    _notifyBillsDueTomorrow();

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
    _nameController.dispose();
    _amountController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _notifyBillsDueTomorrow() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfThreeDaysLater = startOfToday.add(const Duration(days: 3));

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('bills')
        .where('status', isEqualTo: 'Pending')
        .where('due_date', isGreaterThanOrEqualTo: startOfToday)
        .where('due_date', isLessThanOrEqualTo: startOfThreeDaysLater)
        .get();

    for (var doc in snapshot.docs) {
      final bill = doc.data();
      // final billName = bill['name'] ?? 'Bill';
      final amount = (bill['amount'] as num?)?.toDouble() ?? 0.0;
      final category = bill['category'] ?? '';

      String categoryMessage = "Your $category bill";
      if (category == "Electricity") categoryMessage = "Don't let lights go out! Electricity bill";
      if (category == "WiFi") categoryMessage = "Stay connected! WiFi bill";
      if (category == "Rent") categoryMessage = "Home sweet home! Rent bill";

      final dueDate = (bill['due_date'] as Timestamp).toDate();
      final nowDate = DateTime(now.year, now.month, now.day);
      final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
      final daysLeft = dueDateOnly.difference(nowDate).inDays;

      String title = '';
      String body = '';

      if (daysLeft == 0) {
        title = '⏰ Due Date Today!';
        body = 'Reminder: $categoryMessage of ₹${amount.toStringAsFixed(2)} is due today.';
      } else if (daysLeft == 1) {
        title = '⚡ Bill Due Tomorrow!';
        body = '$categoryMessage of ₹${amount.toStringAsFixed(2)} is due tomorrow!';
      } else if (daysLeft == 2 || daysLeft == 3) {
        title = '🧾 Bill Due Soon!';
        body = '$categoryMessage of ₹${amount.toStringAsFixed(2)} is due in $daysLeft days!';
      } else {
        continue; // skip if not in the range
      }

      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: doc.id.hashCode + 1000,
          channelKey: 'bill_reminders',
          title: title,
          body: body,
        ),
      );
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDueDate = picked);
    }
  }

  Future<void> _addBill() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || _selectedDueDate == null) return;

    final billName = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());

    if (billName.isEmpty || amount == null || _selectedCategory == null || _selectedRepeatCycle == null) return;

    final billRef = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('bills')
        .add({
      'name': billName,
      'amount': amount,
      'due_date': _selectedDueDate,
      'status': 'Pending',
      'category': _selectedCategory,
      'repeat_cycle': _selectedRepeatCycle,
      'created_at': FieldValue.serverTimestamp(),
    });

    _scheduleMultiReminders(
      billRef.id,
      billName,
      amount,
      _selectedDueDate!,
      _selectedCategory!,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bill added and reminders scheduled!')),
      );
    }

    _nameController.clear();
    _amountController.clear();
    setState(() {
      _selectedDueDate = null;
      _selectedCategory = null;
      _selectedRepeatCycle = null;
      _streamKey = UniqueKey();
    });
  }

  Future<void> _scheduleMultiReminders(
    String billId,
    String name,
    double amount,
    DateTime dueDate,
    String category,
  ) async {
    final threeDaysBefore = dueDate.subtract(const Duration(days: 3));
    final oneDayBefore = dueDate.subtract(const Duration(days: 1));

    String categoryMessage = "Your $category bill";
    if (category == "Electricity") categoryMessage = "Don't let lights go out! Electricity bill";
    if (category == "WiFi") categoryMessage = "Stay connected! WiFi bill";
    if (category == "Rent") categoryMessage = "Home sweet home! Rent bill";

    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: billId.hashCode,
        channelKey: 'bill_reminders',
        title: '🧾 Bill Due Soon!',
        body: '$categoryMessage of ₹${amount.toStringAsFixed(2)} is due in 3 days!',
      ),
      schedule: NotificationCalendar.fromDate(date: threeDaysBefore),
    );

    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: billId.hashCode + 1,
        channelKey: 'bill_reminders',
        title: '⚡ Bill Due Tomorrow!',
        body: '$categoryMessage of ₹${amount.toStringAsFixed(2)} is due tomorrow!',
      ),
      schedule: NotificationCalendar.fromDate(date: oneDayBefore),
    );

    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: billId.hashCode + 2,
        channelKey: 'bill_reminders',
        title: '⏰ Due Date Today!',
        body: 'Reminder: $categoryMessage of ₹${amount.toStringAsFixed(2)} is due Today.',
      ),
      schedule: NotificationCalendar.fromDate(date: dueDate),
    );
  }

  Future<void> _markBillAsPaid(String billId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final billDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('bills')
        .doc(billId)
        .get();

    if (!billDoc.exists) return;

    final billData = billDoc.data()!;

    await billDoc.reference.update({'status': 'Paid'});

    AwesomeNotifications().cancel(billId.hashCode);
    AwesomeNotifications().cancel(billId.hashCode + 1);
    AwesomeNotifications().cancel(billId.hashCode + 2);

    if (billData['repeat_cycle'] != 'None') {
      DateTime currentDueDate = (billData['due_date'] as Timestamp).toDate();
      DateTime nextDueDate;

      if (billData['repeat_cycle'] == 'Monthly') {
        nextDueDate = DateTime(currentDueDate.year, currentDueDate.month + 1, currentDueDate.day);
      } else if (billData['repeat_cycle'] == 'Yearly') {
        nextDueDate = DateTime(currentDueDate.year + 1, currentDueDate.month, currentDueDate.day);
      } else {
        return;
      }

      final newBillRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('bills')
          .add({
        'name': billData['name'],
        'amount': billData['amount'],
        'due_date': nextDueDate,
        'status': 'Pending',
        'category': billData['category'],
        'repeat_cycle': billData['repeat_cycle'],
        'created_at': FieldValue.serverTimestamp(),
      });

      _scheduleMultiReminders(
        newBillRef.id,
        billData['name'],
        (billData['amount'] as num).toDouble(),
        nextDueDate,
        billData['category'],
      );
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => const SuccessDialog(),
      );
    }
  }

  Future<void> _deleteBill(String billId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('bills')
        .doc(billId)
        .delete();

    AwesomeNotifications().cancel(billId.hashCode);
    AwesomeNotifications().cancel(billId.hashCode + 1);
    AwesomeNotifications().cancel(billId.hashCode + 2);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bill deleted.')),
      );
    }
  }

  Future<void> _checkOverdueBills() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final now = DateTime.now();

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('bills')
        .where('status', isEqualTo: 'Pending')
        .get();

    for (var doc in snapshot.docs) {
      DateTime dueDate = (doc['due_date'] as Timestamp).toDate();
      if (now.isAfter(dueDate)) {
        await doc.reference.update({'status': 'Overdue'});
      }
    }
  }

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
      case 'Gas':
        return Icons.local_gas_station;
      case 'Phone':
        return Icons.phone;
      case 'Credit Card':
        return Icons.credit_card;
      case 'Insurance':
        return Icons.shield;
      case 'Maintenance':
        return Icons.build;
      default:
        return Icons.receipt_long;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Electricity':
        return Colors.orange;
      case 'WiFi':
        return Colors.blue;
      case 'Rent':
        return Colors.green;
      case 'Water':
        return Colors.cyan;
      case 'Streaming':
        return Colors.purple;
      case 'Gas':
        return Colors.redAccent;
      case 'Phone':
        return Colors.teal;
      case 'Credit Card':
        return Colors.indigo;
      case 'Insurance':
        return Colors.amber;
      case 'Garbage':
        return Colors.brown;
      case 'Maintenance':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatDueDate(dynamic dueDate) {
    if (dueDate == null) return "Unknown";
    DateTime date;
    if (dueDate is DateTime) {
      date = dueDate;
    } else if (dueDate is Timestamp) {
      date = dueDate.toDate();
    } else {
      return "Unknown";
    }
    return "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return "0.00";
    if (amount is num) {
      return amount.toStringAsFixed(2);
    }
    try {
      return double.parse(amount.toString()).toStringAsFixed(2);
    } catch (_) {
      return "0.00";
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final mediaQuery = MediaQuery.of(context);
    // final padding = mediaQuery.padding;
    // final screenWidth = mediaQuery.size.width;


    return Scaffold(
      appBar: AppBar(
        title: const Text("Bill Payment Reminders"),
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
                    Color(0xFFE6E6FA),
                    Color(0xFFFFF8E1),
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
            final horizontalPaddingInner = isLargeScreen ? 32.0 : 20.0;
            final verticalPaddingInner = isLargeScreen ? 24.0 : 16.0;
            final availableHeight = mediaQuery.size.height - mediaQuery.padding.top - kToolbarHeight;
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPaddingInner, vertical: verticalPaddingInner),
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
                          margin: EdgeInsets.only(bottom: verticalPaddingInner),
                          shadowColor: Colors.deepPurpleAccent.withValues(alpha: 0.3),
                          child: Padding(
                            padding: EdgeInsets.all(verticalPaddingInner),
                            child: Column(
                              children: [
                                Text(
                                  "Add a New Bill",
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: verticalPaddingInner),
                                TextField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: "Bill Name",
                                    labelStyle: theme.textTheme.bodySmall?.copyWith(color: Colors.deepPurpleAccent),
                                    prefixIcon: const Icon(Icons.receipt_long, color: Colors.deepPurpleAccent),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 3),
                                    ),
                                    filled: true,
                                    fillColor: isLight ? Colors.white : Colors.grey.shade800,
                                  ),
                                ),
                                SizedBox(height: verticalPaddingInner),
                                TextField(
                                  controller: _amountController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: "Amount",
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
                                    filled: true,
                                    fillColor: isLight ? Colors.white : Colors.grey.shade800,
                                  ),
                                ),
                                SizedBox(height: verticalPaddingInner),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                        decoration: BoxDecoration(
                                          color: isLight ? Colors.white : Colors.grey.shade800,
                                          borderRadius: BorderRadius.circular(18),
                                          border: Border.all(color: Colors.deepPurpleAccent),
                                        ),
                                        child: Text(
                                          _selectedDueDate == null
                                              ? "No Due Date Chosen"
                                              : "Due: ${_selectedDueDate!.toLocal().toString().split(' ')[0]}",
                                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.deepPurpleAccent),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: verticalPaddingInner),
                                    ElevatedButton(
                                      onPressed: _pickDueDate,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.deepPurpleAccent,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        elevation: 8,
                                        shadowColor: Colors.deepPurpleAccent.withValues(alpha: 0.7),
                                      ),
                                      child: const Text("Pick Due Date"),
                                    ),
                                  ],
                                ),
                                SizedBox(height: verticalPaddingInner),
                                DropdownButtonFormField<String>(
                                  value: _selectedCategory,
                                  hint: const Text('Select Category'),
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.category, color: Colors.deepPurpleAccent),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 3),
                                    ),
                                    filled: true,
                                    fillColor: isLight ? Colors.white : Colors.grey.shade800,
                                  ),
                                  items: _categories.map((cat) {
                                    return DropdownMenuItem(
                                      value: cat,
                                      child: Row(
                                        children: [
                                          Icon(_getCategoryIcon(cat), color: Colors.deepPurpleAccent),
                                          const SizedBox(width: 16),
                                          Text(
                                            cat,
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: Colors.deepPurpleAccent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() => _selectedCategory = val);
                                  },
                                ),
                                SizedBox(height: verticalPaddingInner),
                                DropdownButtonFormField<String>(
                                  value: _selectedRepeatCycle,
                                  hint: const Text('Repeat?'),
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.repeat, color: Colors.deepPurpleAccent),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 3),
                                    ),
                                    filled: true,
                                    fillColor: isLight ? Colors.white : Colors.grey.shade800,
                                  ),
                                  items: _repeatOptions.map((repeat) {
                                    return DropdownMenuItem(
                                      value: repeat,
                                      child: Text(
                                        repeat,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: Colors.deepPurpleAccent,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() => _selectedRepeatCycle = val);
                                  },
                                ),
                                SizedBox(height: verticalPaddingInner),
                                SizedBox(
                                  width: double.infinity,
                                  child: ScaleTransition(
                                    scale: _buttonScaleAnimation,
                                    child: ElevatedButton.icon(
                                      onPressed: _addBill,
                                      icon: const Icon(Icons.save),
                                      label: const Text("Add Bill"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.deepPurpleAccent,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        elevation: 8,
                                        shadowColor: Colors.deepPurpleAccent.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ),
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
                          height: mediaQuery.size.height * 0.4,
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
                                    "Upcoming Bills",
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurpleAccent,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: StreamBuilder<QuerySnapshot>(
                                      key: _streamKey,
                                      stream: FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(userId)
                                          .collection('bills')
                                          .where('status', whereIn: ['Pending'])
                                          .orderBy('due_date')
                                          .limit(30)
                                          .snapshots(),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasError) {
                                          return Center(child: Text('Error: \${snapshot.error}'));
                                        }
                                        if (!snapshot.hasData) {
                                          return const Center(child: CircularProgressIndicator());
                                        }

                                        final bills = snapshot.data!.docs;

                                        if (bills.isEmpty) {
                                          return Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.inbox, size: 72, color: Colors.deepPurpleAccent.shade100),
                                                const SizedBox(height: 16),
                                                Text(
                                                  "No upcoming bills.",
                                                  style: theme.textTheme.bodyLarge?.copyWith(color: Colors.deepPurpleAccent.shade200),
                                                ),
                                              ],
                                            ),
                                          );
                                        }

                                        return ListView.builder(
                                          itemCount: bills.length,
                                          itemBuilder: (context, index) {
                                            final bill = bills[index];

                                            return Dismissible(
                                              key: Key(bill.id),
                                              background: Container(color: Colors.red),
                                              onDismissed: (_) => _deleteBill(bill.id),
                                              child: Card(
                                                elevation: 10,
                                                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(24),
                                                ),
                                                shadowColor: Colors.deepPurpleAccent.withValues(alpha: 0.4),
                                                child: ListTile(
                                                  leading: CircleAvatar(
                                                    backgroundColor: _getCategoryColor(bill['category']).withValues(alpha: 0.4),
                                                    child: Icon(
                                                      _getCategoryIcon(bill['category']),
                                                      color: _getCategoryColor(bill['category']),
                                                    ),
                                                  ),
                                                  title: Text(
                                                    bill['name'],
                                                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                                                  ),
                                                  subtitle: Text(
                                                    "Amount: ₹${bill['amount'] != null ? _formatAmount(bill['amount']) : '0.00'} | Due: ${bill['due_date'] != null ? _formatDueDate(bill['due_date']) : 'Unknown'}",
                                                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.deepPurpleAccent.shade200),
                                                  ),
                                                  trailing: ElevatedButton(
                                                    onPressed: () => _markBillAsPaid(bill.id),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.green,
                                                      foregroundColor: Colors.white,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(18),
                                                      ),
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                    ),
                                                    child: const Text("Mark Paid"),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
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
