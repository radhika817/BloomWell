import 'package:bloomwell/features/study_planner/application/planner_consent_notifier.dart';
import 'package:bloomwell/features/study_planner/data/study_planner_repository.dart';
import 'package:bloomwell/features/study_planner/domain/entities/plan_item_status.dart';
import 'package:bloomwell/features/study_planner/domain/entities/planner_cycle_consent.dart';
import 'package:bloomwell/features/study_planner/domain/entities/study_plan.dart';
import 'package:bloomwell/features/study_planner/domain/entities/study_plan_item.dart';
import 'package:bloomwell/features/study_planner/domain/entities/suggested_load.dart';
import 'package:bloomwell/features/study_planner/presentation/widgets/study_plan_day_sheet.dart';
import 'package:bloomwell/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePlannerRepository implements IStudyPlannerRepository {
  PlanItemStatus? lastStatus;
  SuggestedLoad? lastSuggestedLoad;

  @override
  Future<StudyPlan> generatePlan(
          {required String weekStart, bool replace = false}) async =>
      throw UnimplementedError();

  @override
  Future<StudyPlan?> getCurrentPlan() async => null;

  @override
  Future<StudyPlan?> getPlanByWeek(String weekStart) async => null;

  @override
  Future<StudyPlan?> getPlanById(String id) async => null;

  @override
  Future<void> deletePlan(String id) async {}

  @override
  Future<StudyPlanItem> patchItem({
    required String itemId,
    required PlanItemStatus status,
    SuggestedLoad? suggestedLoad,
  }) async {
    lastStatus = status;
    lastSuggestedLoad = suggestedLoad;
    return StudyPlanItem(
      id: itemId,
      studyPlanId: 'p-1',
      planDate: DateTime(2026, 10, 20),
      suggestedLoad: suggestedLoad ?? SuggestedLoad.normal,
      reasonCodes: const ['WEEKDAY_ENERGY_HIGHER'],
      status: status,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<PlannerCycleConsent> getPlannerCycleConsent() async =>
      const PlannerCycleConsent(enabled: false);

  @override
  Future<PlannerCycleConsent> updatePlannerCycleConsent(
          {required bool enabled}) async =>
      const PlannerCycleConsent(enabled: false);
}

Widget _buildTestApp(Widget child, _FakePlannerRepository fakeRepo) {
  return ProviderScope(
    overrides: [
      studyPlannerRepositoryProvider.overrideWithValue(fakeRepo),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StudyPlanDaySheet Tests', () {
    late _FakePlannerRepository fakeRepo;
    late StudyPlanItem sampleItem;

    setUp(() {
      fakeRepo = _FakePlannerRepository();
      sampleItem = StudyPlanItem(
        id: 'item-1',
        studyPlanId: 'p-1',
        planDate: DateTime(2026, 10, 20),
        suggestedLoad: SuggestedLoad.normal,
        reasonCodes: const ['WEEKDAY_ENERGY_HIGHER'],
        status: PlanItemStatus.suggested,
        updatedAt: DateTime(2026, 10, 19),
      );
    });

    testWidgets('Renders why this suggestion, reason code, and action buttons',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        StudyPlanDaySheet(item: sampleItem),
        fakeRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Why this suggestion?'), findsOneWidget);
      expect(
          find.text(
              "You've often logged higher energy on this day of the week."),
          findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('Accept action triggers patchItem and shows confirmation',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        Builder(builder: (ctx) {
          return ElevatedButton(
            onPressed: () => StudyPlanDaySheet.show(ctx, sampleItem),
            child: const Text('Open Sheet'),
          );
        }),
        fakeRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();

      expect(fakeRepo.lastStatus, equals(PlanItemStatus.accepted));
      expect(find.text('Day accepted'), findsOneWidget);
    });

    testWidgets('Change action displays all 3 loads and updates on selection',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        Builder(builder: (ctx) {
          return ElevatedButton(
            onPressed: () => StudyPlanDaySheet.show(ctx, sampleItem),
            child: const Text('Open Sheet'),
          );
        }),
        fakeRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Change'));
      await tester.pumpAndSettle();

      // All 3 loads are displayed
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Normal'), findsAtLeastNWidgets(1));
      expect(find.text('Focus'), findsOneWidget);

      // Select Focus
      await tester.tap(find.text('Focus'));
      await tester.pumpAndSettle();

      expect(fakeRepo.lastStatus, equals(PlanItemStatus.edited));
      expect(fakeRepo.lastSuggestedLoad, equals(SuggestedLoad.focus));
      expect(find.text('Day updated'), findsOneWidget);
    });

    testWidgets('Skip action triggers patchItem and shows confirmation',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        Builder(builder: (ctx) {
          return ElevatedButton(
            onPressed: () => StudyPlanDaySheet.show(ctx, sampleItem),
            child: const Text('Open Sheet'),
          );
        }),
        fakeRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(fakeRepo.lastStatus, equals(PlanItemStatus.skipped));
      expect(find.text('Day skipped'), findsOneWidget);
    });
  });
}
