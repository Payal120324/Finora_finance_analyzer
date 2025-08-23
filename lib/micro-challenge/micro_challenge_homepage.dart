import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/badge_gallery_screen.dart';

class MicroChallengeHomePage extends StatefulWidget {
  final String uid;
  const MicroChallengeHomePage({super.key, required this.uid});

  @override
  State<MicroChallengeHomePage> createState() => _MicroChallengeHomePageState();
}

class _MicroChallengeHomePageState extends State<MicroChallengeHomePage> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Micro Challenge Hub'),
        centerTitle: true,
        backgroundColor: isDarkMode ? Colors.teal[700] : Colors.teal,
        elevation: 4,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [Colors.teal.shade900, Colors.black87]
                : [Colors.teal.shade100, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Welcome to Micro Challenges!",
              style: TextStyle(
                fontSize: 28,
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
              "Track your progress and earn badges through daily challenges.",
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 30),
            _buildNavigationCard(
              context,
              title: "Challenge Dashboard",
              subtitle: "View and complete daily challenges",
              icon: Icons.assignment,
              iconBackground: Colors.blue,
              destination: ChallengesScreen(),
            ),
            const SizedBox(height: 20),
            _buildNavigationCard(
              context,
              title: "Badge Gallery",
              subtitle: "See your earned achievement badges",
              icon: Icons.emoji_events,
              iconBackground: Colors.amber,
              destination: BadgeGalleryScreen(uid: widget.uid),
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
        if (widget.uid.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User ID is invalid. Please log in again.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => destination),
        );
      },
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        shadowColor: isDarkMode ? Colors.black54 : Colors.grey.withValues(alpha: 0.5),
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
                      color: iconBackground.withValues(alpha: 0.6),
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
