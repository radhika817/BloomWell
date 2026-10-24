import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloomwell/core/api/api_exceptions.dart';
import 'package:bloomwell/features/auth/application/auth_notifier.dart';
import 'package:bloomwell/features/cycle_care/application/cycle_care_notifier.dart';
import 'package:bloomwell/features/cycle_care/data/cycle_care_repository.dart';
import 'package:bloomwell/features/cycle_care/domain/entities/cycle_estimate.dart';
import 'package:bloomwell/features/cycle_care/domain/entities/cycle_history_insight.dart';
import 'package:bloomwell/features/cycle_care/domain/entities/cycle_period_entry.dart';
import 'package:bloomwell/features/cycle_care/domain/entities/cycle_symptom_entry.dart';
import 'package:bloomwell/features/cycle_care/domain/entities/cycle_tracking_status.dart';

class FakeCycleCareRepository implements ICycleCareRepository {
  bool enabled = false;
  bool throw403 = false;
  bool deleteDataCalled = false;
  List<CyclePeriodEntry> storedPeriods = [];
  List<CycleSymptomEntry> storedSymptoms = [];
  CycleEstimate? storedEstimate;
  List<CyclePeriodEntry> storedRecentCycles = [];

  @override
  Future<CycleTrackingStatus> getCycleTrackingStatus() async {
    if (throw403) {
      throw const CycleTrackingDisabledException();
    }
    return CycleTrackingStatus(
      cycleTrackingEnabled: enabled,
      consentRecordedAt: enabled ? DateTime.utc(2026, 10, 1) : null,
    );
  }

  @override
  Future<CycleTrackingStatus> updateCycleTracking({
    required bool enabled,
    bool deleteData = false,
  }) async {
    this.enabled = enabled;
    if (deleteData) {
      deleteDataCalled = true;
      storedPeriods.clear();
      storedSymptoms.clear();
      storedEstimate = null;
    }
    return CycleTrackingStatus(
      cycleTrackingEnabled: enabled,
      consentRecordedAt: enabled ? DateTime.utc(2026, 10, 1) : null,
    );
  }

  @override
  Future<({List<CyclePeriodEntry> items, String? nextCursor, bool hasMore})>
      getCycles({
    String? fromDate,
    String? toDate,
    String? cursor,
    int limit = 20,
  }) async {
    if (!enabled) throw const CycleTrackingDisabledException();
    if (cursor == 'page-2') {
      return (
        items: const [
          CyclePeriodEntry(
            id: 'c-3',
            clientId: 'client-3',
            periodStart: '2026-08-01',
            periodEnd: '2026-08-05',
            cycleLengthDays: 28,
          ),
        ],
        nextCursor: null,
        hasMore: false,
      );
    }
    return (
      items: storedPeriods,
      nextCursor: storedPeriods.length > 1 ? 'page-2' : null,
      hasMore: storedPeriods.length > 1,
    );
  }

  @override
  Future<CyclePeriodEntry> createPeriod({
    required String clientId,
    required String periodStart,
    String? periodEnd,
  }) async {
    if (!enabled) throw const CycleTrackingDisabledException();
    final entry = CyclePeriodEntry(
      id: 'c-${storedPeriods.length + 1}',
      clientId: clientId,
      periodStart: periodStart,
      periodEnd: periodEnd,
      cycleLengthDays: 28,
    );
    storedPeriods.insert(0, entry);
    return entry;
  }

  @override
  Future<CyclePeriodEntry> updatePeriod({
    required String id,
    String? periodStart,
    String? periodEnd,
  }) async {
    if (!enabled) throw const CycleTrackingDisabledException();
    final idx = storedPeriods.indexWhere((p) => p.id == id);
    final updated = storedPeriods[idx].copyWith(
      periodStart: periodStart ?? storedPeriods[idx].periodStart,
      periodEnd: () => periodEnd,
    );
    storedPeriods[idx] = updated;
    return updated;
  }

  @override
  Future<void> deletePeriod(String id) async {
    if (!enabled) throw const CycleTrackingDisabledException();
    storedPeriods.removeWhere((p) => p.id == id);
  }

  @override
  Future<({List<CycleSymptomEntry> items, String? nextCursor, bool hasMore})>
      getSymptoms({
    String? fromDate,
    String? toDate,
    String? cursor,
    int limit = 50,
  }) async {
    if (!enabled) throw const CycleTrackingDisabledException();
    return (items: storedSymptoms, nextCursor: null, hasMore: false);
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
    if (!enabled) throw const CycleTrackingDisabledException();
    final entry = CycleSymptomEntry(
      id: 's-${storedSymptoms.length + 1}',
      clientId: clientId,
      date: date,
      symptomType: symptomType,
      severity: severity,
      customLabel: customLabel,
      notes: notes,
    );
    storedSymptoms.add(entry);
    return entry;
  }

  @override
  Future<CycleSymptomEntry> updateSymptom({
    required String id,
    String? date,
    CycleSymptomType? symptomType,
    String? customLabel,
    int? severity,
    String? notes,
  }) async {
    if (!enabled) throw const CycleTrackingDisabledException();
    final idx = storedSymptoms.indexWhere((s) => s.id == id);
    final updated = storedSymptoms[idx].copyWith(
      date: date ?? storedSymptoms[idx].date,
      symptomType: symptomType ?? storedSymptoms[idx].symptomType,
      customLabel: customLabel != null ? () => customLabel : null,
      severity: severity ?? storedSymptoms[idx].severity,
      notes: notes != null ? () => notes : null,
    );
    storedSymptoms[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteSymptom(String id) async {
    if (!enabled) throw const CycleTrackingDisabledException();
    storedSymptoms.removeWhere((s) => s.id == id);
  }

  @override
  Future<CycleHistoryInsight> getCycleHistoryInsight() async {
    if (!enabled) throw const CycleTrackingDisabledException();
    return CycleHistoryInsight(
      estimate: storedEstimate ??
          const CycleEstimate(status: CycleEstimateStatus.notEnoughData),
      recentCycles: storedRecentCycles,
    );
  }
}

void main() {
  group('CycleCareNotifier State & Isolation Tests', () {
    late FakeCycleCareRepository fakeRepo;
    late ProviderContainer container;

    setUp(() {
      fakeRepo = FakeCycleCareRepository();
      container = ProviderContainer(
        overrides: [
          cycleCareRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state is un-opted-in with empty in-memory records', () {
      final state = container.read(cycleCareNotifierProvider);
      expect(state.isTrackingEnabled, false);
      expect(state.monthCycles, isEmpty);
      expect(state.monthSymptoms, isEmpty);
      expect(state.historyCycles, isEmpty);
      expect(state.estimate, isNull);
      expect(state.calendarViewMode, CalendarViewMode.grid);
    });

    test(
        'loadInitial when disabled preserves un-opted-in state without queries',
        () async {
      fakeRepo.enabled = false;
      await container.read(cycleCareNotifierProvider.notifier).loadInitial();

      final state = container.read(cycleCareNotifierProvider);
      expect(state.isTrackingEnabled, false);
      expect(state.isLoading, false);
      expect(state.monthCycles, isEmpty);
    });

    test('HTTP 403 gracefully marks tracking as disabled and resets state',
        () async {
      fakeRepo.throw403 = true;
      await container.read(cycleCareNotifierProvider.notifier).loadInitial();

      final state = container.read(cycleCareNotifierProvider);
      expect(state.isTrackingEnabled, false);
      expect(state.isLoading, false);
      expect(state.monthCycles, isEmpty);
    });

    test('enableTracking enables feature and loads month data and estimates',
        () async {
      fakeRepo.enabled = false;
      fakeRepo.storedPeriods = [
        const CyclePeriodEntry(
          id: 'c-1',
          clientId: 'client-1',
          periodStart: '2026-10-05',
          periodEnd: '2026-10-10',
          cycleLengthDays: 28,
        ),
      ];
      fakeRepo.storedEstimate = const CycleEstimate(
        status: CycleEstimateStatus.estimate,
        estimatedRangeStart: '2026-11-02',
        estimatedRangeEnd: '2026-11-06',
        typicalCycleLengthDays: 28,
      );

      final ok = await container
          .read(cycleCareNotifierProvider.notifier)
          .enableTracking();
      expect(ok, true);

      final state = container.read(cycleCareNotifierProvider);
      expect(state.isTrackingEnabled, true);
      expect(state.monthCycles.length, 1);
      expect(state.estimate?.status, CycleEstimateStatus.estimate);
    });

    test('disableTracking with deleteData purges server and local memory',
        () async {
      fakeRepo.enabled = true;
      fakeRepo.storedPeriods = [
        const CyclePeriodEntry(
          id: 'c-1',
          clientId: 'client-1',
          periodStart: '2026-10-05',
        ),
      ];

      final ok = await container
          .read(cycleCareNotifierProvider.notifier)
          .disableTracking(deleteData: true);
      expect(ok, true);
      expect(fakeRepo.deleteDataCalled, true);

      final state = container.read(cycleCareNotifierProvider);
      expect(state.isTrackingEnabled, false);
      expect(state.monthCycles, isEmpty);
      expect(state.estimate, isNull);
    });

    test('Strict In-Memory Isolation: logout wipes all sensitive cycle data',
        () async {
      // Setup authenticated state and load cycle data
      fakeRepo.enabled = true;
      fakeRepo.storedPeriods = [
        const CyclePeriodEntry(
          id: 'c-1',
          clientId: 'client-1',
          periodStart: '2026-10-05',
        ),
      ];
      fakeRepo.storedSymptoms = [
        const CycleSymptomEntry(
          id: 's-1',
          clientId: 'client-s1',
          date: '2026-10-05',
          symptomType: CycleSymptomType.cramps,
          severity: 3,
        ),
      ];

      await container.read(cycleCareNotifierProvider.notifier).loadInitial();
      expect(
        container.read(cycleCareNotifierProvider).monthCycles.length,
        1,
      );
      expect(
        container.read(cycleCareNotifierProvider).monthSymptoms.length,
        1,
      );

      // Simulate Auth transition to unauthenticated (e.g. session expired or logout)
      container.read(authNotifierProvider.notifier).handleSessionExpired();

      // Verify that all sensitive cycle and symptom entries are completely erased
      final wipedState = container.read(cycleCareNotifierProvider);
      expect(wipedState.monthCycles, isEmpty);
      expect(wipedState.monthSymptoms, isEmpty);
      expect(wipedState.historyCycles, isEmpty);
      expect(wipedState.estimate, isNull);
      expect(wipedState.trackingStatus, isNull);
    });

    test('logPeriod, updatePeriod, and deletePeriod modify in-memory state',
        () async {
      fakeRepo.enabled = true;
      await container.read(cycleCareNotifierProvider.notifier).loadInitial();

      // Log period
      final logged =
          await container.read(cycleCareNotifierProvider.notifier).logPeriod(
                clientId: 'client-p1',
                startDate: DateTime(2026, 10, 5),
                endDate: DateTime(2026, 10, 9),
              );
      expect(logged, true);
      expect(
        container.read(cycleCareNotifierProvider).monthCycles.length,
        1,
      );

      final periodId =
          container.read(cycleCareNotifierProvider).monthCycles.first.id;

      // Update period
      final updated =
          await container.read(cycleCareNotifierProvider.notifier).updatePeriod(
                id: periodId,
                startDate: DateTime(2026, 10, 6),
                endDate: DateTime(2026, 10, 10),
              );
      expect(updated, true);
      expect(
        container.read(cycleCareNotifierProvider).monthCycles.first.periodStart,
        '2026-10-06',
      );

      // Delete period
      final deleted = await container
          .read(cycleCareNotifierProvider.notifier)
          .deletePeriod(periodId);
      expect(deleted, true);
      expect(container.read(cycleCareNotifierProvider).monthCycles, isEmpty);
    });

    test('logSymptom and deleteSymptom update month symptoms', () async {
      fakeRepo.enabled = true;
      await container.read(cycleCareNotifierProvider.notifier).loadInitial();

      final logged =
          await container.read(cycleCareNotifierProvider.notifier).logSymptom(
                clientId: 'client-sym-1',
                date: DateTime(2026, 10, 8),
                symptomType: CycleSymptomType.headache,
                severity: 4,
                notes: 'Resting with hydration',
              );
      expect(logged, true);
      expect(
        container.read(cycleCareNotifierProvider).monthSymptoms.length,
        1,
      );

      final symptomId =
          container.read(cycleCareNotifierProvider).monthSymptoms.first.id;

      final deleted = await container
          .read(cycleCareNotifierProvider.notifier)
          .deleteSymptom(symptomId);
      expect(deleted, true);
      expect(container.read(cycleCareNotifierProvider).monthSymptoms, isEmpty);
    });

    test('History pagination loads next page and appends', () async {
      fakeRepo.enabled = true;
      fakeRepo.storedPeriods = [
        const CyclePeriodEntry(
          id: 'c-1',
          clientId: 'client-1',
          periodStart: '2026-10-05',
          periodEnd: '2026-10-10',
        ),
        const CyclePeriodEntry(
          id: 'c-2',
          clientId: 'client-2',
          periodStart: '2026-09-07',
          periodEnd: '2026-09-12',
        ),
      ];

      await container.read(cycleCareNotifierProvider.notifier).loadInitial();
      expect(
        container.read(cycleCareNotifierProvider).historyCycles.length,
        2,
      );
      expect(container.read(cycleCareNotifierProvider).hasMoreHistory, true);

      await container
          .read(cycleCareNotifierProvider.notifier)
          .loadMoreHistory();
      expect(
        container.read(cycleCareNotifierProvider).historyCycles.length,
        3,
      );
      expect(container.read(cycleCareNotifierProvider).hasMoreHistory, false);
    });

    test('toggleViewMode switches between grid and list', () {
      final notifier = container.read(cycleCareNotifierProvider.notifier);
      expect(
        container.read(cycleCareNotifierProvider).calendarViewMode,
        CalendarViewMode.grid,
      );

      notifier.toggleViewMode();
      expect(
        container.read(cycleCareNotifierProvider).calendarViewMode,
        CalendarViewMode.list,
      );

      notifier.toggleViewMode();
      expect(
        container.read(cycleCareNotifierProvider).calendarViewMode,
        CalendarViewMode.grid,
      );
    });
  });
}
