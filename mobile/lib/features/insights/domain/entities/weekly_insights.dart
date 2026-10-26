import 'insight_status.dart';

/// Single metric comparison for a weekly observation.
class WeeklyMetricComparison {
  const WeeklyMetricComparison({
    required this.weekAverage,
    required this.baselineAverage,
    required this.diff,
    required this.code,
  });

  final double weekAverage;
  final double baselineAverage;
  final double diff;
  final String code;

  factory WeeklyMetricComparison.fromJson(Map<String, dynamic> json) {
    return WeeklyMetricComparison(
      weekAverage: (json['week_average'] as num?)?.toDouble() ?? 0.0,
      baselineAverage: (json['baseline_average'] as num?)?.toDouble() ?? 0.0,
      diff: (json['diff'] as num?)?.toDouble() ?? 0.0,
      code: json['code'] as String? ?? 'SIMILAR',
    );
  }
}

/// Sample sizes for weekly comparison.
class WeeklySampleSizes {
  const WeeklySampleSizes({
    required this.weekDistinctDays,
    required this.baselineDistinctDays,
  });

  final int weekDistinctDays;
  final int baselineDistinctDays;

  factory WeeklySampleSizes.fromJson(Map<String, dynamic> json) {
    return WeeklySampleSizes(
      weekDistinctDays: (json['week_distinct_days'] as num?)?.toInt() ?? 0,
      baselineDistinctDays:
          (json['baseline_distinct_days'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Additional check-in days needed for weekly observations.
class WeeklyDaysNeeded {
  const WeeklyDaysNeeded({
    required this.week,
    required this.baseline,
  });

  final int week;
  final int baseline;

  factory WeeklyDaysNeeded.fromJson(Map<String, dynamic> json) {
    return WeeklyDaysNeeded(
      week: (json['week'] as num?)?.toInt() ?? 0,
      baseline: (json['baseline'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Personal weekly check-in observations.
class WeeklyInsights {
  const WeeklyInsights({
    required this.status,
    required this.weekStart,
    this.metrics,
    this.sampleSizes,
    this.daysNeeded,
  });

  final InsightStatus status;
  final String weekStart;
  final Map<String, WeeklyMetricComparison>? metrics;
  final WeeklySampleSizes? sampleSizes;
  final WeeklyDaysNeeded? daysNeeded;

  bool get hasSufficientData => status == InsightStatus.sufficientData;

  factory WeeklyInsights.fromJson(Map<String, dynamic> json) {
    final status = InsightStatus.fromString(
        json['status'] as String? ?? 'not_enough_data');
    final weekStart = json['week_start'] as String? ?? '';

    Map<String, WeeklyMetricComparison>? metrics;
    if (json['metrics'] is Map<String, dynamic>) {
      final m = json['metrics'] as Map<String, dynamic>;
      metrics = m.map((k, v) => MapEntry(
            k,
            WeeklyMetricComparison.fromJson(v as Map<String, dynamic>),
          ));
    }

    WeeklySampleSizes? sampleSizes;
    if (json['sample_sizes'] is Map<String, dynamic>) {
      sampleSizes = WeeklySampleSizes.fromJson(
          json['sample_sizes'] as Map<String, dynamic>);
    }

    WeeklyDaysNeeded? daysNeeded;
    if (json['days_needed'] is Map<String, dynamic>) {
      daysNeeded = WeeklyDaysNeeded.fromJson(
          json['days_needed'] as Map<String, dynamic>);
    }

    return WeeklyInsights(
      status: status,
      weekStart: weekStart,
      metrics: metrics,
      sampleSizes: sampleSizes,
      daysNeeded: daysNeeded,
    );
  }
}
