import 'dart:async';
import 'package:bloomwell/core/api/api_exceptions.dart';
import 'package:bloomwell/features/auth/application/auth_notifier.dart';
import 'package:bloomwell/features/cycle_care/application/cycle_care_notifier.dart';
import 'package:bloomwell/features/cycle_care/data/cycle_care_repository.dart';
import 'package:bloomwell/features/cycle_care/domain/entities/cycle_estimate.dart';
import 'package:bloomwell/features/cycle_care/domain/entities/cycle_history_insight.dart';
import 'package:bloomwell/features/cycle_care/domain/entities/cycle_period_entry.dart';
import 'package:bloomwell/features/cycle_care/domain/entities/cycle_symptom_entry.dart';
import 'package:bloomwell/features/cycle_care/domain/entities/cycle_tracking_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const canaryNotes = 'CANARY_SENSITIVE_JOURNAL_NOTES_SECRET_12345';
const canaryCustomLabel = 'CANARY_SENSITIVE_CUSTOM_LABEL_SECRET_67890';
const canaryPeriodStart = '2026-10-15';
const canaryPeriodEnd = '2026-10-20';
const canaryClientId = 'CANARY_CLIENT_ID_SECRET_ABCDE';

class ZeroLoggingCanaryRepository implements ICycleCareRepository {
  bool enabled = true;
  bool shouldThrowError = false;
  List<CyclePeriodEntry> periods = [];
  List<CycleSymptomEntry> symptoms = [];

  @override
  Future<CycleTrackingStatus> getCycleTrackingStatus() async {
    return CycleTrackingStatus(
      cycleTrackingEnabled: enabled,
      consentRecordedAt: DateTime.utc(2026, 10, 1),
    );
  }

  @override
  Future<CycleTrackingStatus> updateCycleTracking({
    required bool enabled,
    bool deleteData = false,
  }) async {
    this.enabled = enabled;
    if (deleteData) {
      periods.clear();
      symptoms.clear();
    }
    return CycleTrackingStatus(cycleTrackingEnabled: enabled);
  }

  @override
  Future<({List<CyclePeriodEntry> items, String? nextCursor, bool hasMore})>
      getCycles({
    String? fromDate,
    String? toDate,
    String? cursor,
    int limit = 20,
  }) async {
    if (shouldThrowError) {
      throw const ServerException(message: 'Internal server error');
    }
    return (items: periods, nextCursor: null, hasMore: false);
  }

  @override
  Future<CyclePeriodEntry> createPeriod({
    required String clientId,
    required String periodStart,
    String? periodEnd,
  }) async {
    if (shouldThrowError) {
      throw const ServerException(message: 'Server error while saving');
    }
    final entry = CyclePeriodEntry(
      id: 'p-canary',
      clientId: clientId,
      periodStart: periodStart,
      periodEnd: periodEnd,
    );
    periods.add(entry);
    return entry;
  }

  @override
  Future<CyclePeriodEntry> updatePeriod({
    required String id,
    String? periodStart,
    String? periodEnd,
  }) async {
    if (shouldThrowError) {
      throw const ServerException(message: 'Server error while updating');
    }
    final entry = CyclePeriodEntry(
      id: id,
      clientId: canaryClientId,
      periodStart: periodStart ?? canaryPeriodStart,
      periodEnd: periodEnd ?? canaryPeriodEnd,
    );
    return entry;
  }

  @override
  Future<void> deletePeriod(String id) async {
    if (shouldThrowError) {
      throw const ServerException(message: 'Server error while deleting');
    }
    periods.removeWhere((p) => p.id == id);
  }

  @override
  Future<({List<CycleSymptomEntry> items, String? nextCursor, bool hasMore})>
      getSymptoms({
    String? fromDate,
    String? toDate,
    String? cursor,
    int limit = 50,
  }) async {
    if (shouldThrowError) {
      throw const ServerException(message: 'Failed to fetch symptoms');
    }
    return (items: symptoms, nextCursor: null, hasMore: false);
  }

  @override
  Future<CycleSymptomEntry> createSymptom({
    required String clientId,
    required String date,
    required CycleSymptomType symptomType,
    required int severity,
    String? customLabel,
    String? notes,
  }) async {
    if (shouldThrowError) {
      throw const ServerException(message: 'Server error while saving symptom');
    }
    final entry = CycleSymptomEntry(
      id: 's-canary',
      clientId: clientId,
      date: date,
      symptomType: symptomType,
      severity: severity,
      customLabel: customLabel,
      notes: notes,
      createdAt: DateTime.now().toUtc(),
    );
    symptoms.add(entry);
    return entry;
  }

  @override
  Future<CycleSymptomEntry> updateSymptom({
    required String id,
    String? date,
    CycleSymptomType? symptomType,
    int? severity,
    String? customLabel,
    String? notes,
  }) async {
    if (shouldThrowError) {
      throw const ServerException(
          message: 'Server error while updating symptom');
    }
    return CycleSymptomEntry(
      id: id,
      clientId: canaryClientId,
      date: date ?? '2026-10-15',
      symptomType: symptomType ?? CycleSymptomType.other,
      severity: severity ?? 3,
      customLabel: customLabel,
      notes: notes,
      createdAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<void> deleteSymptom(String id) async {
    if (shouldThrowError) {
      throw const ServerException(
          message: 'Server error while deleting symptom');
    }
    symptoms.removeWhere((s) => s.id == id);
  }

  @override
  Future<CycleHistoryInsight> getCycleHistoryInsight() async {
    return const CycleHistoryInsight(
      estimate: CycleEstimate(status: CycleEstimateStatus.notEnoughData),
      recentCycles: [],
    );
  }
}

void main() {
  late ZeroLoggingCanaryRepository repo;
  late ProviderContainer container;
  final List<String> capturedPrintLogs = [];

  setUp(() {
    repo = ZeroLoggingCanaryRepository();
    capturedPrintLogs.clear();

    container = ProviderContainer(
      overrides: [
        cycleCareRepositoryProvider.overrideWithValue(repo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test(
      'Zero-logging: Canary notes, custom labels, and dates are never logged or leaked',
      () async {
    await runZoned(
      () async {
        final notifier = container.read(cycleCareNotifierProvider.notifier);

        // 1. Initial load
        await notifier.loadInitial();

        // 2. Log period with canary dates
        final periodSuccess = await notifier.logPeriod(
          clientId: canaryClientId,
          startDate: DateTime(2026, 10, 15),
          endDate: DateTime(2026, 10, 20),
        );
        expect(periodSuccess, true);

        // 3. Log symptom with canary notes and custom label
        final symptomSuccess = await notifier.logSymptom(
          clientId: canaryClientId,
          date: DateTime(2026, 10, 15),
          symptomType: CycleSymptomType.other,
          severity: 4,
          customLabel: canaryCustomLabel,
          notes: canaryNotes,
        );
        expect(symptomSuccess, true);

        // 4. Update period
        await notifier.updatePeriod(
          id: 'p-canary',
          startDate: DateTime(2026, 10, 15),
          endDate: DateTime(2026, 10, 21),
        );

        // 5. Trigger errors to test exception error messages
        repo.shouldThrowError = true;

        await notifier.logPeriod(
          clientId: canaryClientId,
          startDate: DateTime(2026, 10, 15),
        );
        final stateAfterPeriodError = container.read(cycleCareNotifierProvider);
        expect(stateAfterPeriodError.errorMessage, isNotNull);
        expect(
          stateAfterPeriodError.errorMessage!.contains(canaryClientId),
          false,
        );
        expect(
          stateAfterPeriodError.errorMessage!.contains(canaryPeriodStart),
          false,
        );

        await notifier.logSymptom(
          clientId: canaryClientId,
          date: DateTime(2026, 10, 15),
          symptomType: CycleSymptomType.other,
          severity: 3,
          customLabel: canaryCustomLabel,
          notes: canaryNotes,
        );
        final stateAfterSymptomError =
            container.read(cycleCareNotifierProvider);
        expect(stateAfterSymptomError.errorMessage, isNotNull);
        expect(
          stateAfterSymptomError.errorMessage!.contains(canaryNotes),
          false,
        );
        expect(
          stateAfterSymptomError.errorMessage!.contains(canaryCustomLabel),
          false,
        );

        // Delete operations
        repo.shouldThrowError = false;
        await notifier.deletePeriod('p-canary');
        await notifier.deleteSymptom('s-canary');
      },
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) {
          capturedPrintLogs.add(line);
        },
      ),
    );

    // Verify zero occurrences of sensitive canary data in all stdout/logs
    final combinedLogs = capturedPrintLogs.join('\n');
    expect(combinedLogs.contains(canaryNotes), false,
        reason: 'Sensitive symptom notes leaked into print logs');
    expect(combinedLogs.contains(canaryCustomLabel), false,
        reason: 'Sensitive symptom custom label leaked into print logs');
    expect(combinedLogs.contains(canaryClientId), false,
        reason: 'Sensitive client ID leaked into print logs');
    expect(combinedLogs.contains('2026-10-15'), false,
        reason: 'Sensitive cycle date leaked into print logs');
  });

  test(
      'In-memory data isolation: Sensitive data is immediately purged on logout',
      () async {
    final notifier = container.read(cycleCareNotifierProvider.notifier);
    await notifier.loadInitial();

    await notifier.logPeriod(
      clientId: canaryClientId,
      startDate: DateTime(2026, 10, 15),
      endDate: DateTime(2026, 10, 20),
    );

    await notifier.logSymptom(
      clientId: canaryClientId,
      date: DateTime(2026, 10, 15),
      symptomType: CycleSymptomType.other,
      severity: 4,
      customLabel: canaryCustomLabel,
      notes: canaryNotes,
    );

    var currentState = container.read(cycleCareNotifierProvider);
    expect(currentState.monthCycles.isNotEmpty, true);
    expect(currentState.monthSymptoms.isNotEmpty, true);

    // Trigger user session expiry / logout
    container.read(authNotifierProvider.notifier).handleSessionExpired();

    // Verify state was completely wiped from memory
    final purgedState = container.read(cycleCareNotifierProvider);
    expect(purgedState.monthCycles, isEmpty);
    expect(purgedState.monthSymptoms, isEmpty);
    expect(purgedState.historyCycles, isEmpty);
    expect(purgedState.recentCycles, isEmpty);
    expect(purgedState.estimate, isNull);
    expect(purgedState.trackingStatus, isNull);
  });
}
