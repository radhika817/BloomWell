import 'activity_category.dart';

/// Represents a completion record for a completed wellness activity.
class ActivityCompletionLog {
  final String id;
  final String clientId;
  final String activityId;
  final String activityTitle;
  final ActivityCategory activityCategory;
  final DateTime completedAt;
  final int? helpfulnessRating; // 1 to 5 optional rating

  const ActivityCompletionLog({
    required this.id,
    required this.clientId,
    required this.activityId,
    required this.activityTitle,
    required this.activityCategory,
    required this.completedAt,
    this.helpfulnessRating,
  });

  factory ActivityCompletionLog.fromJson(Map<String, dynamic> json) {
    return ActivityCompletionLog(
      id: json['id'] as String? ?? '',
      clientId: json['client_id'] as String? ?? '',
      activityId: json['activity_id'] as String? ?? '',
      activityTitle:
          json['activity_title'] as String? ?? json['title'] as String? ?? '',
      activityCategory:
          ActivityCategory.fromString(json['category'] as String?),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String).toLocal()
          : DateTime.now(),
      helpfulnessRating: (json['helpfulness_rating'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'activity_id': activityId,
      'activity_title': activityTitle,
      'category': activityCategory.apiValue,
      'completed_at': completedAt.toUtc().toIso8601String(),
      if (helpfulnessRating != null) 'helpfulness_rating': helpfulnessRating,
    };
  }
}
