import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

enum AnalyticsType { category, daily, monthly }
class _AnalyticsPageState extends State<AnalyticsPage> {
  AnalyticsType _selectedAnalytics = AnalyticsType.category;

  Map<String, double> categoryTotals = {};
  Map<String, double> dailyTotals = {};
  Map<String, double> monthlyTotals = {};

  List<Map<String, dynamic>> allExpenses = [];

  DateTime? _selectedDate;
  DateTime? _selectedMonth;

  // ignore: unused_field
  bool _isLoading = true;
  // ignore: unused_field
  String? _errorMessage;

  final List<Color> colors = [
    Colors.greenAccent,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.cyan,
    Colors.indigo,
    Colors.teal,
    Colors.pink,
    Colors.yellow,
  ];

  @override
  void initState() {
    super.initState();
    fetchAllAnalyticsData();
  }

  Map<String, double> getCategoryTotalsForSelectedDate() {
    if (_selectedDate == null) return {};

    final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final Map<String, double> categoryTotalsForDate = {};

    for (var expense in allExpenses) {
      final expenseDate = expense['date'] as DateTime;
      final expenseDateStr = DateFormat('yyyy-MM-dd').format(expenseDate);
      if (expenseDateStr == selectedDateStr) {
        final category = expense['category'] as String;
        final amount = expense['amount'] as double;
        categoryTotalsForDate[category] = (categoryTotalsForDate[category] ?? 0) + amount;
      }
    }

    return categoryTotalsForDate;
  }

  Future<void> fetchAllAnalyticsData() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User not authenticated';
        });
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('expenses')
          .get();

      final data = snapshot.docs;

      if (data.isEmpty) {
        setState(() {
          _isLoading = false;
          categoryTotals = {};
          dailyTotals = {};
          monthlyTotals = {};
          allExpenses = [];
        });
        return;
      }

      final Map<String, double> catTotals = {};
      final Map<String, double> dayTotals = {};
      final Map<String, double> monthTotals = {};

      final List<Map<String, dynamic>> expenses = [];

      for (var doc in data) {
        try {
          final category = doc['category'] ?? 'Uncategorized';
          final amount = (doc['amount'] as num?)?.toDouble() ?? 0.0;

          // Skip invalid entries
          if (amount <= 0) continue;

          // Aggregate category totals
          catTotals[category] = (catTotals[category] ?? 0) + amount;

          // Aggregate daily totals
          final dateTimestamp = doc['date'];
          DateTime date;
          if (dateTimestamp is Timestamp) {
            date = dateTimestamp.toDate();
          } else if (dateTimestamp is DateTime) {
            date = dateTimestamp;
          } else {
            continue; // skip if date invalid
          }
          final dayKey = DateFormat('yyyy-MM-dd').format(date);
          dayTotals[dayKey] = (dayTotals[dayKey] ?? 0) + amount;

          // Aggregate monthly totals
          final monthKey = DateFormat('yyyy-MM').format(date);
          monthTotals[monthKey] = (monthTotals[monthKey] ?? 0) + amount;

          expenses.add({
            'category': category,
            'amount': amount,
            'date': date,
          });
        } catch (e) {
          // Skip problematic documents but continue processing others
          debugPrint('Error processing document ${doc.id}: $e');
          continue;
        }
      }

      setState(() {
        _isLoading = false;
        categoryTotals = catTotals;
        dailyTotals = dayTotals;
        monthlyTotals = monthTotals;
        allExpenses = expenses;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load analytics data: ${e.toString()}';
      });
    }
  }

  List<PieChartSectionData> getPieSections() {
    int index = 0;
    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedEntries.map((entry) {
      final color = colors[index % colors.length];
      index++;
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '',
        radius: 70,
      );
    }).toList();
  }

  List<PieChartSectionData> getPieSectionsFromMap(Map<String, double> dataMap) {
    int index = 0;
    final sortedEntries = dataMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedEntries.map((entry) {
      final color = colors[index % colors.length];
      index++;
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '',
        radius: 70,
      );
    }).toList();
  }

  List<BarChartGroupData> getBarGroups(Map<String, double> dataMap) {
    int index = 0;
    final sortedEntries = dataMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedEntries.map((entry) {
      final color = colors[index % colors.length];
      final barGroup = BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: color,
            width: 14,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
      index++;
      return barGroup;
    }).toList();
  }

  Widget buildLegend(Map<String, double> dataMap) {
    final sortedEntries = dataMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    List<Widget> rows = [];
    for (int i = 0; i < sortedEntries.length; i += 2) {
      final color1 = colors[i % colors.length];
      final entry1 = sortedEntries[i];
      Widget first = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            color: color1,
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.light ? Colors.grey[300] : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('${entry1.key} (${entry1.value.toStringAsFixed(0)})'),
          ),
        ],
      );

      Widget second = const SizedBox.shrink();
      if (i + 1 < sortedEntries.length) {
        final color2 = colors[(i + 1) % colors.length];
        final entry2 = sortedEntries[i + 1];
        second = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              color: color2,
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.light ? Colors.grey[300] : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('${entry2.key} (${entry2.value.toStringAsFixed(0)})'),
            ),
          ],
        );
      }

      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            first,
            const SizedBox(width: 20),
            second,
          ],
        ),
      ));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget analyticsContent;
    String title;

    switch (_selectedAnalytics) {
      case AnalyticsType.daily:
        analyticsContent = SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).brightness == Brightness.light ? Colors.purple : Colors.purple,
                  foregroundColor: Theme.of(context).brightness == Brightness.light ? Colors.white : Colors.white,
                  side: BorderSide(
                    color: Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.grey,
                    width: 1.5,
                  ),
                ),
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _selectedDate = pickedDate;
                    });
                  }
                },
                child: Text(_selectedDate == null
                    ? 'Pick a date'
                    : 'Selected: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}'),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.35,
                        child: PieChart(
                          PieChartData(
                            sections: getPieSectionsFromMap(
                              _selectedDate == null
                                  ? dailyTotals
                                  : getCategoryTotalsForSelectedDate(),
                            ),
                            centerSpaceRadius: 40,
                            sectionsSpace: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.9,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: buildLegend(
                            _selectedDate == null
                                ? dailyTotals
                                : getCategoryTotalsForSelectedDate(),
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
        title = "Daily Expenses";
        break;
      case AnalyticsType.monthly:
        analyticsContent = Column(
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).brightness == Brightness.light ? Colors.purple : Colors.purple,
                foregroundColor: Theme.of(context).brightness == Brightness.light ? Colors.white : Colors.white,
                side: BorderSide(
                  color: Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.grey,
                  width: 1.5,
                ),
              ),
              onPressed: () async {
                final pickedMonth = await showMonthPicker(
                  context: context,
                  initialDate: _selectedMonth ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (pickedMonth != null) {
                  setState(() {
                    // Only keep year and month, set day to 1
                    _selectedMonth = DateTime(pickedMonth.year, pickedMonth.month, 1);
                  });
                }
              },
              child: Text(_selectedMonth == null
                  ? 'Pick a month'
                  : 'Selected: ${DateFormat('yyyy-MM').format(_selectedMonth!)}'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.35,
                    child: PieChart(
                      PieChartData(
                        sections: getPieSectionsFromMap(
                          _selectedMonth == null
                              ? monthlyTotals
                              : {
                                  DateFormat('yyyy-MM').format(_selectedMonth!):
                                      monthlyTotals[DateFormat('yyyy-MM').format(_selectedMonth!)] ?? 0,
                                },
                        ),
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: buildLegend(
                        _selectedMonth == null
                            ? monthlyTotals
                            : {
                                DateFormat('yyyy-MM').format(_selectedMonth!):
                                    monthlyTotals[DateFormat('yyyy-MM').format(_selectedMonth!)] ?? 0,
                              },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        title = "Monthly Expenses";
        break;
      case AnalyticsType.category:
        analyticsContent = buildCategoryAnalytics();
        title = "Expenses by Category";
        break;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Expense Analytics')),
      body: categoryTotals.isEmpty && dailyTotals.isEmpty && monthlyTotals.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.brightness == Brightness.light ? Colors.black : Colors.transparent,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ToggleButtons(
                        isSelected: [
                          _selectedAnalytics == AnalyticsType.category,
                          _selectedAnalytics == AnalyticsType.daily,
                          _selectedAnalytics == AnalyticsType.monthly,
                        ],
                        onPressed: (index) {
                          setState(() {
                            _selectedAnalytics = AnalyticsType.values[index];
                            if (_selectedAnalytics != AnalyticsType.daily) {
                              _selectedDate = null; // reset date when not daily
                            }
                            if (_selectedAnalytics != AnalyticsType.monthly) {
                              _selectedMonth = null; // reset month when not monthly
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        selectedColor: Colors.white,
                        fillColor: Colors.deepPurpleAccent,
                        color: Colors.deepPurpleAccent,
                        constraints: const BoxConstraints(minHeight: 40, minWidth: 100),
                        borderColor: Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.grey,
                        selectedBorderColor: Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.grey,
                        children: const [
                          Text('Category'),
                          Text('Daily'),
                          Text('Monthly'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: analyticsContent,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget buildCategoryAnalytics() {
    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Theme.of(context).brightness == Brightness.light ? Colors.black : const Color.fromARGB(0, 148, 129, 129),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.35,
                    child: PieChart(
                      PieChartData(
                        sections: getPieSections(),
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Changed legend container to show all categories vertically with scrolling if needed
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.25,
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: buildLegend(categoryTotals),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Theme.of(context).brightness == Brightness.light ? Colors.black : const Color.fromARGB(0, 115, 109, 109),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        barGroups: getBarGroups(categoryTotals),
                        borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false,
                            reservedSize: 0,
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false,
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false,
                          ),
                        ),
                      ),
                        gridData: FlGridData(show: false),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: Colors.deepPurpleAccent,
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                          tooltipPadding: const EdgeInsets.all(8),
                          maxContentWidth: 150,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final int index = group.x.toInt();
                            String key = '';
                            if (index >= 0 && index < sortedEntries.length) {
                              key = sortedEntries[index].key;
                            } else {
                              key = 'Unknown';
                            }
                            final value = rod.toY;
                            return BarTooltipItem(
                              '$key: ₹${value.toStringAsFixed(2)}',
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            );
                          },
                        ),
                      ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          buildLineChart(),
        ],
      ),
    );
  }

  List<FlSpot> getLineChartSpots() {
    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    List<FlSpot> spots = [];
    for (int i = 0; i < sortedEntries.length; i++) {
      spots.add(FlSpot(i.toDouble(), sortedEntries[i].value));
    }
    return spots;
  }

  Widget buildLineChart() {
    if (categoryTotals.isEmpty) {
      return const Center(child: Text('No data available for line chart'));
    }
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.light ? Colors.black : const Color.fromARGB(0, 130, 122, 122),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category Totals Line Graph',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: getLineChartSpots(),
                      isCurved: true,
                      color: Colors.deepPurpleAccent,
                      barWidth: 4,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                              radius: 6,
                              color: Colors.deepPurpleAccent,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            ),
                            
                      ),
                      belowBarData: BarAreaData(show: true, color: Colors.deepPurpleAccent.withValues(alpha: 0.3)),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Theme.of(context).brightness == Brightness.light ? Colors.grey[300]! : Colors.deepPurpleAccent,
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((touchedSpot) {
                          final index = touchedSpot.spotIndex;
                          final sortedEntries = categoryTotals.entries.toList()
                            ..sort((a, b) => b.value.compareTo(a.value));
                          final key = sortedEntries[index].key;
                          final value = sortedEntries[index].value;
                          return LineTooltipItem(
                            '$key\n₹${value.toStringAsFixed(2)}',
                            TextStyle(
                              color: Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                    handleBuiltInTouches: true,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBarChart(Map<String, double> dataMap, String chartTitle) {
    if (dataMap.isEmpty) {
      return const Center(child: Text('No data available'));
    }
    final sortedEntries = dataMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              chartTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 450,
              child: Stack(
                children: [
                  BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: sortedEntries.isNotEmpty ? sortedEntries.first.value * 1.1 : 0,
                      barGroups: getBarGroups(dataMap),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false,
                            reservedSize: 0,
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false,
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= dataMap.length) {
                                return const SizedBox.shrink();
                              }
                              final key = sortedEntries[index].key;
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text(key, style: const TextStyle(fontSize: 10)),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(show: false),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: Colors.deepPurpleAccent,
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                          tooltipPadding: const EdgeInsets.all(8),
                          maxContentWidth: 150,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final int index = group.x.toInt();
                            String key = '';
                            if (index >= 0 && index < sortedEntries.length) {
                              key = sortedEntries[index].key;
                            } else {
                              key = 'Unknown';
                            }
                            final value = rod.toY;
                            return BarTooltipItem(
                              '$key: ₹${value.toStringAsFixed(2)}',
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
