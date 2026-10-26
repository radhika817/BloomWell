import 'plan_item_status.dart';
import 'suggested_load.dart';

/// A single day entry in a weekly study plan.
class StudyPlanItem {
  const StudyPlanItem({
    required this.id,
    required this.studyPlanId,
    required this.planDate,
    required this.suggestedLoad,
    required this.reasonCodes,
    this.academicEventId,
    this.activityId,
    required this.status,
    required this.updatedAt,
    this.academicEventTitle,
    this.activityTitle,
  });

  final String id;
  final String studyPlanId;
  final DateTime planDate;
  final SuggestedLoad suggestedLoad;
  final List<String> reasonCodes;
  final String? academicEventId;
  final String? activityId;
  final PlanItemStatus status;
  final DateTime updatedAt;
  final String? academicEventTitle;
  final String? activityTitle;

  StudyPlanItem copyWith({
    String? id,
    String? studyPlanId,
    DateTime? planDate,
    SuggestedLoad? suggestedLoad,
    List<String>? reasonCodes,
    String? academicEventId,
    String? activityId,
    PlanItemStatus? status,
    DateTime? updatedAt,
    String? academicEventTitle,
    String? activityTitle,
  }) {
    return StudyPlanItem(
      id: id ?? this.id,
      studyPlanId: studyPlanId ?? this.studyPlanId,
      planDate: planDate ?? this.planDate,
      suggestedLoad: suggestedLoad ?? this.suggestedLoad,
      reasonCodes: reasonCodes ?? this.reasonCodes,
      academicEventId: academicEventId ?? this.academicEventId,
      activityId: activityId ?? this.activityId,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      academicEventTitle: academicEventTitle ?? this.academicEventTitle,
      activityTitle: activityTitle ?? this.activityTitle,
    );
  }

  factory StudyPlanItem.fromJson(Map<String, dynamic> json) {
    return StudyPlanItem(
      id: json['id'] as String,
      studyPlanId: json['study_plan_id'] as String,
      planDate: DateTime.parse(json['plan_date'] as String),
      suggestedLoad: SuggestedLoad.fromString(
          json['suggested_load'] as String? ?? 'normal'),
      reasonCodes: (json['reason_codes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      academicEventId: json['academic_event_id'] as String?,
      activityId: json['activity_id'] as String?,
      status:
          PlanItemStatus.fromString(json['status'] as String? ?? 'suggested'),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      academicEventTitle: json['academic_event_title'] as String?,
      activityTitle: json['activity_title'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final y = planDate.year.toString().padLeft(4, '0');
    final m = planDate.month.toString().padLeft(2, '0');
    final d = planDate.day.toString().padLeft(2, '0');
    return {
      'id': id,
      'study_plan_id': studyPlanId,
      'plan_date': '$y-$m-$d',
      'suggested_load': suggestedLoad.apiValue,
      'reason_codes': reasonCodes,
      'academic_event_id': academicEventId,
      'activity_id': activityId,
      'status': status.apiValue,
      'updated_at': updatedAt.toIso8601String(),
      if (academicEventTitle != null)
        'academic_event_title': academicEventTitle,
      if (activityTitle != null) 'activity_title': activityTitle,
    };
  }
}
