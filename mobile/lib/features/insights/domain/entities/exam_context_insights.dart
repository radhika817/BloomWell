import 'insight_status.dart';

/// Single metric comparison before academic events.
class ExamMetricComparison {
  const ExamMetricComparison({
    required this.preEventAverage,
    required this.baselineAverage,
    required this.diff,
    required this.code,
  });

  final double preEventAverage;
  final double baselineAverage;
  final double diff;
  final String code;

  factory ExamMetricComparison.fromJson(Map<String, dynamic> json) {
    return ExamMetricComparison(
      preEventAverage: (json['pre_event_average'] as num?)?.toDouble() ?? 0.0,
      baselineAverage: (json['baseline_average'] as num?)?.toDouble() ?? 0.0,
      diff: (json['diff'] as num?)?.toDouble() ?? 0.0,
      code: json['code'] as String? ?? 'STRESS_SIMILAR_BEFORE_EVENTS',
    );
  }
}

/// Sample sizes for academic event observations.
class ExamSampleSizes {
  const ExamSampleSizes({
    required this.preEventDistinctDays,
    required this.baselineDistinctDays,
    required this.qualifyingEvents,
  });

  final int preEventDistinctDays;
  final int baselineDistinctDays;
  final int qualifyingEvents;

  factory ExamSampleSizes.fromJson(Map<String, dynamic> json) {
    return ExamSampleSizes(
      preEventDistinctDays:
          (json['pre_event_distinct_days'] as num?)?.toInt() ?? 0,
      baselineDistinctDays:
          (json['baseline_distinct_days'] as num?)?.toInt() ?? 0,
      qualifyingEvents: (json['qualifying_events'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Observations contextualizing mood check-ins around exams and deadlines.
class ExamContextInsights {
  const ExamContextInsights({
    required this.status,
    this.qualifyingEventsCount = 0,
    this.stress,
    this.energy,
    this.sampleSizes,
  });

  final InsightStatus status;
  final int qualifyingEventsCount;
  final ExamMetricComparison? stress;
  final ExamMetricComparison? energy;
  final ExamSampleSizes? sampleSizes;

  bool get hasSufficientData => status == InsightStatus.sufficientData;

  factory ExamContextInsights.fromJson(Map<String, dynamic> json) {
    final status = InsightStatus.fromString(
        json['status'] as String? ?? 'not_enough_data');

    ExamMetricComparison? stress;
    if (json['stress'] is Map<String, dynamic>) {
      stress =
          ExamMetricComparison.fromJson(json['stress'] as Map<String, dynamic>);
    }

    ExamMetricComparison? energy;
    if (json['energy'] is Map<String, dynamic>) {
      energy =
          ExamMetricComparison.fromJson(json['energy'] as Map<String, dynamic>);
    }

    ExamSampleSizes? sampleSizes;
    if (json['sample_sizes'] is Map<String, dynamic>) {
      sampleSizes = ExamSampleSizes.fromJson(
          json['sample_sizes'] as Map<String, dynamic>);
    }

    return ExamContextInsights(
      status: status,
      qualifyingEventsCount:
          (json['qualifying_events_count'] as num?)?.toInt() ?? 0,
      stress: stress,
      energy: energy,
      sampleSizes: sampleSizes,
    );
  }
}
