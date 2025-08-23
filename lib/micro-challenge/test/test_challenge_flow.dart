import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/challenge_dashboard_screen.dart';

class TestChallengeFlow extends StatelessWidget {
  const TestChallengeFlow({super.key});

  Future<void> _resetChallenges() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Challenge Flow'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChallengeDashboardScreen(),
                  ),
                );
              },
              child: const Text('Open Challenge Dashboard'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _resetChallenges,
              child: const Text('Reset All Challenges'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Test the weekly challenge flow:\n'
              '1. Complete a challenge\n'
              '2. See unlocked badge\n'
              '3. View dynamic tips\n'
              '4. Wait for Monday for new challenge',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
