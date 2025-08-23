class WeeklyChallenge {
  final String id;
  final String title;
  final String description;
  final String badgeId;
  final String badgeName;
  final String badgeIcon;
  final String animationPath;
  final int difficulty; // 1-5
  final String category;

  WeeklyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.badgeId,
    required this.badgeName,
    required this.badgeIcon,
    required this.animationPath,
    required this.difficulty,
    required this.category,
  });

  factory WeeklyChallenge.fromMap(Map<String, dynamic> map) {
    return WeeklyChallenge(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      badgeId: map['badgeId'],
      badgeName: map['badgeName'],
      badgeIcon: map['badgeIcon'],
      animationPath: map['animationPath'],
      difficulty: map['difficulty'],
      category: map['category'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'badgeId': badgeId,
      'badgeName': badgeName,
      'badgeIcon': badgeIcon,
      'animationPath': animationPath,
      'difficulty': difficulty,
      'category': category,
    };
  }
}
