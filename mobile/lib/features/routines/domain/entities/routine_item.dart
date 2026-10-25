/// Represents an activity item scheduled or saved in a personal routine.
class RoutineItem {
  final String id;
  final String routineId;
  final String activityId;
  final String activityTitle;
  final DateTime? scheduledDate;
  final DateTime? completedAt;
  final int position;

  const RoutineItem({
    required this.id,
    required this.routineId,
    required this.activityId,
    required this.activityTitle,
    this.scheduledDate,
    this.completedAt,
    this.position = 0,
  });

  bool get isDone => completedAt != null;

  RoutineItem copyWith({
    String? id,
    String? routineId,
    String? activityId,
    String? activityTitle,
    DateTime? scheduledDate,
    bool clearScheduledDate = false,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    int? position,
  }) {
    return RoutineItem(
      id: id ?? this.id,
      routineId: routineId ?? this.routineId,
      activityId: activityId ?? this.activityId,
      activityTitle: activityTitle ?? this.activityTitle,
      scheduledDate:
          clearScheduledDate ? null : (scheduledDate ?? this.scheduledDate),
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      position: position ?? this.position,
    );
  }

  factory RoutineItem.fromJson(Map<String, dynamic> json) {
    return RoutineItem(
      id: json['id'] as String? ?? '',
      routineId: json['routine_id'] as String? ?? '',
      activityId: json['activity_id'] as String? ?? '',
      activityTitle:
          json['activity_title'] as String? ?? json['title'] as String? ?? '',
      scheduledDate: json['scheduled_date'] != null
          ? DateTime.parse(json['scheduled_date'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String).toLocal()
          : null,
      position: (json['position'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'routine_id': routineId,
      'activity_id': activityId,
      'activity_title': activityTitle,
      if (scheduledDate != null)
        'scheduled_date':
            '${scheduledDate!.year.toString().padLeft(4, '0')}-${scheduledDate!.month.toString().padLeft(2, '0')}-${scheduledDate!.day.toString().padLeft(2, '0')}',
      if (completedAt != null)
        'completed_at': completedAt!.toUtc().toIso8601String(),
      'position': position,
    };
  }
}
