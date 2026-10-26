import 'package:bloomwell/core/api/api_exceptions.dart';
import 'package:bloomwell/features/auth/application/auth_notifier.dart';
import 'package:bloomwell/features/auth/domain/entities/auth_state.dart';
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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeStudyPlannerRepository implements IStudyPlannerRepository {
  StudyPlan? planToReturn;
  bool throwPlanExists = false;
  bool throwCycleTrackingRequired = false;
  PlannerCycleConsent consentToReturn =
      const PlannerCycleConsent(enabled: false);
  bool deleteCalled = false;
  StudyPlanItem? patchedItemToReturn;

  @override
  Future<StudyPlan> generatePlan(
      {required String weekStart, bool replace = false}) async {
    if (throwPlanExists) {
      throw const PlanExistsException();
    }
    if (throwCycleTrackingRequired) {
      throw const CycleTrackingRequiredException();
    }
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
    deleteCalled = true;
    planToReturn = null;
  }

  @override
  Future<StudyPlanItem> patchItem({
    required String itemId,
    required PlanItemStatus status,
    SuggestedLoad? suggestedLoad,
  }) async {
    if (patchedItemToReturn != null) {
      return patchedItemToReturn!;
    }
    return StudyPlanItem(
      id: itemId,
      studyPlanId: 'p-1',
      planDate: DateTime(2026, 11, 2),
      suggestedLoad: suggestedLoad ?? SuggestedLoad.normal,
      reasonCodes: const ['WEEKDAY_ENERGY_HIGHER'],
      status: status,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<PlannerCycleConsent> getPlannerCycleConsent() async => consentToReturn;

  @override
  Future<PlannerCycleConsent> updatePlannerCycleConsent(
      {required bool enabled}) async {
    if (throwCycleTrackingRequired) {
      throw const CycleTrackingRequiredException();
    }
    consentToReturn = PlannerCycleConsent(
      enabled: enabled,
      deletedCyclePlansCount: enabled ? 0 : 2,
    );
    return consentToReturn;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StudyPlannerNotifier and PlannerConsentNotifier Tests', () {
    late _FakeStudyPlannerRepository fakeRepo;
    late ProviderContainer container;

    final dummyPlan = StudyPlan(
      id: 'plan-1',
      weekStart: DateTime(2026, 11, 2),
      days: 7,
      mode: StudyPlanMode.personalized,
      usesCycleData: true,
      personalization: const PersonalizationInfo(
        status: StudyPlanMode.personalized,
        checkinDaysUsed: 15,
        checkinDaysNeeded: 14,
      ),
      items: [
        StudyPlanItem(
          id: 'item-1',
          studyPlanId: 'plan-1',
          planDate: DateTime(2026, 11, 2),
          suggestedLoad: SuggestedLoad.focus,
          reasonCodes: const ['WEEKDAY_ENERGY_HIGHER'],
          status: PlanItemStatus.suggested,
          updatedAt: DateTime(2026, 10, 26),
        ),
        StudyPlanItem(
          id: 'item-2',
          studyPlanId: 'plan-1',
          planDate: DateTime(2026, 11, 3),
          suggestedLoad: SuggestedLoad.normal,
          reasonCodes: const ['DEFAULT_PLAN'],
          status: PlanItemStatus.suggested,
          updatedAt: DateTime(2026, 10, 26),
        ),
      ],
      createdAt: DateTime(2026, 10, 26),
    );

    setUp(() {
      fakeRepo = _FakeStudyPlannerRepository();
      container = ProviderContainer(
        overrides: [
          studyPlannerRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state has no plan and device-local Monday', () {
      final state = container.read(studyPlannerNotifierProvider);
      expect(state.hasPlan, isFalse);
      expect(state.currentPlan, isNull);
      expect(state.selectedWeekStart.weekday, equals(DateTime.monday));
    });

    test('loadPlan fetches plan from repository and sets state', () async {
      fakeRepo.planToReturn = dummyPlan;

      final notifier = container.read(studyPlannerNotifierProvider.notifier);
      await notifier.loadPlan(weekStart: DateTime(2026, 11, 2));

      final state = container.read(studyPlannerNotifierProvider);
      expect(state.hasPlan, isTrue);
      expect(state.currentPlan?.id, equals('plan-1'));
      expect(state.currentPlan?.items.length, equals(2));
    });

    test('generatePlan handles 409 plan_exists cleanly without crash',
        () async {
      fakeRepo.throwPlanExists = true;

      final notifier = container.read(studyPlannerNotifierProvider.notifier);
      final ok = await notifier.generatePlan(weekStart: DateTime(2026, 11, 2));

      expect(ok, isFalse);
      final state = container.read(studyPlannerNotifierProvider);
      expect(state.conflictPlanExists, isTrue);
    });

    test('generatePlan handles 409 cycle_tracking_required cleanly', () async {
      fakeRepo.throwCycleTrackingRequired = true;

      final notifier = container.read(studyPlannerNotifierProvider.notifier);
      final ok = await notifier.generatePlan(weekStart: DateTime(2026, 11, 2));

      expect(ok, isFalse);
      final state = container.read(studyPlannerNotifierProvider);
      expect(state.cycleTrackingRequired, isTrue);
    });

    test('patchItem updates item in state strictly on server confirmation',
        () async {
      fakeRepo.planToReturn = dummyPlan;
      final notifier = container.read(studyPlannerNotifierProvider.notifier);
      await notifier.loadPlan(weekStart: DateTime(2026, 11, 2));

      fakeRepo.patchedItemToReturn = dummyPlan.items[0].copyWith(
        status: PlanItemStatus.edited,
        suggestedLoad: SuggestedLoad.light,
      );

      final result = await notifier.patchItem(
        itemId: 'item-1',
        status: PlanItemStatus.edited,
        suggestedLoad: SuggestedLoad.light,
      );

      expect(result, isNotNull);
      final state = container.read(studyPlannerNotifierProvider);
      final updated =
          state.currentPlan?.items.firstWhere((i) => i.id == 'item-1');
      expect(updated?.status, equals(PlanItemStatus.edited));
      expect(updated?.suggestedLoad, equals(SuggestedLoad.light));
    });

    test('deletePlan removes plan from memory on server confirmation',
        () async {
      fakeRepo.planToReturn = dummyPlan;
      final notifier = container.read(studyPlannerNotifierProvider.notifier);
      await notifier.loadPlan(weekStart: DateTime(2026, 11, 2));
      expect(container.read(studyPlannerNotifierProvider).hasPlan, isTrue);

      final ok = await notifier.deletePlan('plan-1');
      expect(ok, isTrue);
      expect(fakeRepo.deleteCalled, isTrue);
      expect(container.read(studyPlannerNotifierProvider).hasPlan, isFalse);
      expect(container.read(studyPlannerNotifierProvider).currentPlan, isNull);
    });

    test('PlannerConsentNotifier loads and updates consent', () async {
      fakeRepo.consentToReturn =
          const PlannerCycleConsent(enabled: false, deletedCyclePlansCount: 0);

      final consentNotifier =
          container.read(plannerConsentNotifierProvider.notifier);
      await consentNotifier.loadConsent();

      expect(container.read(plannerConsentNotifierProvider).isConsentEnabled,
          isFalse);

      final deleted = await consentNotifier.updateConsent(enabled: true);
      expect(deleted, equals(0));
      expect(container.read(plannerConsentNotifierProvider).isConsentEnabled,
          isTrue);
    });

    test('In-memory isolation: clearAllData purges all state in memory',
        () async {
      fakeRepo.planToReturn = dummyPlan;
      final notifier = container.read(studyPlannerNotifierProvider.notifier);
      await notifier.loadPlan(weekStart: DateTime(2026, 11, 2));
      expect(container.read(studyPlannerNotifierProvider).hasPlan, isTrue);

      notifier.clearAllData();
      final state = container.read(studyPlannerNotifierProvider);
      expect(state.hasPlan, isFalse);
      expect(state.currentPlan, isNull);
    });

    test(
        'Privacy boundary: Auth unauthenticated purges planner and consent data',
        () async {
      fakeRepo.planToReturn = dummyPlan;
      final plannerNotifier =
          container.read(studyPlannerNotifierProvider.notifier);
      await plannerNotifier.loadPlan(weekStart: DateTime(2026, 11, 2));
      expect(container.read(studyPlannerNotifierProvider).hasPlan, isTrue);

      final consentNotifier =
          container.read(plannerConsentNotifierProvider.notifier);
      await consentNotifier.updateConsent(enabled: true);
      expect(container.read(plannerConsentNotifierProvider).isConsentEnabled,
          isTrue);

      // Simulate logout
      container.read(authNotifierProvider.notifier).state =
          const AuthState.unauthenticated();

      expect(container.read(studyPlannerNotifierProvider).hasPlan, isFalse);
      expect(container.read(plannerConsentNotifierProvider).isConsentEnabled,
          isFalse);
    });
  });
}
