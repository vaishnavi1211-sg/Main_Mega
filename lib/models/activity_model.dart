// lib/models/activity_model.dart
class Activity {
  final String id;
  final String? userId;
  final String activityType;
  final String description;
  final String? referenceId;
  final String? referenceType;
  final DateTime createdAt;

  Activity({
    required this.id,
    this.userId,
    required this.activityType,
    required this.description,
    this.referenceId,
    this.referenceType,
    required this.createdAt,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      activityType: json['activity_type'] as String,
      description: json['description'] as String,
      referenceId: json['reference_id'] as String?,
      referenceType: json['reference_type'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'activity_type': activityType,
      'description': description,
      'reference_id': referenceId,
      'reference_type': referenceType,
      'created_at': createdAt.toIso8601String(),
    };
  }
}