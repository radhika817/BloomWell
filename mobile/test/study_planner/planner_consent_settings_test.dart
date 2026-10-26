import 'package:bloomwell/features/cycle_care/application/cycle_care_notifier.dart';
import 'package:bloomwell/features/cycle_care/domain/entities/cycle_tracking_status.dart';
import 'package:bloomwell/features/study_planner/application/planner_consent_notifier.dart';
import 'package:bloomwell/features/study_planner/data/study_planner_repository.dart';
import 'package:bloomwell/features/study_planner/domain/entities/plan_item_status.dart';
import 'package:bloomwell/features/study_planner/domain/entities/planner_cycle_consent.dart';
import 'package:bloomwell/features/study_planner/domain/entities/study_plan.dart';
import 'package:bloomwell/features/study_planner/domain/entities/study_plan_item.dart';
import 'package:bloomwell/features/study_planner/domain/entities/suggested_load.dart';
import 'package:bloomwell/features/study_planner/presentation/planner_settings_screen.dart';
import 'package:bloomwell/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSettingsRepo implements IStudyPlannerRepository {
  PlannerCycleConsent consent =
      const PlannerCycleConsent(enabled: false, deletedCyclePlansCount: 0);
  bool updateCalled = false;
  bool lastEnabledPassed = false;

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
  }) async =>
      throw UnimplementedError();

  @override
  Future<PlannerCycleConsent> getPlannerCycleConsent() async => consent;

  @override
  Future<PlannerCycleConsent> updatePlannerCycleConsent(
      {required bool enabled}) async {
    updateCalled = true;
    lastEnabledPassed = enabled;
    consent = PlannerCycleConsent(
      enabled: enabled,
      deletedCyclePlansCount: enabled ? 0 : 3,
    );
    return consent;
  }
}

Widget _buildTestApp({
  required Widget child,
  required _FakeSettingsRepo fakeRepo,
  required bool isCycleTrackingEnabled,
}) {
  return ProviderScope(
    overrides: [
      studyPlannerRepositoryProvider.overrideWithValue(fakeRepo),
      cycleCareNotifierProvider.overrideWith(() => _FakeCycleCareNotifier(
            CycleCareState.initial().copyWith(
              trackingStatus: CycleTrackingStatus(
                cycleTrackingEnabled: isCycleTrackingEnabled,
              ),
            ),
          )),
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

class _FakeCycleCareNotifier extends CycleCareNotifier {
  _FakeCycleCareNotifier(this.initialState);
  final CycleCareState initialState;

  @override
  CycleCareState build() => initialState;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlannerSettingsScreen Tests', () {
    late _FakeSettingsRepo fakeRepo;

    setUp(() {
      fakeRepo = _FakeSettingsRepo();
    });

    testWidgets(
        'When cycle tracking is OFF, switch is disabled and notice is shown',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        child: const PlannerSettingsScreen(),
        fakeRepo: fakeRepo,
        isCycleTrackingEnabled: false,
      ));
      await tester.pumpAndSettle();

      expect(
          find.text(
              'Cycle tracking is currently off. Turn on CycleCare to enable this option.'),
          findsOneWidget);
      expect(find.text('Open CycleCare'), findsOneWidget);

      final switchWidget = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(switchWidget.onChanged, isNull);
    });

    testWidgets(
        'When cycle tracking is ON, turning ON shows transparent consent dialog and updates on confirmation',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        child: const PlannerSettingsScreen(),
        fakeRepo: fakeRepo,
        isCycleTrackingEnabled: true,
      ));
      await tester.pumpAndSettle();

      // Tap the switch
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      // Verify consent dialog content
      expect(find.text('Use Period Logs for Study Planning?'), findsOneWidget);
      expect(
          find.text(
              'We can use your recorded period days and your own energy check-ins to suggest gentler study pacing. Estimates and predicted dates are never used. Your data never leaves BloomWell and no AI has access to it. This is completely optional and can be turned off at any time. Turning this off will delete any plans that used your period logs.'),
          findsOneWidget);

      // Confirm dialog
      await tester.tap(find.text('I understand & allow'));
      await tester.pumpAndSettle();

      expect(fakeRepo.updateCalled, isTrue);
      expect(fakeRepo.lastEnabledPassed, isTrue);
    });

    testWidgets(
        'Turning OFF shows revocation dialog and shows honest server deletion count on confirm',
        (tester) async {
      fakeRepo.consent =
          const PlannerCycleConsent(enabled: true, deletedCyclePlansCount: 0);

      await tester.pumpWidget(_buildTestApp(
        child: const PlannerSettingsScreen(),
        fakeRepo: fakeRepo,
        isCycleTrackingEnabled: true,
      ));
      await tester.pumpAndSettle();

      // Switch should be active and ON
      final switchFinder = find.byType(SwitchListTile);
      expect(switchFinder, findsOneWidget);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Verify revocation dialog
      expect(find.text('Turn Off Period Log Access?'), findsOneWidget);
      expect(
          find.text(
              'Turning this off will delete all study plans that used your period logs. Are you sure you want to turn it off?'),
          findsOneWidget);

      // Confirm revocation
      await tester.tap(find.text('Turn off & delete plans'));
      await tester.pumpAndSettle();

      expect(fakeRepo.updateCalled, isTrue);
      expect(fakeRepo.lastEnabledPassed, isFalse);

      // Verify snackbar displays honest server count
      expect(find.text('Period log access turned off. 3 plans deleted.'),
          findsOneWidget);
    });
  });
}
