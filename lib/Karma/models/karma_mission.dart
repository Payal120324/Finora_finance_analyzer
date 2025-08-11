class KarmaMission {
  final String id;
  final String title;
  final String description;
  final bool done;
  KarmaMission({
    required this.id,
    required this.title,
    required this.description,
    required this.done,
  });

  factory KarmaMission.fromMap(Map<String, dynamic> m) => KarmaMission(
        id: m['id'],
        title: m['title'],
        description: m['description'],
        done: m['done'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'done': done,
      };
}
