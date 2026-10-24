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
import 'package:bloomwell/features/cycle_care/presentation/widgets/symptom_logging_sheet.dart';
import 'package:bloomwell/l10n/app_localizations.dart';

class MockSymptomRepository implements ICycleCareRepository {
  List<CycleSymptomEntry> symptoms = [];
  bool createCalled = false;
  String? lastClientId;
  CycleSymptomType? lastType;
  int? lastSeverity;
  String? lastCustomLabel;
  String? lastNotes;

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
    createCalled = true;
    lastClientId = clientId;
    lastType = symptomType;
    lastSeverity = severity;
    lastCustomLabel = customLabel;
    lastNotes = notes;

    final entry = CycleSymptomEntry(
      id: 's-new',
      clientId: clientId,
      date: date,
      symptomType: symptomType,
      severity: severity,
      customLabel: customLabel,
      notes: notes,
    );
    symptoms.add(entry);
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
  required MockSymptomRepository repository,
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
  group('SymptomLoggingSheet Widget & Guardrail Tests', () {
    late MockSymptomRepository mockRepo;

    setUp(() {
      mockRepo = MockSymptomRepository();
    });

    testWidgets('Renders all 12 symptom chips and neutral severity selector',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestableWidget(
          repository: mockRepo,
          child: const SymptomLoggingSheet(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Log Symptoms'), findsOneWidget);
      expect(find.text('What are you noticing?'), findsOneWidget);

      // Verify all 12 symptom chips exist
      for (final type in CycleSymptomType.values) {
        expect(
          find.byKey(Key('cycle_symptom_chip_${type.apiValue}')),
          findsOneWidget,
        );
      }

      // Default severity is 2 (mild)
      expect(find.text('Severity: Mild'), findsOneWidget);
      expect(find.text('0 / 500'), findsOneWidget);

      // Clinic advice prompt should NOT be visible for severity 2
      expect(
        find.textContaining('talking to a doctor or nurse can help'),
        findsNothing,
      );
    });

    testWidgets('Selecting severity 4 or 5 displays gentle clinic prompt',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestableWidget(
          repository: mockRepo,
          child: const SymptomLoggingSheet(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap severity 4 pill
      final pill4 = find.byKey(const Key('cycle_severity_pill_4'));
      await tester.ensureVisible(pill4);
      await tester.tap(pill4);
      await tester.pumpAndSettle();

      expect(find.text('Severity: Strong'), findsOneWidget);
      expect(
        find.text(
          'If symptoms feel severe or worrying, talking to a doctor or nurse can help.',
        ),
        findsOneWidget,
      );

      // Tap severity 5 pill
      final pill5 = find.byKey(const Key('cycle_severity_pill_5'));
      await tester.ensureVisible(pill5);
      await tester.tap(pill5);
      await tester.pumpAndSettle();

      expect(find.text('Severity: Very strong'), findsOneWidget);
      expect(
        find.text(
          'If symptoms feel severe or worrying, talking to a doctor or nurse can help.',
        ),
        findsOneWidget,
      );

      // Revert to severity 3
      final pill3 = find.byKey(const Key('cycle_severity_pill_3'));
      await tester.ensureVisible(pill3);
      await tester.tap(pill3);
      await tester.pumpAndSettle();

      expect(find.text('Severity: Moderate'), findsOneWidget);
      expect(
        find.textContaining('talking to a doctor or nurse can help'),
        findsNothing,
      );
    });

    testWidgets('Selecting Other shows custom symptom name text input',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestableWidget(
          repository: mockRepo,
          child: const SymptomLoggingSheet(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('cycle_custom_label_input')), findsNothing);

      final otherChip = find.byKey(const Key('cycle_symptom_chip_other'));
      await tester.ensureVisible(otherChip);
      await tester.tap(otherChip);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('cycle_custom_label_input')),
        findsOneWidget,
      );
    });

    testWidgets('Live notes counter updates and saving invokes repository',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestableWidget(
          repository: mockRepo,
          child: const SymptomLoggingSheet(),
        ),
      );
      await tester.pumpAndSettle();

      // Enter notes
      final notesInput = find.byKey(const Key('cycle_symptom_notes_input'));
      await tester.ensureVisible(notesInput);
      await tester.enterText(notesInput, 'Feeling tired after exams');
      await tester.pumpAndSettle();

      expect(find.text('25 / 500'), findsOneWidget);

      // Tap Save
      final saveBtn = find.byKey(const Key('cycle_symptom_save_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(mockRepo.createCalled, isTrue);
      expect(mockRepo.lastType, equals(CycleSymptomType.cramps));
      expect(mockRepo.lastSeverity, equals(2));
      expect(mockRepo.lastNotes, equals('Feeling tired after exams'));
      expect(mockRepo.lastClientId, isNotNull);
      expect(mockRepo.lastClientId!.length, equals(36));
    });

    testWidgets('Renders properly under 200% accessibility text scale',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(450, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestableWidget(
          repository: mockRepo,
          textScaleFactor: 2.0,
          child: const SymptomLoggingSheet(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Log Symptoms'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
