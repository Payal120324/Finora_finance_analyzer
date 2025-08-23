import 'package:flutter/material.dart' hide Badge;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import '../models/badge.dart' as app_badge;

class TipCard extends StatefulWidget {
  final app_badge.Badge badge;
  final VoidCallback onClose;
  
  const TipCard({
    super.key, 
    required this.badge, 
    required this.onClose,
  });

  @override
  State<TipCard> createState() => _TipCardState();
}

class _TipCardState extends State<TipCard> {
  List<String> tips = [];
  String currentTip = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTips();
  }

  Future<void> loadTips() async {
    try {
      final String response = await rootBundle.loadString('assets/financial_tips.json');
      final List<dynamic> data = json.decode(response);
      setState(() {
        tips = List<String>.from(data);
        currentTip = tips.isNotEmpty ? tips[DateTime.now().millisecondsSinceEpoch % tips.length] : 'No tips available';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        currentTip = 'Great job! You completed this week\'s challenge. Keep up the excellent work!';
        isLoading = false;
      });
    }
  }

  void refreshTip() {
    if (tips.isNotEmpty) {
      setState(() {
        currentTip = tips[DateTime.now().millisecondsSinceEpoch % tips.length];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🎉 Challenge Completed!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: widget.onClose,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    widget.badge.icon,
                    style: const TextStyle(fontSize: 64),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.badge.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Badge unlocked: ${widget.badge.description}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (isLoading)
              const SizedBox(
                height: 30,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '💡 Financial Tip:',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentTip,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (tips.length > 1) ...[
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: refreshTip,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Show Another Tip',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
