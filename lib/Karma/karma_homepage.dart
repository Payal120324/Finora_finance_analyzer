import 'package:flutter/material.dart';
import 'screens/karma_dashboard_screen.dart';
import 'screens/badge_gallery_screen.dart';
import 'services/mission_initializer.dart';
import 'services/badge_initializer.dart';

class KarmaHomePage extends StatefulWidget {
  final String uid;
  const KarmaHomePage({super.key, required this.uid});

  @override
  State<KarmaHomePage> createState() => _KarmaHomePageState();
}

class _KarmaHomePageState extends State<KarmaHomePage> {
  bool _missionsInitialized = false;
  bool _initializingMissions = false;
  bool _badgesInitialized = false;
  bool _initializingBadges = false;

  @override
  void initState() {
    super.initState();
    _initializeMissions();
    _initializeBadges();
  }

  Future<void> _initializeMissions() async {
    if (!_missionsInitialized && !_initializingMissions) {
      setState(() {
        _initializingMissions = true;
      });
      final initializer = MissionInitializer(widget.uid);
      await initializer.createSampleMissions();
      setState(() {
        _missionsInitialized = true;
        _initializingMissions = false;
      });
    }
  }

  Future<void> _initializeBadges() async {
    if (!_badgesInitialized && !_initializingBadges) {
      setState(() {
        _initializingBadges = true;
      });
      final initializer = BadgeInitializer(widget.uid);
      await initializer.initializeBadgesForNewUser();
      setState(() {
        _badgesInitialized = true;
        _initializingBadges = false;
      });
    }
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
        if (_initializingMissions) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Initializing missions, please wait...'),
              backgroundColor: Colors.orange,
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
              "Manage your karma, view badges, and track your progress.",
              style: TextStyle(
                fontSize: 18,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 30),
            _buildNavigationCard(
              context,
              title: "Karma Dashboard",
              subtitle: "View your karma progress and stats",
              icon: Icons.dashboard,
              iconBackground: Colors.deepPurple,
              destination: KarmaDashboardScreen(uid: widget.uid),
            ),
            const SizedBox(height: 20),
            _buildNavigationCard(
              context,
              title: "Badge Gallery",
              subtitle: "See your earned badges",
              icon: Icons.emoji_events,
              iconBackground: Colors.orangeAccent,
              destination: BadgeGalleryScreen(uid: widget.uid),
            ),
          ],
        ),
      ),
    );
  }
}
