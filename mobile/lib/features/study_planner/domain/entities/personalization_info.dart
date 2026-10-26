import 'study_plan_mode.dart';

/// Personalization metadata provided by the study planner engine.
class PersonalizationInfo {
  const PersonalizationInfo({
    required this.status,
    required this.checkinDaysUsed,
    required this.checkinDaysNeeded,
  });

  final StudyPlanMode status;
  final int checkinDaysUsed;
  final int checkinDaysNeeded;

  factory PersonalizationInfo.fromJson(Map<String, dynamic> json) {
    return PersonalizationInfo(
      status: StudyPlanMode.fromString(json['status'] as String? ?? 'default'),
      checkinDaysUsed: (json['checkin_days_used'] as num?)?.toInt() ?? 0,
      checkinDaysNeeded: (json['checkin_days_needed'] as num?)?.toInt() ?? 14,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.apiValue,
      'checkin_days_used': checkinDaysUsed,
      'checkin_days_needed': checkinDaysNeeded,
    };
  }
}
