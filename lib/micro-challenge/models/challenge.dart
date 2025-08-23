class Challenge {
  final String id;
  final String title;
  final String description;
  final String badgeId;
  final String animationPath;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.badgeId,
    required this.animationPath,
  });

  factory Challenge.fromMap(Map<String, dynamic> map) {
    return Challenge(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      badgeId: map['badgeId'],
      animationPath: map['animationPath'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'badgeId': badgeId,
      'animationPath': animationPath,
    };
  }
}
