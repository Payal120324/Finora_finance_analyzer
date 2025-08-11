class KarmaMetrics {
  int score;
  int streak;
  int budgetUsed;
  int goalsDone;

  KarmaMetrics({
    required this.score,
    required this.streak,
    required this.budgetUsed,
    required this.goalsDone,
  });

  factory KarmaMetrics.empty() =>
      KarmaMetrics(score: 50, streak: 0, budgetUsed: 0, goalsDone: 0);

  factory KarmaMetrics.fromMap(Map<String, dynamic> m) => KarmaMetrics(
        score: m['score'] ?? 50,
        streak: m['streak'] ?? 0,
        budgetUsed: m['budgetUsed'] ?? 0,
        goalsDone: m['goalsDone'] ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'score': score,
        'streak': streak,
        'budgetUsed': budgetUsed,
        'goalsDone': goalsDone,
      };
}
