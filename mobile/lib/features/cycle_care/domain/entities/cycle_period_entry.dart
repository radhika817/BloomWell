/// Domain entity representing a recorded menstrual period log entry.
class CyclePeriodEntry {
  const CyclePeriodEntry({
    required this.id,
    required this.clientId,
    required this.periodStart,
    this.periodEnd,
    this.cycleLengthDays,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String clientId;

  /// Local date string in format YYYY-MM-DD
  final String periodStart;

  /// Optional local date string in format YYYY-MM-DD
  final String? periodEnd;

  /// Computed cycle length in days between this and previous start (if returned by server)
  final int? cycleLengthDays;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isOngoing => periodEnd == null;

  /// Computes logged bleeding duration in days inclusive if end date is set.
  int? get durationDays {
    if (periodEnd == null) return null;
    final start = DateTime.tryParse(periodStart);
    final end = DateTime.tryParse(periodEnd!);
    if (start == null || end == null) return null;
    return end.difference(start).inDays + 1;
  }

  factory CyclePeriodEntry.fromJson(Map<String, dynamic> json) {
    return CyclePeriodEntry(
      id: json['id'] as String,
      clientId: json['client_id'] as String? ?? json['id'] as String,
      periodStart: json['period_start'] as String,
      periodEnd: json['period_end'] as String?,
      cycleLengthDays: json['cycle_length_days'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'period_start': periodStart,
      if (periodEnd != null) 'period_end': periodEnd,
      if (cycleLengthDays != null) 'cycle_length_days': cycleLengthDays,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  CyclePeriodEntry copyWith({
    String? id,
    String? clientId,
    String? periodStart,
    String? Function()? periodEnd,
    int? Function()? cycleLengthDays,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CyclePeriodEntry(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd != null ? periodEnd() : this.periodEnd,
      cycleLengthDays:
          cycleLengthDays != null ? cycleLengthDays() : this.cycleLengthDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
