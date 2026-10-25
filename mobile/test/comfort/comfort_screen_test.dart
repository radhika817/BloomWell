import 'package:bloomwell/app/theme/app_theme.dart';
import 'package:bloomwell/features/app_lock/application/app_lock_notifier.dart';
import 'package:bloomwell/features/app_lock/domain/app_lock_config.dart';
import 'package:bloomwell/features/comfort/application/comfort_notifier.dart';
import 'package:bloomwell/features/comfort/data/comfort_repository.dart';
import 'package:bloomwell/features/comfort/domain/entities/comfort_plan_item.dart';
import 'package:bloomwell/features/comfort/presentation/comfort_screen.dart';
import 'package:bloomwell/features/self_care/application/self_care_notifier.dart';
import 'package:bloomwell/features/self_care/data/self_care_repository.dart';
import 'package:bloomwell/features/self_care/domain/entities/activity_category.dart';
import 'package:bloomwell/features/self_care/domain/entities/activity_completion_log.dart';
import 'package:bloomwell/features/self_care/domain/entities/activity_entry.dart';
import 'package:bloomwell/features/self_care/domain/entities/activity_suggestion.dart';
import 'package:bloomwell/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockLockNotifier extends AppLockNotifier {
  final bool _locked;
  MockLockNotifier([this._locked = false]);

  @override
  AppLockState build() =>
      const AppLockState.initial().copyWith(isLocked: _locked);
}

class FakeSelfCareRepoForComfort implements ISelfCareRepository {
  final List<ActivityEntry> activities = [
    const ActivityEntry(
      id: 'act-tea',
      title: 'Warm Chamomile Tea',
      category: ActivityCategory.comfort,
      durationMinutes: 5,
      summary: 'Gentle warmth to soothe your body.',
      steps: ['Steep tea', 'Sip slowly'],
      source: 'Student Wellness',
    ),
    const ActivityEntry(
      id: 'act-breathe',
      title: 'Gentle Pacing Breath',
      category: ActivityCategory.breathing,
      durationMinutes: 3,
      summary: 'Soothing breaths to release tension.',
      steps: ['Breathe in', 'Breathe out'],
      source: 'Mindfulness Practice',
    ),
  ];

  String? lastNeedRequested;
  int? lastMaxDurationRequested;

  @override
  Future<List<ActivitySuggestion>> getSuggestions({
    required String need,
    int? maxDuration,
  }) async {
    lastNeedRequested = need;
    lastMaxDurationRequested = maxDuration;

    return [
      ActivitySuggestion(
        activity: activities.first,
        reasonCode: 'FAVORITE',
        reason: ActivitySuggestionReason.favorite,
      ),
      ActivitySuggestion(
        activity: activities.last,
        reasonCode: 'NEW_FOR_YOU',
        reason: ActivitySuggestionReason.newForYou,
      ),
    ];
  }

  @override
  Future<({List<ActivityEntry> items, String? nextCursor, bool hasMore})>
      getActivities({
    ActivityCategory? category,
    int? maxDuration,
    String? cursor,
    int limit = 20,
  }) async =>
          (items: activities, nextCursor: null, hasMore: false);

  @override
  Future<ActivityEntry> getActivityDetail(String id) async => activities.first;

  @override
  Future<({List<ActivityEntry> items, String? nextCursor, bool hasMore})>
      getFavorites({String? cursor, int limit = 50}) async =>
          (items: <ActivityEntry>[], nextCursor: null, hasMore: false);

  @override
  Future<bool> setFavorite(
          {required String activityId, required bool isFavorite}) async =>
      true;

  @override
  Future<ActivityCompletionLog> completeActivity({
    required String clientId,
    required String activityId,
    int? helpfulnessRating,
  }) async =>
      throw UnimplementedError();

  @override
  Future<
      ({
        List<ActivityCompletionLog> items,
        String? nextCursor,
        bool hasMore
      })> getActivityHistory(
          {String? cursor, int limit = 20}) async =>
      (items: <ActivityCompletionLog>[], nextCursor: null, hasMore: false);
}

class FakeComfortRepo implements IComfortRepository {
  List<ComfortPlanItem> planItems = [
    ComfortPlanItem(
      id: 'plan-item-1',
      activityId: 'act-tea',
      activity: const ActivityEntry(
        id: 'act-tea',
        title: 'Warm Chamomile Tea',
        category: ActivityCategory.comfort,
        durationMinutes: 5,
        summary: 'Gentle warmth to soothe your body.',
        steps: ['Steep tea'],
        source: 'Student Wellness',
      ),
      position: 0,
      createdAt: DateTime.utc(2026, 10, 24),
    ),
  ];

  @override
  Future<List<ComfortPlanItem>> getComfortPlan() async => List.of(planItems);

  @override
  Future<ComfortPlanItem> addToComfortPlan({required String activityId}) async {
    final newItem = ComfortPlanItem(
      id: 'plan-item-${planItems.length + 1}',
      activityId: 'act-breathe',
      activity: const ActivityEntry(
        id: 'act-breathe',
        title: 'Gentle Pacing Breath',
        category: ActivityCategory.breathing,
        durationMinutes: 3,
        summary: 'Soothing breaths to release tension.',
        steps: ['Breathe in', 'Breathe out'],
        source: 'Mindfulness Practice',
      ),
      position: planItems.length,
      createdAt: DateTime.now(),
    );
    planItems.add(newItem);
    return newItem;
  }

  @override
  Future<void> removeFromComfortPlan(String itemId) async {
    planItems.removeWhere((i) => i.id == itemId);
  }

  @override
  Future<List<ComfortPlanItem>> reorderComfortPlan(List<String> itemIds) async {
    final reordered = <ComfortPlanItem>[];
    for (int i = 0; i < itemIds.length; i++) {
      final found = planItems.firstWhere((p) => p.id == itemIds[i]);
      reordered.add(found.copyWith(position: i));
    }
    planItems = reordered;
    return List.of(planItems);
  }
}

Widget buildComfortApp({
  required FakeSelfCareRepoForComfort selfCareRepo,
  required FakeComfortRepo comfortRepo,
  bool isLocked = false,
}) {
  return ProviderScope(
    overrides: [
      selfCareRepositoryProvider.overrideWithValue(selfCareRepo),
      comfortRepositoryProvider.overrideWithValue(comfortRepo),
      appLockNotifierProvider.overrideWith(() => MockLockNotifier(isLocked)),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const ComfortScreen(),
    ),
  );
}

void main() {
  group('ComfortScreen Tests', () {
    late FakeSelfCareRepoForComfort selfCareRepo;
    late FakeComfortRepo comfortRepo;

    setUp(() {
      selfCareRepo = FakeSelfCareRepoForComfort();
      comfortRepo = FakeComfortRepo();
    });

    testWidgets(
        'renders low-stimulation header, needs chips, suggestions and plan',
        (tester) async {
      await tester.pumpWidget(buildComfortApp(
        selfCareRepo: selfCareRepo,
        comfortRepo: comfortRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('A gentle moment'), findsOneWidget);
      expect(
        find.text('No pressure. Pick what feels okay right now.'),
        findsOneWidget,
      );
      expect(find.text('What do you need?'), findsOneWidget);
      expect(find.text('Calm down'), findsOneWidget);
      expect(find.text('A quick break'), findsOneWidget);
      expect(find.text('Body comfort'), findsOneWidget);
      expect(find.text('Focus'), findsOneWidget);

      // Suggestions
      expect(find.text('Warm Chamomile Tea'), findsWidgets);
      expect(find.text('One of your favorites'), findsOneWidget);
      expect(find.text('Gentle Pacing Breath'), findsOneWidget);
      expect(find.text('Something new to try'), findsOneWidget);

      // Comfort plan
      expect(find.text('My comfort plan'), findsOneWidget);
      expect(
        find.text('Your saved soothing practices for difficult days.'),
        findsOneWidget,
      );

      // Support & Non-medical notice
      expect(find.text('Find support'), findsWidgets);
      expect(
        find.text(
          'BloomWell is not a medical or emergency service. If you are going through a difficult time, reaching out to a trusted person or health professional can help.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('tapping need chip updates suggestions query', (tester) async {
      await tester.pumpWidget(buildComfortApp(
        selfCareRepo: selfCareRepo,
        comfortRepo: comfortRepo,
      ));
      await tester.pumpAndSettle();

      expect(selfCareRepo.lastNeedRequested, equals('calm'));

      // Tap 'Body comfort'
      await tester.tap(find.text('Body comfort'));
      await tester.pumpAndSettle();

      expect(selfCareRepo.lastNeedRequested, equals('body_comfort'));
    });

    testWidgets('Show me something else cycles duration tier', (tester) async {
      await tester.pumpWidget(buildComfortApp(
        selfCareRepo: selfCareRepo,
        comfortRepo: comfortRepo,
      ));
      await tester.pumpAndSettle();

      final initialMaxDuration = selfCareRepo.lastMaxDurationRequested;

      await tester.tap(find.text('Show me something else'));
      await tester.pumpAndSettle();

      expect(
        selfCareRepo.lastMaxDurationRequested,
        isNot(equals(initialMaxDuration)),
      );
    });

    testWidgets('removing item from comfort plan updates list', (tester) async {
      await tester.pumpWidget(buildComfortApp(
        selfCareRepo: selfCareRepo,
        comfortRepo: comfortRepo,
      ));
      await tester.pumpAndSettle();

      // Initially 1 item in plan
      expect(comfortRepo.planItems.length, equals(1));

      // Scroll down to bring plan item into view
      await tester.drag(
          find.byType(SingleChildScrollView).first, const Offset(0, -300));
      await tester.pumpAndSettle();

      // Tap remove button
      await tester.tap(find.byTooltip('Remove from plan'));
      await tester.pumpAndSettle();

      expect(comfortRepo.planItems.isEmpty, isTrue);
      expect(
        find.text(
          'No practices in your plan yet. Save a few favorites here for easy access.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('adding activity to comfort plan updates plan list',
        (tester) async {
      await tester.pumpWidget(buildComfortApp(
        selfCareRepo: selfCareRepo,
        comfortRepo: comfortRepo,
      ));
      await tester.pumpAndSettle();

      // Find 'Add to comfort plan' button on suggestion
      final addBtnFinder = find.text('Add to comfort plan');
      expect(addBtnFinder, findsOneWidget);

      await tester.tap(addBtnFinder);
      await tester.pumpAndSettle();

      expect(comfortRepo.planItems.length, equals(2));
      expect(find.text('✓ Saved in plan'), findsNWidgets(2));
    });

    testWidgets('when app is locked, screen is blank for privacy',
        (tester) async {
      await tester.pumpWidget(buildComfortApp(
        selfCareRepo: selfCareRepo,
        comfortRepo: comfortRepo,
        isLocked: true,
      ));
      await tester.pumpAndSettle();

      expect(find.text('A gentle moment'), findsNothing);
      expect(find.text('What do you need?'), findsNothing);
    });
  });
}
