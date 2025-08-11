import 'package:cloud_firestore/cloud_firestore.dart';
enum BadgeType {
  bronze,
  silver,
  gold,
  platinum,
  diamond,
}

class Badge {
  final String id;
  final String name;
  final String description;
  final BadgeType type;
  final String icon;
  final DateTime? unlockedAt;
  final bool isUnlocked;
  final String? category;

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.icon,
    this.unlockedAt,
    this.isUnlocked = false,
    this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.toString().split('.').last,
      'icon': icon,
      'unlockedAt': unlockedAt,
      'isUnlocked': isUnlocked,
      'category': category,
    };
  }

  factory Badge.fromMap(Map<String, dynamic> map) {
    DateTime? parseTimestamp(dynamic timestamp) {
      if (timestamp == null) return null;
      
      try {
        // Handle Firestore Timestamp
        if (timestamp is Timestamp) {
          return timestamp.toDate();
        }
        // Handle String (ISO format)
        else if (timestamp is String) {
          return DateTime.parse(timestamp);
        }
        // Handle int (milliseconds since epoch)
        else if (timestamp is int) {
          return DateTime.fromMillisecondsSinceEpoch(timestamp);
        }
        // Handle DateTime
        else if (timestamp is DateTime) {
          return timestamp;
        }
      } catch (e) {
        print('Error parsing timestamp: $e');
        return null;
      }
      return null;
    }

    return Badge(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      type: BadgeType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => BadgeType.bronze,
      ),
      icon: map['icon'] ?? '',
      unlockedAt: parseTimestamp(map['unlockedAt']),
      isUnlocked: map['isUnlocked'] ?? false,
      category: map['category'],
    );
  }
}

// Import for Firestore Timestamp

