import 'package:bloomwell/features/self_care/domain/entities/activity_entry.dart';

/// Represents a saved comfort plan item.
class ComfortPlanItem {
  final String id;
  final String activityId;
  final ActivityEntry? activity;
  final int position;
  final DateTime createdAt;

  const ComfortPlanItem({
    required this.id,
    required this.activityId,
    this.activity,
    required this.position,
    required this.createdAt,
  });

  ComfortPlanItem copyWith({
    String? id,
    String? activityId,
    ActivityEntry? activity,
    int? position,
    DateTime? createdAt,
  }) {
    return ComfortPlanItem(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      activity: activity ?? this.activity,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ComfortPlanItem.fromJson(Map<String, dynamic> json) {
    ActivityEntry? parsedActivity;
    if (json['activity'] is Map<String, dynamic>) {
      parsedActivity =
          ActivityEntry.fromJson(json['activity'] as Map<String, dynamic>);
    }

    return ComfortPlanItem(
      id: json['id'] as String? ?? '',
      activityId: json['activity_id'] as String? ?? '',
      activity: parsedActivity,
      position: (json['position'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activity_id': activityId,
      if (activity != null) 'activity': activity!.toJson(),
      'position': position,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }
}
