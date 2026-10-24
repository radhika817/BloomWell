import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloomwell/features/cycle_care/application/cycle_care_notifier.dart';
import 'package:bloomwell/features/cycle_care/data/cycle_care_repository.dart';
import 'package:bloomwell/features/cycle_care/domain/entities/cycle_estimate.dart';
import 'package:bloomwell/features/cycle_care/domain/entities/cycle_history_insight.dart';
import 'package:bloomwell/features/cycle_care/domain/entities/cycle_period_entry.dart';
import 'package:bloomwell/features/cycle_care/domain/entities/cycle_symptom_entry.dart';
import 'package:bloomwell/features/cycle_care/domain/entities/cycle_tracking_status.dart';
import 'package:bloomwell/features/cycle_care/presentation/widgets/cycle_estimate_card.dart';
import 'package:bloomwell/features/cycle_care/presentation/widgets/cycle_history_list.dart';
import 'package:bloomwell/l10n/app_localizations.dart';

class MockEstimateAndHistoryRepository implements ICycleCareRepository {
  List<CyclePeriodEntry> periods = [];
  bool deleteCalled = false;
  bool paginateCalled = false;

  @override
  Future<CycleTrackingStatus> getCycleTrackingStatus() async {
    return const CycleTrackingStatus(cycleTrackingEnabled: true);
  }

  @override
  Future<CycleTrackingStatus> updateCycleTracking({
    required bool enabled,
    bool deleteData = false,
  }) async {
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
    if (cursor == 'page-2') {
      paginateCalled = true;
      return (
        items: const [
          CyclePeriodEntry(
            id: 'p-3',
            clientId: 'c-3',
            periodStart: '2026-07-01',
            periodEnd: '2026-07-05',
          ),
        ],
        nextCursor: null,
        hasMore: false,
      );
    }
    return (
      items: periods,
      nextCursor: periods.length >= 2 ? 'page-2' : null,
      hasMore: periods.length >= 2,
    );
  }

  @override
  Future<CyclePeriodEntry> createPeriod({
    required String clientId,
    required String periodStart,
    String? periodEnd,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<CyclePeriodEntry> updatePeriod({
    required String id,
    String? periodStart,
    String? periodEnd,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deletePeriod(String id) async {
    deleteCalled = true;
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
    return (items: <CycleSymptomEntry>[], nextCursor: null, hasMore: false);
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
    throw UnimplementedError();
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
    throw UnimplementedError();
  }

  @override
  Future<void> deleteSymptom(String id) async {}

  @override
  Future<CycleHistoryInsight> getCycleHistoryInsight() async {
    return const CycleHistoryInsight(
      estimate: CycleEstimate(status: CycleEstimateStatus.notEnoughData),
      recentCycles: [],
    );
  }
}

Widget createTestableWidget({
  required Widget child,
  MockEstimateAndHistoryRepository? repository,
  double textScaleFactor = 1.0,
}) {
  final repo = repository ?? MockEstimateAndHistoryRepository();
  return ProviderScope(
    overrides: [
      cycleCareRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: SingleChildScrollView(
          child: MediaQuery(
            data: MediaQueryData(
              textScaler: TextScaler.linear(textScaleFactor),
            ),
            child: child,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('CycleEstimateCard Widget Tests', () {
    testWidgets('Renders not_enough_data status with prominent disclaimer',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const notEnough = CycleEstimate(
        status: CycleEstimateStatus.notEnoughData,
        neededCycles: 3,
      );

      await tester.pumpWidget(
        createTestableWidget(
          child: const CycleEstimateCard(estimate: notEnough),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cycle Observation'), findsOneWidget);
      expect(find.text('Estimate'), findsOneWidget);
      expect(
        find.text(
          'Log a few more periods to see an estimate (3 more needed).',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'This is an estimate and can be wrong. It is not medical advice.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Renders too_variable status with disclaimer', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const variable = CycleEstimate(
        status: CycleEstimateStatus.tooVariable,
        cyclesCounted: 4,
      );

      await tester.pumpWidget(
        createTestableWidget(
          child: const CycleEstimateCard(estimate: variable),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Your logged cycles vary too much for a useful estimate.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'This is an estimate and can be wrong. It is not medical advice.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Renders estimate range and typical length with disclaimer',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const estimate = CycleEstimate(
        status: CycleEstimateStatus.estimate,
        estimatedRangeStart: '2026-11-02',
        estimatedRangeEnd: '2026-11-06',
        typicalCycleLengthDays: 28,
        cyclesCounted: 4,
      );

      await tester.pumpWidget(
        createTestableWidget(
          child: const CycleEstimateCard(estimate: estimate),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Next period expected around 2026-11-02 to 2026-11-06.'),
        findsOneWidget,
      );
      expect(
        find.text(
            'Typical length: 28 days · Based on your last 4 logged cycles.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'This is an estimate and can be wrong. It is not medical advice.',
        ),
        findsOneWidget,
      );
    });
  });

  group('CycleHistoryList Widget Tests', () {
    late MockEstimateAndHistoryRepository mockRepo;

    setUp(() {
      mockRepo = MockEstimateAndHistoryRepository();
    });

    testWidgets('Renders empty state when history is empty', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestableWidget(
          repository: mockRepo,
          child: const CycleHistoryList(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Recorded Cycles'), findsOneWidget);
      expect(
        find.text(
          'No cycles recorded yet. Your logged periods will appear here.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Renders recorded cycles, ongoing badge, and allows deletion',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      mockRepo.periods = [
        const CyclePeriodEntry(
          id: 'p-1',
          clientId: 'c-1',
          periodStart: '2026-10-01',
          periodEnd: '2026-10-05',
          cycleLengthDays: 28,
        ),
        const CyclePeriodEntry(
          id: 'p-2',
          clientId: 'c-2',
          periodStart: '2026-10-24', // ongoing
        ),
      ];

      await tester.pumpWidget(
        createTestableWidget(
          repository: mockRepo,
          child: const CycleHistoryList(),
        ),
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(CycleHistoryList)),
      );
      await container.read(cycleCareNotifierProvider.notifier).loadInitial();
      await tester.pumpAndSettle();

      expect(find.text('2026-10-01 – 2026-10-05'), findsOneWidget);
      expect(find.text('Started 2026-10-24'), findsOneWidget);
      expect(find.text('Ongoing'), findsOneWidget);
      expect(find.text('Bleeding: 5 days'), findsOneWidget);
      expect(find.text('Cycle: 28 days'), findsOneWidget);

      // Tap delete on first entry
      final deleteBtn = find.byKey(const Key('cycle_history_delete_p-1'));
      await tester.ensureVisible(deleteBtn);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      expect(find.text('Delete period'), findsWidgets);

      // Confirm
      await tester.tap(find.byKey(const Key('cycle_history_delete_confirm')));
      await tester.pumpAndSettle();

      expect(mockRepo.deleteCalled, isTrue);
    });

    testWidgets('Pagination button loads more cycles', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      mockRepo.periods = [
        const CyclePeriodEntry(
          id: 'p-1',
          clientId: 'c-1',
          periodStart: '2026-10-01',
          periodEnd: '2026-10-05',
        ),
        const CyclePeriodEntry(
          id: 'p-2',
          clientId: 'c-2',
          periodStart: '2026-09-01',
          periodEnd: '2026-09-05',
        ),
      ];

      await tester.pumpWidget(
        createTestableWidget(
          repository: mockRepo,
          child: const CycleHistoryList(),
        ),
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(CycleHistoryList)),
      );
      await container.read(cycleCareNotifierProvider.notifier).loadInitial();
      await tester.pumpAndSettle();

      final loadMoreBtn =
          find.byKey(const Key('cycle_history_load_more_button'));
      expect(loadMoreBtn, findsOneWidget);

      await tester.ensureVisible(loadMoreBtn);
      await tester.tap(loadMoreBtn);
      await tester.pumpAndSettle();

      expect(mockRepo.paginateCalled, isTrue);
    });

    testWidgets('Renders properly under 200% accessibility text scale',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestableWidget(
          textScaleFactor: 2.0,
          child: const CycleEstimateCard(
            estimate: CycleEstimate(
              status: CycleEstimateStatus.estimate,
              estimatedRangeStart: '2026-11-02',
              estimatedRangeEnd: '2026-11-06',
              typicalCycleLengthDays: 28,
              cyclesCounted: 4,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cycle Observation'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
