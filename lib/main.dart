import 'package:flutter/material.dart';
import 'authentication/auth.dart';
import 'screens/auth/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:finance_analyzer/homepage.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'onboarding.dart'; // Import onboarding screen

void main() async {
   WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
   AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'budget_alerts',
        channelName: 'Budget Alerts',
        channelDescription: 'Notification when budget exceeds limit',
        defaultColor: const Color(0xFF9D50DD),
        importance: NotificationImportance.High,
        ledColor: Colors.white,
      ),

      NotificationChannel(
        channelKey: 'bill_reminders',
        channelName: 'Bill Reminders',
        channelDescription: 'Notifications for upcoming bill payments',
        defaultColor: const Color(0xFF00C853),
        importance: NotificationImportance.High,
        ledColor: Colors.green,
      ),
    ],
  );
  runApp(FinanceAnalyzerApp());
}

class FinanceAnalyzerApp extends StatefulWidget {
  final AuthService authService = AuthService(); // Use correct class

  FinanceAnalyzerApp({super.key});

  @override
  _FinanceAnalyzerAppState createState() => _FinanceAnalyzerAppState();
}

class _FinanceAnalyzerAppState extends State<FinanceAnalyzerApp> {
  bool loggedIn = false;
  bool _showOnboarding = true; // New flag to show onboarding

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      loggedIn = true;
      _showOnboarding = false; // Skip onboarding if logged in
    }
  }

  void _onOnboardingComplete() {
    setState(() {
      _showOnboarding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance Analyzer',
      theme: ThemeData.dark(),
      home: Builder(
        builder: (context) {
          if (_showOnboarding) {
            return OnboardingScreen(
              authService: widget.authService,
              onSignupSuccess: _onOnboardingComplete,
            );
          } else if (loggedIn) {
            final userEmail = widget.authService.currentUserEmail ?? 'user@example.com';
            return HomeScreen(userEmail: userEmail, authService: widget.authService);
          } else {
            return LoginScreen(
              authService: widget.authService,
              onLoginSuccess: () {
                setState(() {
                  loggedIn = true;
                });
                final userEmail = widget.authService.currentUserEmail ?? 'user@example.com';
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeScreen(userEmail: userEmail, authService: widget.authService),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
