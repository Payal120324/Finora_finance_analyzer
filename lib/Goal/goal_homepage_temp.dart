import 'package:flutter/material.dart';
import 'add_goal.dart';
import 'viewgoal.dart';

class GoalHomePage extends StatelessWidget {
  final String userId;
  const GoalHomePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance Analyzer'),
        centerTitle: true,
        backgroundColor: isDarkMode ? Colors.deepPurple[700] : Colors.purple,
        elevation: 4,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [Colors.deepPurple.shade900, Colors.black87]
                : [Colors.purple.shade100, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Welcome!",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    offset: Offset(1, 1),
                    blurRadius: 3,
                    color: Colors.black45,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Manage your goals, track progress, and achieve your financial targets easily.",
              style: TextStyle(
                fontSize: 18,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 30),

            // Add Goal Card
            _buildNavigationCard(
              context,
              title: "Add Goal",
              subtitle: "Create new savings goals",
              icon: Icons.add,
              iconBackground: Colors.blueAccent,
              destination: AddGoalScreen(userId: userId),
            ),

            const SizedBox(height: 20),

            // View Goals Card
            _buildNavigationCard(
              context,
              title: "View Goals",
              subtitle: "See your active goals",
              icon: Icons.list,
              iconBackground: Colors.orangeAccent,
              destination: GoalListScreen(userId: userId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationCard(BuildContext context,
      {required String title,
      required String subtitle,
      required IconData icon,
      required Color iconBackground,
      required Widget destination}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => destination),
        );
      },
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        shadowColor: isDarkMode ? Colors.black54 : Colors.grey.withOpacity(0.5),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: iconBackground.withOpacity(0.6),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Icon(icon, size: 40, color: Colors.white),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        )),
                    const SizedBox(height: 6),
                    Text(subtitle,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        )),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 20,
                  color: isDarkMode ? Colors.white70 : Colors.black45),
            ],
          ),
        ),
      ),
    );
  }
}
