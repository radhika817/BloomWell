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
import 'package:bloomwell/features/cycle_care/presentation/cycle_care_opt_in_screen.dart';
import 'package:bloomwell/l10n/app_localizations.dart';

class MockOptInRepository implements ICycleCareRepository {
  bool enableSuccess = true;
  bool enableCalled = false;

  @override
  Future<CycleTrackingStatus> getCycleTrackingStatus() async {
    return const CycleTrackingStatus(cycleTrackingEnabled: false);
  }

  @override
  Future<CycleTrackingStatus> updateCycleTracking({
    required bool enabled,
    bool deleteData = false,
  }) async {
    enableCalled = true;
    if (!enableSuccess) {
      throw Exception('Server unavailable');
    }
    return CycleTrackingStatus(
      cycleTrackingEnabled: enabled,
      consentRecordedAt: DateTime.utc(2026, 10, 24),
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
    return (items: <CyclePeriodEntry>[], nextCursor: null, hasMore: false);
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
  Future<void> deletePeriod(String id) async {}

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
  required MockOptInRepository repository,
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
      home: MediaQuery(
        data: MediaQueryData(
          textScaler: TextScaler.linear(textScaleFactor),
        ),
        child: child,
      ),
    ),
  );
}

void main() {
  group('CycleCareOptInScreen Widget Tests', () {
    late MockOptInRepository mockRepo;

    setUp(() {
      mockRepo = MockOptInRepository();
    });

    testWidgets('Renders all plain-language disclosures and buttons',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestableWidget(
          repository: mockRepo,
          child: const CycleCareOptInScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CycleCare · Optional Body Rhythm'), findsOneWidget);
      expect(
        find.text('A private, voluntary space to notice your natural cycles.'),
        findsOneWidget,
      );
      expect(find.text('Your privacy & how this works'), findsOneWidget);

      // Verify disclosures
      expect(find.textContaining('What is stored'), findsOneWidget);
      expect(find.textContaining('Estimates are suggestions'), findsOneWidget);
      expect(find.textContaining('Not medical advice'), findsOneWidget);
      expect(find.textContaining('Always your choice'), findsOneWidget);

      // Verify buttons
      expect(find.text('Turn on cycle tracking'), findsOneWidget);
      expect(find.text('Not now'), findsOneWidget);

      // Verify minimum tap target size (48x48)
      final enableButtonFinder =
          find.byKey(const Key('cycle_opt_in_enable_button'));
      final notNowButtonFinder =
          find.byKey(const Key('cycle_opt_in_not_now_button'));
      expect(
        tester.getSize(enableButtonFinder).height,
        greaterThanOrEqualTo(48.0),
      );
      expect(
        tester.getSize(notNowButtonFinder).height,
        greaterThanOrEqualTo(48.0),
      );
    });

    testWidgets('Tapping Not now triggers onNotNow callback', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      bool notNowCalled = false;
      await tester.pumpWidget(
        createTestableWidget(
          repository: mockRepo,
          child: CycleCareOptInScreen(
            onNotNow: () => notNowCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final notNowBtn = find.byKey(const Key('cycle_opt_in_not_now_button'));
      await tester.ensureVisible(notNowBtn);
      await tester.tap(notNowBtn);
      await tester.pumpAndSettle();

      expect(notNowCalled, isTrue);
    });

    testWidgets('Tapping Turn on cycle tracking calls enable and onOptedIn',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      bool optedInCalled = false;
      await tester.pumpWidget(
        createTestableWidget(
          repository: mockRepo,
          child: CycleCareOptInScreen(
            onOptedIn: () => optedInCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final enableBtn = find.byKey(const Key('cycle_opt_in_enable_button'));
      await tester.ensureVisible(enableBtn);
      await tester.tap(enableBtn);
      await tester.pumpAndSettle();

      expect(mockRepo.enableCalled, isTrue);
      expect(optedInCalled, isTrue);
    });

    testWidgets('Displays error banner when enable fails', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      mockRepo.enableSuccess = false;

      await tester.pumpWidget(
        createTestableWidget(
          repository: mockRepo,
          child: const CycleCareOptInScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final enableBtn = find.byKey(const Key('cycle_opt_in_enable_button'));
      await tester.ensureVisible(enableBtn);
      await tester.tap(enableBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('Failed to enable tracking. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('Renders properly under 200% accessibility text scale',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestableWidget(
          repository: mockRepo,
          textScaleFactor: 2.0,
          child: const CycleCareOptInScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CycleCare · Optional Body Rhythm'), findsOneWidget);
      expect(find.text('Turn on cycle tracking'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
