/// Planner cycle consent status and deleted count details.
class PlannerCycleConsent {
  const PlannerCycleConsent({
    required this.enabled,
    this.consentRecordedAt,
    this.deletedCyclePlansCount = 0,
  });

  final bool enabled;
  final DateTime? consentRecordedAt;
  final int deletedCyclePlansCount;

  PlannerCycleConsent copyWith({
    bool? enabled,
    DateTime? consentRecordedAt,
    bool clearConsentRecordedAt = false,
    int? deletedCyclePlansCount,
  }) {
    return PlannerCycleConsent(
      enabled: enabled ?? this.enabled,
      consentRecordedAt: clearConsentRecordedAt
          ? null
          : (consentRecordedAt ?? this.consentRecordedAt),
      deletedCyclePlansCount:
          deletedCyclePlansCount ?? this.deletedCyclePlansCount,
    );
  }

  factory PlannerCycleConsent.fromJson(Map<String, dynamic> json) {
    return PlannerCycleConsent(
      enabled: json['enabled'] as bool? ?? false,
      consentRecordedAt: json['consent_recorded_at'] != null
          ? DateTime.parse(json['consent_recorded_at'] as String)
          : null,
      deletedCyclePlansCount:
          (json['deleted_cycle_plans_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'consent_recorded_at': consentRecordedAt?.toIso8601String(),
      'deleted_cycle_plans_count': deletedCyclePlansCount,
    };
  }
}
