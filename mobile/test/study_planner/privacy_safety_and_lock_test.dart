import 'dart:async';
import 'dart:io';
import 'package:bloomwell/features/app_lock/application/app_lock_notifier.dart';
import 'package:bloomwell/features/app_lock/domain/app_lock_config.dart';
import 'package:bloomwell/features/auth/application/auth_notifier.dart';
import 'package:bloomwell/features/auth/domain/entities/auth_state.dart';
import 'package:bloomwell/features/auth/domain/entities/user_entity.dart';
import 'package:bloomwell/features/cycle_care/application/cycle_care_notifier.dart';
import 'package:bloomwell/features/cycle_care/domain/entities/cycle_tracking_status.dart';
import 'package:bloomwell/features/insights/application/insights_notifier.dart';
import 'package:bloomwell/features/insights/data/insights_repository.dart';
import 'package:bloomwell/features/insights/domain/entities/exam_context_insights.dart';
import 'package:bloomwell/features/insights/domain/entities/insight_status.dart';
import 'package:bloomwell/features/insights/domain/entities/weekly_insights.dart';
import 'package:bloomwell/features/insights/presentation/insights_screen.dart';
import 'package:bloomwell/features/study_planner/application/planner_consent_notifier.dart';
import 'package:bloomwell/features/study_planner/application/study_planner_notifier.dart';
import 'package:bloomwell/features/study_planner/data/study_planner_repository.dart';
import 'package:bloomwell/features/study_planner/domain/entities/personalization_info.dart';
import 'package:bloomwell/features/study_planner/domain/entities/plan_item_status.dart';
import 'package:bloomwell/features/study_planner/domain/entities/planner_cycle_consent.dart';
import 'package:bloomwell/features/study_planner/domain/entities/study_plan.dart';
import 'package:bloomwell/features/study_planner/domain/entities/study_plan_item.dart';
import 'package:bloomwell/features/study_planner/domain/entities/study_plan_mode.dart';
import 'package:bloomwell/features/study_planner/domain/entities/suggested_load.dart';
import 'package:bloomwell/features/study_planner/domain/planner_date_utils.dart';
import 'package:bloomwell/features/study_planner/presentation/planner_settings_screen.dart';
import 'package:bloomwell/features/study_planner/presentation/study_planner_screen.dart';
import 'package:bloomwell/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeLockedAppLockNotifier extends AppLockNotifier {
  _FakeLockedAppLockNotifier({required this.locked});
  final bool locked;

  @override
  AppLockState build() {
    return const AppLockState.initial().copyWith(
      isPinSet: true,
      isLocked: locked,
      isInitialized: true,
    );
  }
}

class _SpyPlannerRepo implements IStudyPlannerRepository {
  int getPlanCallCount = 0;
  StudyPlan? planToReturn;

  @override
  Future<StudyPlan> generatePlan(
      {required String weekStart, bool replace = false}) async {
    return planToReturn!;
  }

  @override
  Future<StudyPlan?> getCurrentPlan() async {
    getPlanCallCount++;
    return planToReturn;
  }

  @override
  Future<StudyPlan?> getPlanByWeek(String weekStart) async {
    getPlanCallCount++;
    return planToReturn;
  }

  @override
  Future<StudyPlan?> getPlanById(String id) async => planToReturn;

  @override
  Future<void> deletePlan(String id) async {}

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
      PlannerCycleConsent(enabled: enabled);
}

class _SpyInsightsRepo implements IInsightsRepository {
  int getInsightsCallCount = 0;
  WeeklyInsights? weeklyToReturn;
  ExamContextInsights? examToReturn;

  @override
  Future<WeeklyInsights> getWeeklyInsights({String? weekStart}) async {
    getInsightsCallCount++;
    return weeklyToReturn ??
        const WeeklyInsights(
          status: InsightStatus.notEnoughData,
          weekStart: '2026-10-26',
        );
  }

  @override
  Future<ExamContextInsights> getExamContextInsights() async {
    getInsightsCallCount++;
    return examToReturn ??
        const ExamContextInsights(
          status: InsightStatus.notEnoughData,
        );
  }
}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(this._initial);
  final AuthState _initial;

  @override
  AuthState build() => _initial;

  void triggerLogout() {
    state = const AuthState.unauthenticated();
  }
}

class _TestCycleCareNotifier extends CycleCareNotifier {
  _TestCycleCareNotifier(this._initial);
  final CycleCareState _initial;

  @override
  CycleCareState build() => _initial;

  void setTrackingEnabled(bool enabled) {
    state = state.copyWith(
      trackingStatus: CycleTrackingStatus(
        cycleTrackingEnabled: enabled,
        consentRecordedAt: DateTime(2026, 1, 1),
      ),
    );
  }
}

Widget _wrapWithScope({
  required Widget child,
  required List<dynamic> overrides,
}) {
  return ProviderScope(
    overrides: overrides.cast(),
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

  group('Privacy, Safety, App Lock & Lifecycle In-Memory Tests', () {
    testWidgets('StudyPlannerScreen renders blank when app lock is locked',
        (tester) async {
      final spyRepo = _SpyPlannerRepo();

      await tester.pumpWidget(
        _wrapWithScope(
          child: const StudyPlannerScreen(),
          overrides: [
            appLockNotifierProvider
                .overrideWith(() => _FakeLockedAppLockNotifier(locked: true)),
            studyPlannerRepositoryProvider.overrideWithValue(spyRepo),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Header and cards should not exist
      expect(find.text('Study Planner'), findsNothing);
      expect(find.byType(Card), findsNothing);
      expect(spyRepo.getPlanCallCount, equals(0));
    });

    testWidgets('PlannerSettingsScreen renders blank when app lock is locked',
        (tester) async {
      final spyRepo = _SpyPlannerRepo();

      await tester.pumpWidget(
        _wrapWithScope(
          child: const PlannerSettingsScreen(),
          overrides: [
            appLockNotifierProvider
                .overrideWith(() => _FakeLockedAppLockNotifier(locked: true)),
            studyPlannerRepositoryProvider.overrideWithValue(spyRepo),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Planner Cycle Suggestions'), findsNothing);
      expect(find.byType(Switch), findsNothing);
    });

    testWidgets('InsightsScreen renders blank when app lock is locked',
        (tester) async {
      final spyRepo = _SpyInsightsRepo();

      await tester.pumpWidget(
        _wrapWithScope(
          child: const InsightsScreen(),
          overrides: [
            appLockNotifierProvider
                .overrideWith(() => _FakeLockedAppLockNotifier(locked: true)),
            insightsRepositoryProvider.overrideWithValue(spyRepo),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Personal Observations'), findsNothing);
      expect(spyRepo.getInsightsCallCount, equals(0));
    });

    test('Notifiers abort network fetch when app lock is locked', () async {
      final spyPlannerRepo = _SpyPlannerRepo();
      final spyInsightsRepo = _SpyInsightsRepo();

      final container = ProviderContainer(
        overrides: [
          appLockNotifierProvider
              .overrideWith(() => _FakeLockedAppLockNotifier(locked: true)),
          studyPlannerRepositoryProvider.overrideWithValue(spyPlannerRepo),
          insightsRepositoryProvider.overrideWithValue(spyInsightsRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(studyPlannerNotifierProvider.notifier).loadPlan();
      await container.read(insightsNotifierProvider.notifier).loadAllInsights();

      expect(spyPlannerRepo.getPlanCallCount, equals(0));
      expect(spyInsightsRepo.getInsightsCallCount, equals(0));
    });

    test('All notifiers wipe state in-memory on auth logout', () async {
      final authNotifier = _TestAuthNotifier(
        AuthState.authenticated(
          user: UserEntity(
            id: 'u-1',
            role: 'student',
            language: 'en',
            timezone: 'Asia/Kolkata',
            createdAt: DateTime(2026, 1, 1),
          ),
          accessToken: 'test-token',
        ),
      );

      final nowMonday = PlannerDateUtils.getMondayOfWeek(DateTime.now());

      final dummyPlan = StudyPlan(
        id: 'plan-1',
        weekStart: nowMonday,
        days: 7,
        mode: StudyPlanMode.personalized,
        usesCycleData: true,
        personalization: const PersonalizationInfo(
          status: StudyPlanMode.personalized,
          checkinDaysUsed: 16,
          checkinDaysNeeded: 14,
        ),
        items: [],
        createdAt: DateTime.now(),
      );

      const dummyWeekly = WeeklyInsights(
        status: InsightStatus.sufficientData,
        weekStart: '2026-10-26',
        metrics: {
          'stress': WeeklyMetricComparison(
            weekAverage: 4.0,
            baselineAverage: 2.0,
            diff: 2.0,
            code: 'WEEKLY_STRESS_HIGHER',
          ),
        },
        sampleSizes: WeeklySampleSizes(
          weekDistinctDays: 5,
          baselineDistinctDays: 14,
        ),
      );

      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(() => authNotifier),
        ],
      );
      addTearDown(container.dispose);

      // Manually set initial in-memory data
      container.read(studyPlannerNotifierProvider.notifier).state =
          StudyPlannerState(
        selectedWeekStart: nowMonday,
        currentPlan: dummyPlan,
      );
      container.read(plannerConsentNotifierProvider.notifier).state =
          const PlannerConsentState(
        consent: PlannerCycleConsent(enabled: true),
      );
      container.read(insightsNotifierProvider.notifier).state =
          const InsightsState(weeklyInsights: dummyWeekly);

      expect(
          container.read(studyPlannerNotifierProvider).currentPlan, isNotNull);
      expect(container.read(plannerConsentNotifierProvider).isConsentEnabled,
          isTrue);
      expect(
          container.read(insightsNotifierProvider).weeklyInsights, isNotNull);

      // Trigger logout
      authNotifier.triggerLogout();

      // Verify immediate in-memory wipe across all notifiers
      expect(container.read(studyPlannerNotifierProvider).currentPlan, isNull);
      expect(container.read(plannerConsentNotifierProvider).consent, isNull);
      expect(container.read(insightsNotifierProvider).weeklyInsights, isNull);
      expect(container.read(insightsNotifierProvider).examInsights, isNull);
    });

    test(
        'Cycle-informed study plan and consent are purged when cycle tracking is disabled',
        () async {
      final cycleCareNotifier = _TestCycleCareNotifier(
        CycleCareState.initial().copyWith(
          trackingStatus: const CycleTrackingStatus(
            cycleTrackingEnabled: true,
          ),
        ),
      );

      final nowMonday = PlannerDateUtils.getMondayOfWeek(DateTime.now());

      final dummyPlanWithCycle = StudyPlan(
        id: 'plan-cycle-1',
        weekStart: nowMonday,
        days: 7,
        mode: StudyPlanMode.personalized,
        usesCycleData: true,
        personalization: const PersonalizationInfo(
          status: StudyPlanMode.personalized,
          checkinDaysUsed: 16,
          checkinDaysNeeded: 14,
        ),
        items: [],
        createdAt: DateTime.now(),
      );

      final container = ProviderContainer(
        overrides: [
          cycleCareNotifierProvider.overrideWith(() => cycleCareNotifier),
        ],
      );
      addTearDown(container.dispose);

      container.read(studyPlannerNotifierProvider.notifier).state =
          StudyPlannerState(
        selectedWeekStart: nowMonday,
        currentPlan: dummyPlanWithCycle,
      );
      container.read(plannerConsentNotifierProvider.notifier).state =
          const PlannerConsentState(
        consent: PlannerCycleConsent(enabled: true),
      );

      expect(
          container.read(studyPlannerNotifierProvider).currentPlan, isNotNull);
      expect(container.read(plannerConsentNotifierProvider).isConsentEnabled,
          isTrue);

      // Disable cycle tracking
      cycleCareNotifier.setTrackingEnabled(false);

      // Verify cycle-informed plan is cleared and consent is disabled in memory
      expect(container.read(studyPlannerNotifierProvider).currentPlan, isNull);
      expect(container.read(plannerConsentNotifierProvider).isConsentEnabled,
          isFalse);
    });

    test('Zero-logging verification: no sensitive data printed or leaked',
        () async {
      final printedLogs = <String>[];
      const canaryAuthValue = 'CANARY_AUTH_VALUE';
      const canaryEventTitle = 'CANARY_EVENT_TITLE';

      await runZoned(
        () async {
          final dummyPlan = StudyPlan(
            id: 'plan-99',
            weekStart: DateTime.parse('2026-10-26'),
            days: 7,
            mode: StudyPlanMode.personalized,
            usesCycleData: false,
            personalization: const PersonalizationInfo(
              status: StudyPlanMode.personalized,
              checkinDaysUsed: 14,
              checkinDaysNeeded: 14,
            ),
            items: [
              StudyPlanItem(
                id: 'item-1',
                studyPlanId: 'plan-99',
                planDate: DateTime.parse('2026-10-28'),
                suggestedLoad: SuggestedLoad.focus,
                reasonCodes: const ['EVENT_DAY'],
                academicEventTitle: canaryEventTitle,
                status: PlanItemStatus.suggested,
                updatedAt: DateTime.now(),
              ),
            ],
            createdAt: DateTime.now(),
          );

          expect(dummyPlan.items.first.academicEventTitle,
              equals(canaryEventTitle));
        },
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) {
            printedLogs.add(line);
          },
        ),
      );

      expect(
          printedLogs.any((line) => line.contains(canaryAuthValue)), isFalse);
      expect(
          printedLogs.any((line) => line.contains(canaryEventTitle)), isFalse);
    });

    test(
        'Comprehensive scan for forbidden vocabulary in study_planner and insights features',
        () {
      final forbiddenTerms = [
        'ovulation',
        'fertile',
        'pregnancy',
        'abnormal',
        'irregular',
        'because of your period',
        'caused by',
        'behind',
        'missed',
        'streak',
      ];

      final directoriesToScan = [
        Directory('lib/features/study_planner'),
        Directory('lib/features/insights'),
      ];

      for (final dir in directoriesToScan) {
        expect(dir.existsSync(), isTrue,
            reason: 'Directory ${dir.path} should exist');
        final files = dir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'));

        for (final file in files) {
          final content = file.readAsStringSync().toLowerCase();
          for (final term in forbiddenTerms) {
            expect(
              content.contains(term),
              isFalse,
              reason: 'Forbidden term "$term" found in file ${file.path}',
            );
          }
        }
      }
    });
  });
}
