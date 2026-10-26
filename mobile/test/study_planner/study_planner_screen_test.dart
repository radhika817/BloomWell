import 'package:bloomwell/features/study_planner/application/planner_consent_notifier.dart';
import 'package:bloomwell/features/study_planner/data/study_planner_repository.dart';
import 'package:bloomwell/features/study_planner/domain/entities/personalization_info.dart';
import 'package:bloomwell/features/study_planner/domain/entities/plan_item_status.dart';
import 'package:bloomwell/features/study_planner/domain/entities/planner_cycle_consent.dart';
import 'package:bloomwell/features/study_planner/domain/entities/study_plan.dart';
import 'package:bloomwell/features/study_planner/domain/entities/study_plan_item.dart';
import 'package:bloomwell/features/study_planner/domain/entities/study_plan_mode.dart';
import 'package:bloomwell/features/study_planner/domain/entities/suggested_load.dart';
import 'package:bloomwell/features/study_planner/domain/planner_date_utils.dart';
import 'package:bloomwell/features/study_planner/presentation/study_planner_screen.dart';
import 'package:bloomwell/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePlannerRepo implements IStudyPlannerRepository {
  StudyPlan? planToReturn;
  bool generateCalled = false;
  bool replaceCalled = false;

  @override
  Future<StudyPlan> generatePlan(
      {required String weekStart, bool replace = false}) async {
    generateCalled = true;
    replaceCalled = replace;
    return planToReturn!;
  }

  @override
  Future<StudyPlan?> getCurrentPlan() async => planToReturn;

  @override
  Future<StudyPlan?> getPlanByWeek(String weekStart) async => planToReturn;

  @override
  Future<StudyPlan?> getPlanById(String id) async => planToReturn;

  @override
  Future<void> deletePlan(String id) async {
    planToReturn = null;
  }

  @override
  Future<StudyPlanItem> patchItem({
    required String itemId,
    required PlanItemStatus status,
    SuggestedLoad? suggestedLoad,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<PlannerCycleConsent> getPlannerCycleConsent() async =>
      const PlannerCycleConsent(enabled: false);

  @override
  Future<PlannerCycleConsent> updatePlannerCycleConsent(
          {required bool enabled}) async =>
      const PlannerCycleConsent(enabled: false);
}

Widget _buildTestApp(Widget child, _FakePlannerRepo fakeRepo) {
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
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StudyPlannerScreen Widget Tests', () {
    late _FakePlannerRepo fakeRepo;

    final nowMonday = PlannerDateUtils.getMondayOfWeek(DateTime.now());

    final dummyItems = List.generate(7, (index) {
      final date = nowMonday.add(Duration(days: index));
      return StudyPlanItem(
        id: 'item-$index',
        studyPlanId: 'plan-101',
        planDate: date,
        suggestedLoad:
            index % 2 == 0 ? SuggestedLoad.normal : SuggestedLoad.focus,
        reasonCodes: const ['WEEKDAY_ENERGY_HIGHER'],
        academicEventTitle: index == 2 ? 'Calculus Midterm' : null,
        status: PlanItemStatus.suggested,
        updatedAt: DateTime.now(),
      );
    });

    final defaultPlan = StudyPlan(
      id: 'plan-default',
      weekStart: nowMonday,
      days: 7,
      mode: StudyPlanMode.defaultMode,
      usesCycleData: false,
      personalization: const PersonalizationInfo(
        status: StudyPlanMode.defaultMode,
        checkinDaysUsed: 5,
        checkinDaysNeeded: 14,
      ),
      items: dummyItems,
      createdAt: DateTime.now(),
    );

    final personalizedPlan = StudyPlan(
      id: 'plan-personalized',
      weekStart: nowMonday,
      days: 7,
      mode: StudyPlanMode.personalized,
      usesCycleData: true,
      personalization: const PersonalizationInfo(
        status: StudyPlanMode.personalized,
        checkinDaysUsed: 16,
        checkinDaysNeeded: 14,
      ),
      items: dummyItems,
      createdAt: DateTime.now(),
    );

    setUp(() {
      fakeRepo = _FakePlannerRepo();
    });

    testWidgets('Renders empty intro state when no plan exists for week',
        (tester) async {
      fakeRepo.planToReturn = null;

      await tester.pumpWidget(_buildTestApp(
        const StudyPlannerScreen(),
        fakeRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Study Planner'), findsAtLeastNWidgets(1));
      expect(
          find.text(
              'Suggestions based only on what you tell us. You can change any of it.'),
          findsOneWidget);
      expect(
          find.text(
              'The planner works fully without period data using your check-ins alone.'),
          findsOneWidget);
      expect(find.text('Make my week'), findsOneWidget);
    });

    testWidgets('Tapping Make my week generates plan and displays 7 days',
        (tester) async {
      fakeRepo.planToReturn = null;

      await tester.pumpWidget(_buildTestApp(
        const StudyPlannerScreen(),
        fakeRepo,
      ));
      await tester.pumpAndSettle();

      // Now set plan to return when generate is called
      fakeRepo.planToReturn = defaultPlan;

      await tester.tap(find.text('Make my week'));
      await tester.pumpAndSettle();

      expect(fakeRepo.generateCalled, isTrue);

      // Verify default personalization banner text
      expect(
          find.text(
              "This week's plan is a simple starting point. Personalized suggestions appear after about 14 days of check-ins (you have 5)."),
          findsOneWidget);

      // Verify items render
      expect(find.text('Calculus Midterm'), findsOneWidget);
    });

    testWidgets('Personalized plan renders honest banner and period log badge',
        (tester) async {
      fakeRepo.planToReturn = personalizedPlan;

      await tester.pumpWidget(_buildTestApp(
        const StudyPlannerScreen(),
        fakeRepo,
      ));
      await tester.pumpAndSettle();

      // Check banner
      expect(find.text('Based on 16 days of your check-ins.'), findsOneWidget);

      // Check cycle data badge
      expect(find.text('Uses your period logs'), findsOneWidget);
    });
  });
}
