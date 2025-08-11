import 'package:flutter/material.dart';
import 'screens/auth/signup.dart';
import 'package:finance_analyzer/authentication/auth.dart'; // Import AuthService
import 'package:lottie/lottie.dart';

class OnboardingScreen extends StatefulWidget {
  final AuthService authService;
  final VoidCallback onSignupSuccess;

  const OnboardingScreen({
    super.key,
    required this.authService,
    required this.onSignupSuccess,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      _buildPage(
        title: 'Welcome to Finance Analyzer',
        description: 'Track your finances and achieve your goals.',
        animationPath: 'assets/finance1.json',
      ),
      _buildPage(
        title: 'Manage Your Budget',
        description: 'Stay on top of your spending and savings.',
        animationPath: 'assets/finance2.json',
      ),
      _buildPage(
        title: 'Get Started Now',
        description: 'Create an account to begin your journey.',
        animationPath: 'assets/finance3.json',
      ),
    ]);
  }

  Widget _buildPage({required String title, required String description, required String animationPath}) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(animationPath, width: 250, height: 250, fit: BoxFit.contain),
          const SizedBox(height: 40),
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            description,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _getStarted() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SignupScreen(
          authService: widget.authService,
          onSignupSuccess: widget.onSignupSuccess,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            children: _pages,
          ),
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(
                    _pages.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 16 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? Colors.purple : Colors.grey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                _currentPage < _pages.length - 1
                    ? ElevatedButton(
                        onPressed: _nextPage,
                        child: const Text('Next'),
                      )
                    : ElevatedButton(
                        onPressed: _getStarted,
                        child: const Text('Get Started'),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
