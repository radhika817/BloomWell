import 'cycle_estimate.dart';
import 'cycle_period_entry.dart';

/// Domain entity representing cycle history and current server-computed estimate.
class CycleHistoryInsight {
  const CycleHistoryInsight({
    required this.recentCycles,
    required this.estimate,
  });

  final List<CyclePeriodEntry> recentCycles;
  final CycleEstimate estimate;

  factory CycleHistoryInsight.fromJson(Map<String, dynamic> json) {
    final cyclesRaw = json['recent_cycles'] as List<dynamic>? ?? [];
    final recentCycles = cyclesRaw
        .map((c) => CyclePeriodEntry.fromJson(c as Map<String, dynamic>))
        .toList();

    final estimateRaw = json['estimate'] as Map<String, dynamic>? ?? {};
    final estimate = CycleEstimate.fromJson(estimateRaw);

    return CycleHistoryInsight(
      recentCycles: recentCycles,
      estimate: estimate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recent_cycles': recentCycles.map((c) => c.toJson()).toList(),
      'estimate': estimate.toJson(),
    };
  }
}
