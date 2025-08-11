import 'package:flutter/material.dart';
import 'chatbot_message.dart';
import 'gemini_service.dart';
// import 'package:vibration/vibration.dart'; // Uncomment after adding vibration package

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatbotMessage> _messages = [];
  bool _isLoading = false;
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final input = _controller.text.trim();
    if (input.isEmpty) return;

    // Vibration feedback on send (uncomment after adding vibration package)
    // if (await Vibration.hasVibrator() ?? false) {
    //   Vibration.vibrate(duration: 50);
    // }

    setState(() {
      _messages.insert(0, ChatbotMessage(text: input, isUser: true, status: 'sent'));
      _controller.clear();
      _isLoading = true;
    });

    _scrollToTop();

    final reply = await GeminiApiService.getReply(input);

    setState(() {
      _messages.insert(0, ChatbotMessage(text: reply, isUser: false));
      _isLoading = false;
    });

    _animationController.forward(from: 0);
    _scrollToTop();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildMessage(ChatbotMessage msg) {
    final mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final horizontalMargin = mediaQuery.size.width * 0.03;
    final verticalMargin = mediaQuery.size.height * 0.008;
    final paddingAll = mediaQuery.size.width * 0.03;
    final avatarRadius = mediaQuery.size.width * 0.04;
    final fontSize = mediaQuery.size.width * 0.04;

    final userGradient = isDark
        ? const LinearGradient(
            colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final botGradient = isDark
        ? const LinearGradient(
            colors: [Color(0xFF424242), Color(0xFF616161)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFE0E0E0), Color(0xFFBDBDBD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final userTextColor = isDark ? Colors.white : Colors.white;
    final botTextColor = isDark ? Colors.white70 : Colors.black87;

    return FadeTransition(
      opacity: _animationController.drive(
        Tween<double>(begin: 0, end: 1).chain(CurveTween(curve: Curves.easeIn)),
      ),
      child: Align(
        alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.symmetric(vertical: verticalMargin, horizontal: horizontalMargin),
          padding: EdgeInsets.all(paddingAll),
          decoration: BoxDecoration(
            gradient: msg.isUser ? userGradient : botGradient,
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black87 : Colors.black.withOpacity(0.15),
                blurRadius: 6,
                offset: const Offset(3, 3),
              ),
            ],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!msg.isUser)
                    Padding(
                      padding: EdgeInsets.only(right: horizontalMargin / 1.5),
                      child: CircleAvatar(
                        radius: avatarRadius,
                        backgroundImage: const AssetImage('assets/robot.png'),
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  Flexible(
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        color: msg.isUser ? userTextColor : botTextColor,
                        fontSize: fontSize,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (msg.isUser)
                    Padding(
                      padding: EdgeInsets.only(left: horizontalMargin / 1.5),
                      child: CircleAvatar(
                        radius: avatarRadius,
                        backgroundImage: const AssetImage('assets/user.png'),
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTimestamp(msg.timestamp),
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: fontSize * 0.75,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  if (msg.isUser) ...[
                    const SizedBox(width: 8),
                    _buildStatusIcon(msg.status),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    if (timestamp.day == now.day && timestamp.month == now.month && timestamp.year == now.year) {
      return "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}";
    } else {
      return "${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}";
    }
  }

  Widget _buildStatusIcon(String status) {
    switch (status) {
      case 'sent':
        return const Icon(Icons.check, size: 14, color: Colors.grey);
      case 'delivered':
        return const Icon(Icons.done_all, size: 14, color: Colors.blue);
      case 'read':
        return const Icon(Icons.done_all, size: 14, color: Colors.green);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTypingIndicator() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.02),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: MediaQuery.of(context).size.width * 0.04,
            backgroundImage: const AssetImage('assets/robot.png'),
            backgroundColor: Colors.transparent,
          ),
          const SizedBox(width: 8),
          Container(
            width: 60,
            height: 24,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: TypingDots(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshChat() async {
    // For demonstration, just wait a moment. In real app, reload chat history.
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Finance Chatbot',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        // Remove backgroundColor to use gradient
        elevation: 6,
        shadowColor: isDark ? Colors.black87 : Colors.blueAccent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple, Colors.deepPurpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: AssetImage('assets/background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            color: isDark ? Colors.black.withOpacity(0.5) : Colors.white.withOpacity(0.5),
          ),
          Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshChat,
                  child: ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isLoading && index == 0) {
                        return _buildTypingIndicator();
                      }
                      final msg = _messages[_isLoading ? index - 1 : index];
                      return _buildMessage(msg);
                    },
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.03,
                  vertical: MediaQuery.of(context).size.height * 0.01,
                ),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.grey[100],
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black87 : Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, -3),
                    ),
                  ],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Ask a question...',
                          filled: true,
                          fillColor: isDark ? Colors.grey[800] : Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(context).size.width * 0.04,
                            vertical: MediaQuery.of(context).size.height * 0.015,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                    ElevatedButton(
                      onPressed: _sendMessage,
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.03),
                        backgroundColor: isDark ? Colors.lightBlueAccent : const Color(0xFF357ABD),
                      ),
                      child: Icon(Icons.send, color: isDark ? Colors.black87 : Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TypingDots extends StatefulWidget {
  const TypingDots({super.key});

  @override
  _TypingDotsState createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation1;
  late Animation<double> _animation2;
  late Animation<double> _animation3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();

    _animation1 = Tween<double>(begin: 0.2, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.7, curve: Curves.easeInOut)),
    );
    _animation2 = Tween<double>(begin: 0.2, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.9, curve: Curves.easeInOut)),
    );
    _animation3 = Tween<double>(begin: 0.2, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1.0, curve: Curves.easeInOut)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDot(Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: CircleAvatar(
          radius: 5,
          backgroundColor: Colors.grey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDot(_animation1),
        _buildDot(_animation2),
        _buildDot(_animation3),
      ],
    );
  }
}
