/// Domain entity representing cycle tracking consent status.
class CycleTrackingStatus {
  const CycleTrackingStatus({
    required this.cycleTrackingEnabled,
    this.consentRecordedAt,
  });

  final bool cycleTrackingEnabled;
  final DateTime? consentRecordedAt;

  factory CycleTrackingStatus.fromJson(Map<String, dynamic> json) {
    final consentStr = json['consent_recorded_at'] as String?;
    return CycleTrackingStatus(
      cycleTrackingEnabled: json['cycle_tracking_enabled'] as bool? ?? false,
      consentRecordedAt:
          consentStr != null ? DateTime.tryParse(consentStr) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cycle_tracking_enabled': cycleTrackingEnabled,
      'consent_recorded_at': consentRecordedAt?.toIso8601String(),
    };
  }

  CycleTrackingStatus copyWith({
    bool? cycleTrackingEnabled,
    DateTime? Function()? consentRecordedAt,
  }) {
    return CycleTrackingStatus(
      cycleTrackingEnabled: cycleTrackingEnabled ?? this.cycleTrackingEnabled,
      consentRecordedAt: consentRecordedAt != null
          ? consentRecordedAt()
          : this.consentRecordedAt,
    );
  }
}
