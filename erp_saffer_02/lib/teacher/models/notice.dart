enum NoticePriority { low, normal, high }

extension NoticePriorityX on NoticePriority {
  String get label {
    switch (this) {
      case NoticePriority.low:
        return 'Low';
      case NoticePriority.normal:
        return 'Normal';
      case NoticePriority.high:
        return 'High';
    }
  }

  static NoticePriority fromString(String value) {
    switch (value.toLowerCase()) {
      case 'low':
        return NoticePriority.low;
      case 'high':
        return NoticePriority.high;
      default:
        return NoticePriority.normal;
    }
  }
}

/// Represents a notice published by a teacher.
class Notice {
  final String id;
  final String title;
  final String description;
  final NoticePriority priority;
  final DateTime publishedAt;

  const Notice({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.publishedAt,
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      priority: NoticePriorityX.fromString(json['priority'] as String? ?? 'normal'),
      publishedAt: DateTime.tryParse(json['publishedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority.label,
      'publishedAt': publishedAt.toIso8601String(),
    };
  }
}
