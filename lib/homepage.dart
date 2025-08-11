import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'Category/expense_category_page.dart';
import 'package:finance_analyzer/authentication/auth.dart';
import 'screens/auth/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'analytics/analytics_page.dart';
import 'Budget/budget_tracker_page.dart';
import 'Bills/bill_homepage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'tip/daily_tip_notifier.dart';
import 'Goal/goal_homepage.dart';
import 'chatbot/chatbot_screen.dart';
import 'Karma/karma_homepage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'profile.dart';

class AppConstants {
  static const double defaultPadding = 16.0;
  static const double cardRadius = 12.0;
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Color featureCardColor = Color(0xFF800000);
  static const String appTitle = 'Finance Analyzer';
  static const String newsApiKey = '9fe4bb91e3ded439e6e81f5334b0d7b8';
  static const String newsApiBaseUrl = 'https://gnews.io/api/v4/top-headlines?lang=en&country=in&topic=business&token= newsApiKey';
}

class HomeScreen extends StatefulWidget {
  final String userEmail;
  final AuthService authService;
  const HomeScreen({
    super.key,
    required this.userEmail,
    required this.authService,
  });
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  late String userEmail;
  String? username;
  List<dynamic> newsItems = [];
  bool isLoading = true;
  String errorMessage = '';
  final List<Map<String, dynamic>> features = [
    {'title': 'Categories', 'image': 'assets/categories.png'},
    {'title': 'Budget', 'image': 'assets/budget.png'},
    {'title': 'Bills', 'image': 'assets/bill.png'},
    {'title': 'Chatbot', 'image': 'assets/chatbot.png'},
    {'title': 'Goals', 'image': 'assets/goal.png'},
    {'title': 'Karma', 'image': 'assets/karma.png'},
  ];
  bool _alertShown = false;

  @override
  void initState() {
    super.initState();
    DailyTipNotifier.showIfNeeded();
    AwesomeNotifications().initialize(null, [
      NotificationChannel(
        channelKey: 'bill_reminders',
        channelName: 'Bill Reminders',
        channelDescription: 'Notification channel for bill reminders',
        defaultColor: Colors.deepPurple,
        importance: NotificationImportance.High,
        channelShowBadge: true,
        locked: false,
      ),
      NotificationChannel(
        channelKey: 'budget_alerts',
        channelName: 'Budget Alerts',
        channelDescription: 'Notification channel for budget alerts',
        defaultColor: Colors.deepPurple,
        importance: NotificationImportance.High,
        channelShowBadge: true,
        locked: false,
      ),
      NotificationChannel(
        channelKey: 'daily_tip_channel',
        channelName: 'Daily Tips',
        channelDescription: 'Notification channel for daily financial tips',
        defaultColor: Color(0xFF4CAF50),
        importance: NotificationImportance.High,
        channelShowBadge: true,
        locked: false,
      ),
    ], debug: true);

    userEmail = widget.userEmail;
    username = FirebaseAuth.instance.currentUser?.displayName;
    fetchFinanceNews();
    _requestNotificationPermission();
    _checkBudgetAlert();
    _notifyBillsDueSoon();
  }

  Future<void> _notifyBillsDueSoon() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfThreeDaysLater = startOfToday.add(const Duration(days: 3));

    final snapshot =
        await FirebaseFirestore.instance
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
      if (category == "Electricity") {
        categoryMessage = "Don't let lights go out! Electricity bill";
      }
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
        body =
            'Reminder: $categoryMessage of ₹${amount.toStringAsFixed(2)} is due today.';
      } else if (daysLeft == 1) {
        title = '⚡ Bill Due Tomorrow!';
        body =
            '$categoryMessage of ₹${amount.toStringAsFixed(2)} is due tomorrow!';
      } else if (daysLeft == 2 || daysLeft == 3) {
        title = '🧾 Bill Due Soon!';
        body =
            '$categoryMessage of ₹${amount.toStringAsFixed(2)} is due in $daysLeft days!';
      } else {
        continue; // skip if not in the range
      }

      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: doc.id.hashCode + 1000, // unique id offset to avoid conflicts
          channelKey: 'bill_reminders',
          title: title,
          body: body,
        ),
      );
    }
  }

  Future<void> _requestNotificationPermission() async {
    if (!await AwesomeNotifications().isNotificationAllowed()) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  Future<void> _checkBudgetAlert() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
      final userData = userDoc.data() ?? {};
      final budget = (userData['budget'] ?? 0).toDouble();
      if (budget <= 0) return;
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final expensesSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('expenses')
              .where('date', isGreaterThanOrEqualTo: startOfMonth)
              .get();
      double totalSpent = 0;
      for (var doc in expensesSnapshot.docs) {
        totalSpent += (doc['amount'] as num).toDouble();
      }
      final percentUsed = totalSpent / budget;
      if (percentUsed >= 0.8) {
        if (!_alertShown) {
          _alertShown = true;
          _showBudgetAlert();
        }
      } else {
        _alertShown = false; // reset alert flag if usage below threshold
      }
    } catch (e) {}
  }

  void _showBudgetAlert() {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: 'budget_alerts',
        title: '⚠️ Budget Limit Alert!',
        body: 'You’ve spent over 80% of your monthly budget.',
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }


  Future<void> fetchFinanceNews() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      final url =
          'https://gnews.io/api/v4/top-headlines?lang=en&country=in&topic=business&token=${AppConstants.newsApiKey}';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!mounted) return;
        setState(() {
          newsItems = data['articles'] ?? data['results'] ?? [];
          isLoading = false;
        });
        // Save news to local cache
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('cachedNews', json.encode(newsItems));
      } else {
        // Load news from cache on failure
        final prefs = await SharedPreferences.getInstance();
        final cachedNews = prefs.getString('cachedNews');
        if (cachedNews != null) {
          setState(() {
            newsItems = json.decode(cachedNews);
            errorMessage = '';
            isLoading = false;
          });
        } else {
          if (!mounted) return;
          setState(() {
            isLoading = false;
            errorMessage = 'Failed to load news: ${response.statusCode}';
          });
        }
      }
    } catch (e) {
      // Load news from cache on exception
      final prefs = await SharedPreferences.getInstance();
      final cachedNews = prefs.getString('cachedNews');
      if (cachedNews != null) {
        setState(() {
          newsItems = json.decode(cachedNews);
          errorMessage = '';
          isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          isLoading = false;
          errorMessage = 'Error fetching news: $e';
        });
      }
    }
  }

 

  Widget _buildNewsCard(dynamic article, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> launchURL(String url) async {
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    }

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.8,
      child: InkWell(
        onTap: () {
          if (article['url'] != null && article['url'].toString().isNotEmpty) {
            launchURL(article['url']);
          }
        },
        child: Card(
          elevation: 6,
          shadowColor:
              isDark ? Colors.purpleAccent : Colors.grey.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            side: BorderSide(
              color: isDark ? Colors.grey : Colors.black,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article['title'] ?? 'No title',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppConstants.defaultPadding / 2),
                Expanded(
                  child: Text(
                    article['description'] ?? 'No description',
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (article['image_url'] != null &&
                    article['image_url'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: AppConstants.defaultPadding,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppConstants.cardRadius,
                      ),
                      child: Image.network(
                        article['image_url'],
                        height: 80,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return SizedBox(
                            height: 80,
                            child: Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 80,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[800]
                                    : Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.error, color: Colors.red),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(Map<String, dynamic> feature) {
    bool isHovering = false;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          onEnter: (_) => setState(() => isHovering = true),
          onExit: (_) => setState(() => isHovering = false),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            onTap: () {
              // Navigation logic remains the same
              if (feature['title'] == 'Categories') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ExpenseCategoryPage(),
                  ),
                );
              } else if (feature['title'] == 'Budget') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BudgetTrackerPage(),
                  ),
                );
              } else if (feature['title'] == 'Bills') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomePage(),
                  ),
                );
              } else if (feature['title'] == 'Chatbot') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatbotScreen(),
                  ),
                );
              } else if (feature['title'] == 'Goals') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GoalHomePage(
                      userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                    ),
                  ),
                );
              } else if (feature['title'] == 'Karma') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => KarmaHomePage(
                      uid: FirebaseAuth.instance.currentUser?.uid ?? '',
                    ),
                  ),
                );
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isHovering
                      ? [
                          Colors.deepPurple.shade400,
                          Colors.deepPurple.shade600,
                        ]
                      : [
                          isDark ? Colors.purple.shade700 : Colors.deepPurple.shade400,
                          isDark ? Colors.purple.shade900 : Colors.deepPurple.shade700,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                border: Border.all(
                  color: Colors.black,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isHovering
                        ? Colors.deepPurple.withOpacity(0.3)
                        : Colors.deepPurple.withOpacity(0.1),
                    blurRadius: isHovering ? 8 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: feature.containsKey('image')
                            ? Image.asset(
                                feature['image'],
                                width: feature['title'] == 'Karma' ? 48 : 40,
                                height: feature['title'] == 'Karma' ? 48 : 40,
                                fit: BoxFit.contain,
                              )
                            : Icon(
                                feature['icon'] ?? Icons.category,
                                size: feature['title'] == 'Karma' ? 48 : 40,
                                color: Colors.white,
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      flex: 1,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          feature['title'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text(AppConstants.appTitle),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchFinanceNews,
            tooltip: 'Refresh News',
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).viewInsets.bottom -
                  MediaQuery.of(context).viewPadding.bottom,
              maxWidth: MediaQuery.of(context).size.width * 0.85,
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepPurple.shade800,
                        Colors.deepPurple.shade900,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.25,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 42,
                            backgroundColor: Colors.white,
                            child: ClipOval(
                              child: Image.asset(
                                'assets/boy.png',
                                height: 76,
                                width: 76,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.6,
                            ),
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ProfilePage(),
                                ),
                              );
                            },
                            child: const Text(
                              'Profile',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                                shadows: [
                                  Shadow(
                                    offset: Offset(1, 1),
                                    blurRadius: 3,
                                    color: Colors.black45,
                                  ),
                                ],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Finance Analyzer User',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                ...features.map(
                  (feature) => ListTile(
                    leading:
                        feature.containsKey('image')
                            ? Image.asset(
                              feature['image'],
                              width: 24,
                              height: 24,
                            )
                            : Icon(feature['icon'], color: Colors.deepPurple),
                    title: Text(
                      feature['title'],
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    horizontalTitleGap: 8,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hoverColor: Colors.deepPurple.shade50,
                    onTap: () {
                      Navigator.pop(context);
                      if (feature['title'] == 'Categories') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ExpenseCategoryPage(),
                          ),
                        );
                      } else if (feature['title'] == 'Analytics') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AnalyticsPage(),
                          ),
                        );
                      } else if (feature['title'] == 'Budget') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BudgetTrackerPage(),
                          ),
                        );
                      } else if (feature['title'] == 'Bills') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HomePage(),
                          ),
                        );
                      } else if (feature['title'] == 'Chatbot') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChatbotScreen(),
                          ),
                        );
                      } else if (feature['title'] == 'Goals') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => GoalHomePage(
                                  userId:
                                      FirebaseAuth.instance.currentUser?.uid ??
                                      '',
                                ),
                          ),
                        );
                      }
                      else if (feature['title'] == 'Karma') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => KarmaHomePage(uid:
                                      FirebaseAuth.instance.currentUser?.uid ??
                                      '',),
                          ),
                        );
                      }
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.deepPurple),
                  title: const Text(
                    'Logout',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hoverColor: Colors.deepPurple.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  onTap: () async {
                    Navigator.pop(context);
                    await widget.authService.signOut();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder:
                            (context) => LoginScreen(
                              authService: widget.authService,
                              onLoginSuccess: () {},
                            ),
                      ),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: isLight ? const BoxDecoration(color: Colors.white) : null,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isLargeScreen = width > 600;
              return ListView(
                padding: EdgeInsets.only(
                  top: AppConstants.defaultPadding,
                  bottom:
                      MediaQuery.of(context).viewInsets.bottom +
                      AppConstants.defaultPadding,
                ),
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal:
                          isLargeScreen
                              ? AppConstants.defaultPadding * 2
                              : AppConstants.defaultPadding,
                    ),
                    child: Text(
                      'Welcome back',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            isLight ? Colors.deepPurple : Colors.purpleAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal:
                          isLargeScreen
                              ? AppConstants.defaultPadding * 2
                              : AppConstants.defaultPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Latest  News',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: AppConstants.defaultPadding),
                        if (isLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (errorMessage.isNotEmpty)
                          Card(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[800]
                                    : Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(
                                AppConstants.defaultPadding,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error, color: Colors.red),
                                  SizedBox(
                                    width: AppConstants.defaultPadding / 2,
                                  ),
                                  Expanded(
                                    child: Text(
                                      errorMessage,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                      SizedBox(
                        height: isLargeScreen ? 240 : 180,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(
                            horizontal: AppConstants.defaultPadding / 2,
                          ),
                          itemCount: newsItems.length,
                          separatorBuilder:
                              (context, index) => SizedBox(
                                width: AppConstants.defaultPadding,
                              ),
                          itemBuilder:
                              (context, index) =>
                                  _buildNewsCard(newsItems[index], context),
                        ),
                      ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      isLargeScreen
                          ? AppConstants.defaultPadding * 2
                          : AppConstants.defaultPadding,
                      AppConstants.defaultPadding / 2,
                      isLargeScreen
                          ? AppConstants.defaultPadding * 2
                          : AppConstants.defaultPadding,
                      MediaQuery.of(context).viewPadding.bottom +
                          AppConstants.defaultPadding / 2,
                    ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final crossAxisCount = 3;
                      final spacing = AppConstants.defaultPadding;
                      final availableWidth = constraints.maxWidth - (crossAxisCount - 1) * spacing;
                      final itemWidth = availableWidth / crossAxisCount;
                      final itemHeight = itemWidth * 1.3; // Increased height slightly
                      final rowCount = (features.length / crossAxisCount).ceil();
                      final gridHeight = (itemHeight * rowCount) + (spacing * (rowCount - 1));
                      
                      return SizedBox(
                        height: gridHeight,
                        child: GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: itemWidth / itemHeight,
                          mainAxisSpacing: spacing,
                          crossAxisSpacing: spacing,
                          padding: const EdgeInsets.all(4), // reduce padding to avoid overflow
                          children:
                              features
                                  .map((feature) => _buildFeatureCard(feature))
                                  .toList(),
                        ),
                      );
                    },
                  ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.deepPurple,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            if (index == 1) {
              // Navigate to AnalyticsPage
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AnalyticsPage(),
                ),
              );
            } else if (index == 2) {
              // Navigate to ProfilePage
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfilePage(),
                ),
              );
            }
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Container(
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(6),
              child: const Icon(Icons.home, color: Colors.white),
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Container(
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(6),
              child: const Icon(Icons.analytics, color: Colors.white),
            ),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Container(
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(6),
              child: const Icon(Icons.person, color: Colors.white),
            ),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
