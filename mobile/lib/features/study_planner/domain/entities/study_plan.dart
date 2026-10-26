import 'personalization_info.dart';
import 'study_plan_item.dart';
import 'study_plan_mode.dart';

/// A 7-day study plan schedule.
class StudyPlan {
  const StudyPlan({
    required this.id,
    required this.weekStart,
    required this.days,
    required this.mode,
    required this.usesCycleData,
    required this.personalization,
    required this.items,
    required this.createdAt,
  });

  final String id;
  final DateTime weekStart;
  final int days;
  final StudyPlanMode mode;
  final bool usesCycleData;
  final PersonalizationInfo personalization;
  final List<StudyPlanItem> items;
  final DateTime createdAt;

  StudyPlan copyWith({
    String? id,
    DateTime? weekStart,
    int? days,
    StudyPlanMode? mode,
    bool? usesCycleData,
    PersonalizationInfo? personalization,
    List<StudyPlanItem>? items,
    DateTime? createdAt,
  }) {
    return StudyPlan(
      id: id ?? this.id,
      weekStart: weekStart ?? this.weekStart,
      days: days ?? this.days,
      mode: mode ?? this.mode,
      usesCycleData: usesCycleData ?? this.usesCycleData,
      personalization: personalization ?? this.personalization,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory StudyPlan.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'] as List<dynamic>? ?? [];
    final items = itemsRaw
        .map((e) => StudyPlanItem.fromJson(e as Map<String, dynamic>))
        .toList();
    // Sort items chronologically by planDate
    items.sort((a, b) => a.planDate.compareTo(b.planDate));

    return StudyPlan(
      id: json['id'] as String,
      weekStart: DateTime.parse(json['week_start'] as String),
      days: (json['days'] as num?)?.toInt() ?? 7,
      mode: StudyPlanMode.fromString(json['mode'] as String? ?? 'default'),
      usesCycleData: json['uses_cycle_data'] as bool? ?? false,
      personalization: PersonalizationInfo.fromJson(
          json['personalization'] as Map<String, dynamic>? ?? {}),
      items: items,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    final y = weekStart.year.toString().padLeft(4, '0');
    final m = weekStart.month.toString().padLeft(2, '0');
    final d = weekStart.day.toString().padLeft(2, '0');
    return {
      'id': id,
      'week_start': '$y-$m-$d',
      'days': days,
      'mode': mode.apiValue,
      'uses_cycle_data': usesCycleData,
      'personalization': personalization.toJson(),
      'items': items.map((e) => e.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
