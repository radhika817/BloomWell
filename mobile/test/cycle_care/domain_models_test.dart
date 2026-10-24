import 'package:bloomwell/features/cycle_care/domain/entities/cycle_estimate.dart';
import 'package:bloomwell/features/cycle_care/domain/entities/cycle_history_insight.dart';
import 'package:bloomwell/features/cycle_care/domain/entities/cycle_period_entry.dart';
import 'package:bloomwell/features/cycle_care/domain/entities/cycle_symptom_entry.dart';
import 'package:bloomwell/features/cycle_care/domain/entities/cycle_tracking_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CycleCare Domain Entities Tests', () {
    test('CycleTrackingStatus JSON serialization and copyWith', () {
      final now = DateTime.utc(2026, 10, 24, 12, 0);
      final status = CycleTrackingStatus(
        cycleTrackingEnabled: true,
        consentRecordedAt: now,
      );

      final json = status.toJson();
      expect(json['cycle_tracking_enabled'], isTrue);
      expect(json['consent_recorded_at'], equals(now.toIso8601String()));

      final parsed = CycleTrackingStatus.fromJson(json);
      expect(parsed.cycleTrackingEnabled, isTrue);
      expect(parsed.consentRecordedAt, equals(now));

      final disabled = status.copyWith(cycleTrackingEnabled: false);
      expect(disabled.cycleTrackingEnabled, isFalse);
      expect(disabled.consentRecordedAt, equals(now));
    });

    test('CyclePeriodEntry duration, ongoing, and JSON handling', () {
      const entry = CyclePeriodEntry(
        id: 'p-1',
        clientId: 'c-1',
        periodStart: '2026-10-01',
        periodEnd: '2026-10-05',
        cycleLengthDays: 28,
      );

      expect(entry.isOngoing, isFalse);
      expect(entry.durationDays, equals(5));

      final json = entry.toJson();
      expect(json['period_start'], equals('2026-10-01'));
      expect(json['period_end'], equals('2026-10-05'));
      expect(json['cycle_length_days'], equals(28));

      const ongoing = CyclePeriodEntry(
        id: 'p-2',
        clientId: 'c-2',
        periodStart: '2026-10-24',
      );
      expect(ongoing.isOngoing, isTrue);
      expect(ongoing.durationDays, isNull);

      final parsed = CyclePeriodEntry.fromJson(ongoing.toJson());
      expect(parsed.id, equals('p-2'));
      expect(parsed.periodStart, equals('2026-10-24'));
      expect(parsed.periodEnd, isNull);
    });

    test('CycleSymptomEntry types, severity, notes, and custom labels', () {
      const symptom = CycleSymptomEntry(
        id: 's-1',
        clientId: 'cs-1',
        date: '2026-10-24',
        symptomType: CycleSymptomType.backPain,
        severity: 4,
        notes: 'Mild discomfort while sitting',
      );

      expect(symptom.symptomType.apiValue, equals('back_pain'));
      expect(symptom.severity, equals(4));

      final json = symptom.toJson();
      expect(json['symptom_type'], equals('back_pain'));
      expect(json['notes'], equals('Mild discomfort while sitting'));

      final parsed = CycleSymptomEntry.fromJson(json);
      expect(parsed.symptomType, equals(CycleSymptomType.backPain));
      expect(parsed.severity, equals(4));

      const custom = CycleSymptomEntry(
        id: 's-2',
        clientId: 'cs-2',
        date: '2026-10-24',
        symptomType: CycleSymptomType.other,
        customLabel: 'Mild tension',
        severity: 2,
      );
      expect(custom.customLabel, equals('Mild tension'));
      expect(
          CycleSymptomType.fromString('other'), equals(CycleSymptomType.other));
      expect(CycleSymptomType.fromString('unknown_type'),
          equals(CycleSymptomType.other));
    });

    test('CycleEstimate statuses, range check, and history insight', () {
      const notEnough = CycleEstimate(
        status: CycleEstimateStatus.notEnoughData,
        neededCycles: 3,
        cyclesCounted: 1,
      );
      expect(notEnough.hasEstimateRange, isFalse);
      expect(notEnough.status, equals(CycleEstimateStatus.notEnoughData));

      const tooVariable = CycleEstimate(
        status: CycleEstimateStatus.tooVariable,
        cyclesCounted: 4,
        explanation: 'Cycles vary too much for a reliable estimate',
      );
      expect(tooVariable.hasEstimateRange, isFalse);
      expect(tooVariable.status, equals(CycleEstimateStatus.tooVariable));

      const estimate = CycleEstimate(
        status: CycleEstimateStatus.estimate,
        typicalCycleLengthDays: 28,
        cyclesCounted: 4,
        estimatedRangeStart: '2026-11-12',
        estimatedRangeEnd: '2026-11-16',
      );
      expect(estimate.hasEstimateRange, isTrue);

      const insight = CycleHistoryInsight(
        recentCycles: [
          CyclePeriodEntry(
            id: 'p-1',
            clientId: 'c-1',
            periodStart: '2026-10-01',
            periodEnd: '2026-10-05',
          ),
        ],
        estimate: estimate,
      );

      final insightJson = insight.toJson();
      final parsedInsight = CycleHistoryInsight.fromJson(insightJson);
      expect(parsedInsight.recentCycles.length, equals(1));
      expect(parsedInsight.estimate.hasEstimateRange, isTrue);
      expect(parsedInsight.estimate.typicalCycleLengthDays, equals(28));
    });
  });
}
