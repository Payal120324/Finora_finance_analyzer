import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/test_firebase_integration.dart';

class TestFirebaseScreenFixed extends StatefulWidget {
  const TestFirebaseScreenFixed({super.key});

  @override
  State<TestFirebaseScreenFixed> createState() => _TestFirebaseScreenFixedState();
}

class _TestFirebaseScreenFixedState extends State<TestFirebaseScreenFixed> {
  final FirebaseIntegrationTest _test = FirebaseIntegrationTest();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _status = '';
  bool _isLoading = false;

  Future<void> _resetUserData() async {
    setState(() {
      _isLoading = true;
      _status = 'Resetting user data...';
    });

    try {
      await _test.resetAllUserData();
      setState(() {
        _status = '✅ All user data reset successfully!\n'
                  'New users will start with all badges locked and no challenges completed.';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Error resetting data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkUserData() async {
    setState(() {
      _isLoading = true;
      _status = 'Checking user data status...';
    });

    try {
      await _test.checkUserDataStatus();
      setState(() {
        _status = '✅ User data status checked successfully!\n'
                  'Check console for detailed information.';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Error checking data status: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final List<Widget> children = [];

    if (user != null) {
      children.addAll([
        Text(
          'Logged in as: ${user.email}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          'User ID: ${user.uid}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 20),
      ]);
    } else {
      children.add(const Text(
        '❌ No user logged in',
        style: TextStyle(fontSize: 16, color: Colors.red),
      ));
    }

    children.addAll([
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: user != null ? _resetUserData : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
        ),
        child: const Text('Reset All User Data'),
      ),
      const SizedBox(height: 10),
      ElevatedButton(
        onPressed: user != null ? _checkUserData : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
        ),
        child: const Text('Check User Data Status'),
      ),
      const SizedBox(height: 20),
      if (_isLoading) const Center(child: CircularProgressIndicator()),
      if (_status.isNotEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _status,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      const SizedBox(height: 20),
      const Text(
        'Testing Instructions:',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 10),
      const Text('1. Make sure you are logged in with a test user'),
      const Text('2. Click "Reset All User Data" to clear existing data'),
      const Text('3. Navigate to the badge gallery to verify all badges are locked'),
      const Text('4. Complete a challenge and verify the badge unlocks'),
      const Text('5. Log in with a different user to verify data isolation'),
    ]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Integration Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}
