import 'package:bloomwell/features/cycle_care/application/cycle_care_notifier.dart';
import 'package:bloomwell/features/cycle_care/data/cycle_care_repository.dart';
import 'package:bloomwell/features/cycle_care/domain/entities/cycle_estimate.dart';
import 'package:bloomwell/features/cycle_care/domain/entities/cycle_history_insight.dart';
import 'package:bloomwell/features/cycle_care/domain/entities/cycle_period_entry.dart';
import 'package:bloomwell/features/cycle_care/domain/entities/cycle_symptom_entry.dart';
import 'package:bloomwell/features/cycle_care/domain/entities/cycle_tracking_status.dart';
import 'package:bloomwell/features/cycle_care/presentation/cycle_care_opt_in_screen.dart';
import 'package:bloomwell/features/cycle_care/presentation/cycle_care_screen.dart';
import 'package:bloomwell/features/cycle_care/presentation/widgets/cycle_estimate_card.dart';
import 'package:bloomwell/features/cycle_care/presentation/widgets/cycle_history_list.dart';
import 'package:bloomwell/features/cycle_care/presentation/widgets/cycle_month_calendar.dart';
import 'package:bloomwell/features/cycle_care/presentation/widgets/period_logging_dialog.dart';
import 'package:bloomwell/features/cycle_care/presentation/widgets/symptom_logging_sheet.dart';
import 'package:bloomwell/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockCycleCareRepository implements ICycleCareRepository {
  bool enabled = false;
  bool deleteDataCalled = false;
  List<CyclePeriodEntry> storedPeriods = [];
  List<CycleSymptomEntry> storedSymptoms = [];
  CycleEstimate? storedEstimate;
  List<CyclePeriodEntry> storedRecentCycles = [];

  @override
  Future<CycleTrackingStatus> getCycleTrackingStatus() async {
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
    return (
      items: storedPeriods,
      nextCursor: null,
      hasMore: false,
    );
  }

  @override
  Future<CyclePeriodEntry> createPeriod({
    required String clientId,
    required String periodStart,
    String? periodEnd,
  }) async {
    final entry = CyclePeriodEntry(
      id: 'p-new',
      clientId: clientId,
      periodStart: periodStart,
      periodEnd: periodEnd,
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
    return CyclePeriodEntry(
      id: id,
      clientId: 'c-updated',
      periodStart: periodStart ?? '2026-10-01',
      periodEnd: periodEnd,
    );
  }

  @override
  Future<void> deletePeriod(String id) async {
    storedPeriods.removeWhere((e) => e.id == id);
  }

  @override
  Future<({List<CycleSymptomEntry> items, String? nextCursor, bool hasMore})>
      getSymptoms({
    String? fromDate,
    String? toDate,
    String? cursor,
    int limit = 50,
  }) async {
    return (
      items: storedSymptoms,
      nextCursor: null,
      hasMore: false,
    );
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
    final entry = CycleSymptomEntry(
      id: 's-new',
      clientId: clientId,
      date: date,
      symptomType: symptomType,
      severity: severity,
      customLabel: customLabel,
      notes: notes,
      createdAt: DateTime.now().toUtc(),
    );
    storedSymptoms.add(entry);
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
    return CycleSymptomEntry(
      id: id,
      clientId: 's-edit',
      date: date ?? '2026-10-01',
      symptomType: symptomType ?? CycleSymptomType.cramps,
      severity: severity ?? 2,
      customLabel: customLabel,
      notes: notes,
      createdAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<void> deleteSymptom(String id) async {
    storedSymptoms.removeWhere((e) => e.id == id);
  }

  @override
  Future<CycleHistoryInsight> getCycleHistoryInsight() async {
    return CycleHistoryInsight(
      estimate: storedEstimate ??
          const CycleEstimate(status: CycleEstimateStatus.notEnoughData),
      recentCycles: storedRecentCycles,
    );
  }
}

Widget createScreenTestWidget({
  required MockCycleCareRepository repo,
  double textScaleFactor = 1.0,
}) {
  return ProviderScope(
    overrides: [
      cycleCareRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: MediaQuery(
        data: MediaQueryData(
          textScaler: TextScaler.linear(textScaleFactor),
          size: const Size(800, 1200),
        ),
        child: const CycleCareScreen(),
      ),
    ),
  );
}

void main() {
  late MockCycleCareRepository repo;

  setUp(() {
    repo = MockCycleCareRepository();
  });

  testWidgets('Renders opt-in screen when tracking is disabled',
      (tester) async {
    repo.enabled = false;

    await tester.pumpWidget(createScreenTestWidget(repo: repo));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(CycleCareOptInScreen), findsOneWidget);
    expect(find.byType(CycleMonthCalendar), findsNothing);
  });

  testWidgets(
      'Renders calendar, estimate card, history list, and settings when tracking is enabled',
      (tester) async {
    repo.enabled = true;
    repo.storedEstimate = const CycleEstimate(
      status: CycleEstimateStatus.estimate,
      estimatedRangeStart: '2026-11-01',
      estimatedRangeEnd: '2026-11-05',
      typicalCycleLengthDays: 28,
      cyclesCounted: 4,
    );

    await tester.pumpWidget(createScreenTestWidget(repo: repo));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(CycleCareOptInScreen), findsNothing);
    expect(find.byType(CycleMonthCalendar), findsOneWidget);
    expect(find.byType(CycleEstimateCard), findsOneWidget);
    expect(find.byType(CycleHistoryList), findsOneWidget);
    expect(find.byKey(const Key('cycle_care_settings_button')), findsOneWidget);
    expect(
        find.byKey(const Key('cycle_quick_log_period_button')), findsOneWidget);
    expect(find.byKey(const Key('cycle_quick_log_symptom_button')),
        findsOneWidget);
  });

  testWidgets('Settings sheet allows turning off tracking and keeping data',
      (tester) async {
    repo.enabled = true;

    await tester.pumpWidget(createScreenTestWidget(repo: repo));
    await tester.pump();
    await tester.pumpAndSettle();

    // Open settings sheet
    await tester.tap(find.byKey(const Key('cycle_care_settings_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('cycle_settings_keep_data_button')),
        findsOneWidget);
    expect(find.byKey(const Key('cycle_settings_delete_data_button')),
        findsOneWidget);

    // Tap keep data option
    await tester.tap(find.byKey(const Key('cycle_settings_keep_data_button')));
    await tester.pumpAndSettle();

    expect(repo.enabled, false);
    expect(repo.deleteDataCalled, false);
    expect(find.byType(CycleCareOptInScreen), findsOneWidget);
  });

  testWidgets(
      'Settings sheet allows turning off tracking and deleting data with confirmation',
      (tester) async {
    repo.enabled = true;

    await tester.pumpWidget(createScreenTestWidget(repo: repo));
    await tester.pump();
    await tester.pumpAndSettle();

    // Open settings sheet
    await tester.tap(find.byKey(const Key('cycle_care_settings_button')));
    await tester.pumpAndSettle();

    // Tap delete data option
    await tester
        .tap(find.byKey(const Key('cycle_settings_delete_data_button')));
    await tester.pumpAndSettle();

    // Verify confirmation dialog appears
    expect(
        find.byKey(const Key('cycle_confirm_delete_button')), findsOneWidget);

    // Confirm deletion
    await tester.tap(find.byKey(const Key('cycle_confirm_delete_button')));
    await tester.pumpAndSettle();

    expect(repo.enabled, false);
    expect(repo.deleteDataCalled, true);
    expect(find.byType(CycleCareOptInScreen), findsOneWidget);
  });

  testWidgets('Tapping quick log buttons opens period and symptom sheets',
      (tester) async {
    repo.enabled = true;

    await tester.pumpWidget(createScreenTestWidget(repo: repo));
    await tester.pump();
    await tester.pumpAndSettle();

    // Tap Quick Log Period
    await tester.tap(find.byKey(const Key('cycle_quick_log_period_button')));
    await tester.pumpAndSettle();

    expect(find.byType(PeriodLoggingSheet), findsOneWidget);

    // Close sheet
    await tester.tap(find.byKey(const Key('cycle_period_close_button')));
    await tester.pumpAndSettle();

    // Tap Quick Log Symptom
    await tester.tap(find.byKey(const Key('cycle_quick_log_symptom_button')));
    await tester.pumpAndSettle();

    expect(find.byType(SymptomLoggingSheet), findsOneWidget);
  });

  testWidgets('Supports 200% text scaling without layout overflow',
      (tester) async {
    repo.enabled = true;
    repo.storedEstimate = const CycleEstimate(
      status: CycleEstimateStatus.estimate,
      estimatedRangeStart: '2026-11-01',
      estimatedRangeEnd: '2026-11-05',
      typicalCycleLengthDays: 28,
      cyclesCounted: 4,
    );

    await tester.pumpWidget(
      createScreenTestWidget(repo: repo, textScaleFactor: 2.0),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(CycleCareScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
