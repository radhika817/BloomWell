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
import 'package:bloomwell/features/cycle_care/presentation/widgets/cycle_day_sheet.dart';
import 'package:bloomwell/features/cycle_care/presentation/widgets/period_logging_dialog.dart';
import 'package:bloomwell/l10n/app_localizations.dart';

class MockPeriodRepository implements ICycleCareRepository {
  List<CyclePeriodEntry> periods = [];
  bool createCalled = false;
  bool updateCalled = false;
  bool deleteCalled = false;
  String? lastClientId;

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
    return (items: periods, nextCursor: null, hasMore: false);
  }

  @override
  Future<CyclePeriodEntry> createPeriod({
    required String clientId,
    required String periodStart,
    String? periodEnd,
  }) async {
    createCalled = true;
    lastClientId = clientId;
    final entry = CyclePeriodEntry(
      id: 'p-new',
      clientId: clientId,
      periodStart: periodStart,
      periodEnd: periodEnd,
      cycleLengthDays: 28,
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
    updateCalled = true;
    final idx = periods.indexWhere((p) => p.id == id);
    if (idx != -1) {
      final updated = periods[idx].copyWith(
        periodStart: periodStart ?? periods[idx].periodStart,
        periodEnd: () => periodEnd,
      );
      periods[idx] = updated;
      return updated;
    }
    return CyclePeriodEntry(
      id: id,
      clientId: 'c-updated',
      periodStart: periodStart ?? '2026-10-01',
      periodEnd: periodEnd,
    );
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
  required MockPeriodRepository repository,
  double textScaleFactor = 1.0,
}) {
  return ProviderScope(
    overrides: [
      cycleCareRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(
            textScaler: TextScaler.linear(textScaleFactor),
          ),
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  group('Period Logging & Day Sheet Widget Tests', () {
    late MockPeriodRepository mockRepo;

    setUp(() {
      mockRepo = MockPeriodRepository();
    });

    testWidgets('PeriodLoggingSheet renders start date and ongoing checkbox',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestableWidget(
          repository: mockRepo,
          child: PeriodLoggingSheet(
            initialDate: DateTime(2026, 10, 10),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Log Period'), findsOneWidget);
      expect(find.text('Start date'), findsOneWidget);
      expect(find.text('2026-10-10'), findsOneWidget);
      expect(find.text('Ongoing'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('Toggling ongoing hides end date picker', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestableWidget(
          repository: mockRepo,
          child: PeriodLoggingSheet(
            initialDate: DateTime(2026, 10, 10),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('End date (optional)'), findsOneWidget);

      await tester.tap(find.byKey(const Key('cycle_period_ongoing_checkbox')));
      await tester.pumpAndSettle();

      expect(find.text('End date (optional)'), findsNothing);
    });

    testWidgets('Overlap validation displays error message', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Setup existing period from Oct 5 to Oct 9
      mockRepo.periods = [
        const CyclePeriodEntry(
          id: 'p-1',
          clientId: 'c-1',
          periodStart: '2026-10-05',
          periodEnd: '2026-10-09',
        ),
      ];

      await tester.pumpWidget(
        createTestableWidget(
          repository: mockRepo,
          child: PeriodLoggingSheet(
            initialDate: DateTime(2026, 10, 7), // overlaps with Oct 5-9
          ),
        ),
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(PeriodLoggingSheet)),
      );
      await container.read(cycleCareNotifierProvider.notifier).loadInitial();
      await tester.pumpAndSettle();

      final saveButton = find.byKey(const Key('cycle_period_save_button'));
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(
        find.text('This period overlaps with an already recorded period.'),
        findsOneWidget,
      );
      expect(mockRepo.createCalled, isFalse);
    });

    testWidgets(
        'Saving valid period calls createPeriod and preserves client_id',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestableWidget(
          repository: mockRepo,
          child: PeriodLoggingSheet(
            initialDate: DateTime(2026, 10, 10),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check ongoing to save single ongoing period
      await tester.tap(find.byKey(const Key('cycle_period_ongoing_checkbox')));
      await tester.pumpAndSettle();

      final saveButton = find.byKey(const Key('cycle_period_save_button'));
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(mockRepo.createCalled, isTrue);
      expect(mockRepo.lastClientId, isNotNull);
      expect(mockRepo.lastClientId!.length, equals(36)); // valid UUID string
    });

    testWidgets('CycleDaySheet shows period details and deletion confirmation',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final testDate = DateTime(2026, 10, 6);
      mockRepo.periods = [
        const CyclePeriodEntry(
          id: 'p-1',
          clientId: 'c-1',
          periodStart: '2026-10-05',
          periodEnd: '2026-10-09',
        ),
      ];

      await tester.pumpWidget(
        createTestableWidget(
          repository: mockRepo,
          child: CycleDaySheet(
            date: testDate,
            onLogSymptom: () {},
          ),
        ),
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(CycleDaySheet)),
      );
      await container.read(cycleCareNotifierProvider.notifier).loadInitial();
      await tester.pumpAndSettle();

      expect(find.text('Period logged'), findsOneWidget);
      expect(find.textContaining('2026-10-05 to 2026-10-09'), findsOneWidget);

      // Tap delete button
      final deleteBtn = find.byKey(const Key('cycle_day_delete_period_button'));
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Verify confirmation dialog
      expect(find.text('Delete period'), findsWidgets);
      expect(
        find.text('Delete this period log? This action cannot be undone.'),
        findsOneWidget,
      );

      // Confirm deletion
      await tester
          .tap(find.byKey(const Key('cycle_delete_period_confirm_button')));
      await tester.pumpAndSettle();

      expect(mockRepo.deleteCalled, isTrue);
    });

    testWidgets('Renders properly under 200% accessibility text scale',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestableWidget(
          repository: mockRepo,
          textScaleFactor: 2.0,
          child: PeriodLoggingSheet(
            initialDate: DateTime(2026, 10, 10),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Log Period'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
