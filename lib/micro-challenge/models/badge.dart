class Badge {
  final String id;
  final String name;
  final String description;
  final String title;
  final String icon;
  final String animationPath;
  final int difficulty;
  final String category;
  final bool isUnlocked;

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.title,
    required this.icon,
    required this.animationPath,
    required this.difficulty,
    required this.category,
    this.isUnlocked = false,
  });

  factory Badge.fromChallenge({
    required String id,
    required String title,
    required String description,
    required String badgeId,
    required String animationPath,
    required int difficulty,
    required String category,
    required String icon,
    bool isUnlocked = false,
  }) {
    return Badge(
      id: badgeId,
      name: _getBadgeNameFromTitle(title),
      description: description,
      title: title,
      icon: _getBadgeIconFromTitle(title),
      animationPath: animationPath,
      difficulty: difficulty,
      category: category,
      isUnlocked: isUnlocked,
    );
  }

  static String _getBadgeNameFromTitle(String title) {
    // Extract badge name from challenge title
    final name = title.split(' ').take(2).join(' ');
    return name;
  }

  static String _getBadgeIconFromTitle(String title) {
    // Map titles to appropriate icons
    final iconMap = {
      'Budget Master': '🏆',
      'No Spend Days': '🚫',
      'Cash Tracker': '📊',
      'Meal Planner': '🍱',
      'Digital Detox': '📵',
      'Savings Boost': '🐷',
      'Subscription Audit': '🔍',
      'Impulse Control': '🎯',
      'Cash Envelope': '💳',
      'Financial Reading': '📚',
    };
    
    return iconMap[title] ?? '🏅';
  }

  Badge copyWith({
    String? id,
    String? name,
    String? description,
    String? title,
    String? icon,
    String? animationPath,
    int? difficulty,
    String? category,
    bool? isUnlocked,
  }) {
    return Badge(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      animationPath: animationPath ?? this.animationPath,
      difficulty: difficulty ?? this.difficulty,
      category: category ?? this.category,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'title': title,
      'icon': icon,
      'animationPath': animationPath,
      'difficulty': difficulty,
      'category': category,
      'isUnlocked': isUnlocked,
    };
  }
}
