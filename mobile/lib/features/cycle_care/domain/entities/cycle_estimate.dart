/// Status of cycle estimate provided by the server.
enum CycleEstimateStatus {
  notEnoughData('not_enough_data'),
  tooVariable('too_variable'),
  estimate('estimate');

  const CycleEstimateStatus(this.apiValue);
  final String apiValue;

  static CycleEstimateStatus fromString(String? val) {
    for (final status in CycleEstimateStatus.values) {
      if (status.apiValue == val || status.name == val) {
        return status;
      }
    }
    return CycleEstimateStatus.notEnoughData;
  }
}

/// Domain entity representing a cycle estimate returned by the API.
/// Never computed locally; displayed strictly as returned by the backend.
class CycleEstimate {
  const CycleEstimate({
    required this.status,
    this.typicalCycleLengthDays,
    this.cyclesCounted,
    this.neededCycles,
    this.estimatedRangeStart,
    this.estimatedRangeEnd,
    this.explanation,
  });

  final CycleEstimateStatus status;

  /// Typical length in days derived from recent cycles (e.g. median).
  final int? typicalCycleLengthDays;

  /// Number of logged cycles used to produce this estimate.
  final int? cyclesCounted;

  /// Number of usable cycles still needed to generate an estimate.
  final int? neededCycles;

  /// Start date of the estimated window in format YYYY-MM-DD.
  final String? estimatedRangeStart;

  /// End date of the estimated window in format YYYY-MM-DD.
  final String? estimatedRangeEnd;

  /// Optional server-provided explanation text.
  final String? explanation;

  bool get hasEstimateRange =>
      status == CycleEstimateStatus.estimate &&
      estimatedRangeStart != null &&
      estimatedRangeEnd != null;

  factory CycleEstimate.fromJson(Map<String, dynamic> json) {
    return CycleEstimate(
      status: CycleEstimateStatus.fromString(json['status'] as String?),
      typicalCycleLengthDays: json['typical_cycle_length_days'] as int?,
      cyclesCounted: json['cycles_counted'] as int?,
      neededCycles: json['needed_cycles'] as int?,
      estimatedRangeStart: json['estimated_range_start'] as String? ??
          json['estimated_start_range_start'] as String?,
      estimatedRangeEnd: json['estimated_range_end'] as String? ??
          json['estimated_start_range_end'] as String?,
      explanation: json['explanation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.apiValue,
      if (typicalCycleLengthDays != null)
        'typical_cycle_length_days': typicalCycleLengthDays,
      if (cyclesCounted != null) 'cycles_counted': cyclesCounted,
      if (neededCycles != null) 'needed_cycles': neededCycles,
      if (estimatedRangeStart != null)
        'estimated_range_start': estimatedRangeStart,
      if (estimatedRangeEnd != null) 'estimated_range_end': estimatedRangeEnd,
      if (explanation != null) 'explanation': explanation,
    };
  }
}
