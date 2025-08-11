import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class BillAnalyticsPage extends StatefulWidget {
  const BillAnalyticsPage({super.key});

  @override
  State<BillAnalyticsPage> createState() => _BillAnalyticsPageState();
}

class _BillAnalyticsPageState extends State<BillAnalyticsPage> {
  Map<String, double> categoryTotals = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBillData();
  }

  /// Loads bill data from Firestore for the current user.
  /// Filters bills with status 'Paid' or 'Overdue'.
  /// Calculates total amount per category.
  Future<void> _loadBillData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        setState(() {
          _errorMessage = "User not logged in.";
          _isLoading = false;
        });
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('bills')
          .where('status', whereIn: ['Paid', 'Overdue'])
          .get();

      Map<String, double> totals = {};

      for (var doc in snapshot.docs) {
        String category = doc['category'];
        double amount = (doc['amount'] as num).toDouble();

        totals[category] = (totals[category] ?? 0) + amount;
      }

      setState(() {
        categoryTotals = totals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load bill data: $e";
        _isLoading = false;
      });
    }
  }

  /// Builds the pie chart sections based on category totals.
  List<PieChartSectionData> _buildPieSections() {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.orange,
      Colors.purple,
      Colors.cyan,
      Colors.amber,
      Colors.teal,
      Colors.indigo,
      Colors.lime,
    ];

    int colorIndex = 0;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDarkMode ? Colors.white : Colors.black;

    return categoryTotals.entries.map((entry) {
      final pieColor = colors[colorIndex % colors.length];
      colorIndex++;

      return PieChartSectionData(
        value: entry.value,
        title: '${entry.key}\n₹${entry.value.toStringAsFixed(0)}',
        color: pieColor,
        radius: 80,
        titleStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: titleColor,
        ),
      );
    }).toList();
  }

  /// Calculates the total amount of all categories combined.
  double get totalAmount =>
      categoryTotals.values.fold(0, (previous, current) => previous + current);

  /// Calculates the average amount per category.
  double get averageAmount =>
      categoryTotals.isEmpty ? 0 : totalAmount / categoryTotals.length;

  /// Builds a legend widget showing category colors and amounts.
  Widget _buildLegend() {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.orange,
      Colors.purple,
      Colors.cyan,
      Colors.amber,
      Colors.teal,
      Colors.indigo,
      Colors.lime,
    ];

    int colorIndex = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categoryTotals.entries.map((entry) {
        final color = colors[colorIndex % colors.length];
        colorIndex++;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${entry.key}: ₹${entry.value.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bill Analytics")),
      body: Builder(
        builder: (context) {
          final mediaQuery = MediaQuery.of(context);
          final padding = mediaQuery.padding;

          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_errorMessage != null) {
            return Center(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, padding.bottom + 16),
            child: categoryTotals.isEmpty
                ? const Center(child: Text("No bills data to show analytics."))
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Center(
                          child: Text(
                            'Total Spending: ₹${totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: Text(
                            'Average Spending per Category: ₹${averageAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 300,
                          child: PieChart(
                            PieChartData(
                              sections: _buildPieSections(),
                              centerSpaceRadius: 40,
                              sectionsSpace: 5,
                              pieTouchData: PieTouchData(
                                touchCallback: (event, response) {
                                  if (response != null &&
                                      response.touchedSection != null) {
                                    final index =
                                        response.touchedSection!.touchedSectionIndex;
                                    final category = categoryTotals.keys.elementAt(index);
                                    final amount = categoryTotals[category];
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            '$category: ₹${amount?.toStringAsFixed(2)}'),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Spending Summary by Category",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        _buildLegend(),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }
}
