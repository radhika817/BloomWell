import 'package:bloomwell/app/theme/app_theme.dart';
import 'package:bloomwell/core/widgets/bloom_button.dart';
import 'package:bloomwell/features/app_lock/application/app_lock_notifier.dart';
import 'package:bloomwell/features/app_lock/domain/app_lock_config.dart';
import 'package:bloomwell/features/routines/application/routines_notifier.dart';
import 'package:bloomwell/features/routines/data/routines_repository.dart';
import 'package:bloomwell/features/routines/domain/entities/routine.dart';
import 'package:bloomwell/features/routines/domain/entities/routine_item.dart';
import 'package:bloomwell/features/routines/presentation/routines_screen.dart';
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

class FakeRoutinesRepo implements IRoutinesRepository {
  List<Routine> routines = [
    Routine(
      id: 'rt-1',
      title: 'Morning Awakening',
      startDate: DateTime.utc(2026, 10, 1),
      endDate: DateTime.utc(2026, 10, 31),
      createdAt: DateTime.utc(2026, 10, 1),
      items: [
        RoutineItem(
          id: 'item-1',
          routineId: 'rt-1',
          activityId: 'act-tea',
          activityTitle: 'Warm Chamomile Tea',
          position: 0,
          completedAt: DateTime.utc(2026, 10, 24, 8, 30),
        ),
        const RoutineItem(
          id: 'item-2',
          routineId: 'rt-1',
          activityId: 'act-breathe',
          activityTitle: 'Gentle Pacing Breath',
          position: 1,
          completedAt: null,
        ),
      ],
    ),
  ];

  @override
  Future<List<Routine>> getRoutines() async => List.of(routines);

  @override
  Future<Routine> getRoutine(String id) async =>
      routines.firstWhere((r) => r.id == id);

  @override
  Future<Routine> createRoutine({
    required String title,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final created = Routine(
      id: 'rt-${routines.length + 1}',
      title: title,
      startDate: startDate,
      endDate: endDate,
      createdAt: DateTime.now(),
      items: [],
    );
    routines.add(created);
    return created;
  }

  @override
  Future<Routine> updateRoutine({
    required String id,
    String? title,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
  }) async {
    final index = routines.indexWhere((r) => r.id == id);
    final existing = routines[index];
    final updated = existing.copyWith(
      title: title ?? existing.title,
      startDate: clearStartDate ? null : (startDate ?? existing.startDate),
      endDate: clearEndDate ? null : (endDate ?? existing.endDate),
    );
    routines[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteRoutine(String id) async {
    routines.removeWhere((r) => r.id == id);
  }

  @override
  Future<RoutineItem> addItem({
    required String routineId,
    required String activityId,
    DateTime? scheduledDate,
  }) async {
    final newItem = RoutineItem(
      id: 'item-${DateTime.now().millisecondsSinceEpoch}',
      routineId: routineId,
      activityId: activityId,
      activityTitle: 'Gentle Activity',
      position: 0,
      completedAt: null,
      scheduledDate: scheduledDate,
    );
    return newItem;
  }

  @override
  Future<RoutineItem> updateItem({
    required String routineId,
    required String itemId,
    bool? isCompleted,
    int? position,
    DateTime? scheduledDate,
    bool clearScheduledDate = false,
  }) async {
    final routineIndex = routines.indexWhere((r) => r.id == routineId);
    final routine = routines[routineIndex];
    final itemIndex = routine.items.indexWhere((i) => i.id == itemId);
    final item = routine.items[itemIndex];
    final updatedItem = item.copyWith(
      completedAt: isCompleted == true ? DateTime.now() : null,
      clearCompletedAt: isCompleted == false,
      position: position ?? item.position,
    );
    final updatedItems = List<RoutineItem>.from(routine.items);
    updatedItems[itemIndex] = updatedItem;
    routines[routineIndex] = routine.copyWith(items: updatedItems);
    return updatedItem;
  }

  @override
  Future<void> deleteItem({
    required String routineId,
    required String itemId,
  }) async {
    final routineIndex = routines.indexWhere((r) => r.id == routineId);
    final routine = routines[routineIndex];
    routines[routineIndex] = routine.copyWith(
      items: routine.items.where((i) => i.id != itemId).toList(),
    );
  }

  @override
  Future<List<RoutineItem>> reorderItems({
    required String routineId,
    required List<String> itemIdsInOrder,
  }) async =>
      [];
}

class FakeSelfCareRepo implements ISelfCareRepository {
  @override
  Future<({List<ActivityEntry> items, String? nextCursor, bool hasMore})>
      getActivities({
    ActivityCategory? category,
    int? maxDuration,
    String? cursor,
    int limit = 20,
  }) async =>
          (items: <ActivityEntry>[], nextCursor: null, hasMore: false);

  @override
  Future<ActivityEntry> getActivityDetail(String id) async =>
      throw UnimplementedError();

  @override
  Future<({List<ActivityEntry> items, String? nextCursor, bool hasMore})>
      getFavorites({String? cursor, int limit = 50}) async =>
          (items: <ActivityEntry>[], nextCursor: null, hasMore: false);

  @override
  Future<bool> setFavorite(
          {required String activityId, required bool isFavorite}) async =>
      true;

  @override
  Future<List<ActivitySuggestion>> getSuggestions({
    required String need,
    int? maxDuration,
  }) async =>
      [];

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

Widget buildRoutinesApp({
  required FakeRoutinesRepo routinesRepo,
  bool isLocked = false,
}) {
  return ProviderScope(
    overrides: [
      routinesRepositoryProvider.overrideWithValue(routinesRepo),
      selfCareRepositoryProvider.overrideWithValue(FakeSelfCareRepo()),
      appLockNotifierProvider.overrideWith(() => MockLockNotifier(isLocked)),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const RoutinesScreen(),
    ),
  );
}

void main() {
  group('RoutinesScreen Tests', () {
    late FakeRoutinesRepo routinesRepo;

    setUp(() {
      routinesRepo = FakeRoutinesRepo();
    });

    testWidgets('renders routines list and peaceful progress text',
        (tester) async {
      await tester.pumpWidget(buildRoutinesApp(routinesRepo: routinesRepo));
      await tester.pumpAndSettle();

      expect(find.text('Routines'), findsOneWidget);
      expect(
        find.text('Gentle rituals to nourish your rhythm without pressure.'),
        findsOneWidget,
      );
      expect(find.text('Morning Awakening'), findsOneWidget);

      // Verify peaceful progress text "1 of 2 done"
      expect(find.text('1 of 2 done'), findsOneWidget);

      // Verify STRICT guardrails: strictly no streaks, % or behind
      expect(find.textContaining(RegExp(r'streak', caseSensitive: false)),
          findsNothing);
      expect(find.textContaining('%'), findsNothing);
      expect(find.textContaining(RegExp(r'behind', caseSensitive: false)),
          findsNothing);
      expect(find.textContaining(RegExp(r'missed', caseSensitive: false)),
          findsNothing);

      // Items inside routine
      expect(find.text('Warm Chamomile Tea'), findsOneWidget);
      expect(find.text('Gentle Pacing Breath'), findsOneWidget);
    });

    testWidgets('toggling item done updates status and progress',
        (tester) async {
      await tester.pumpWidget(buildRoutinesApp(routinesRepo: routinesRepo));
      await tester.pumpAndSettle();

      expect(find.text('1 of 2 done'), findsOneWidget);

      // Find the second item's unchecked button ("Mark done")
      final markDoneFinder = find.byTooltip('Mark done');
      expect(markDoneFinder, findsOneWidget);

      await tester.tap(markDoneFinder);
      await tester.pumpAndSettle();

      // Progress advances peacefully to "2 of 2 done"
      expect(find.text('2 of 2 done'), findsOneWidget);
    });

    testWidgets('deleting routine removes it after user confirms',
        (tester) async {
      await tester.pumpWidget(buildRoutinesApp(routinesRepo: routinesRepo));
      await tester.pumpAndSettle();

      // Open routine menu
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      // Tap Delete in menu
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Verify confirmation dialog appears
      expect(
        find.text('Are you sure you want to delete this routine?'),
        findsOneWidget,
      );

      // Confirm delete
      final confirmDeleteFinder = find.widgetWithText(TextButton, 'Delete');
      await tester.tap(confirmDeleteFinder);
      await tester.pumpAndSettle();

      expect(routinesRepo.routines.isEmpty, isTrue);
      expect(find.text('No routines created yet'), findsOneWidget);
    });

    testWidgets('limit guard: 20 routines limit disables new button',
        (tester) async {
      // Populate 20 routines
      routinesRepo.routines = List.generate(
        20,
        (i) => Routine(
          id: 'rt-$i',
          title: 'Routine #$i',
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(buildRoutinesApp(routinesRepo: routinesRepo));
      await tester.pumpAndSettle();

      expect(
        find.text('You have reached the maximum limit of 20 routines.'),
        findsOneWidget,
      );

      // "New routine" button is disabled
      final newRoutineBtn = tester.widget<BloomButton>(
        find.widgetWithText(BloomButton, 'New routine'),
      );
      expect(newRoutineBtn.onPressed, isNull);
    });

    testWidgets('limit guard: 50 items limit disables add activity button',
        (tester) async {
      // Routine with 50 items
      routinesRepo.routines = [
        Routine(
          id: 'rt-heavy',
          title: 'Max Items Routine',
          createdAt: DateTime.now(),
          items: List.generate(
            50,
            (i) => RoutineItem(
              id: 'item-$i',
              routineId: 'rt-heavy',
              activityId: 'act-$i',
              activityTitle: 'Activity #$i',
              position: i,
              completedAt: null,
            ),
          ),
        ),
      ];

      await tester.pumpWidget(buildRoutinesApp(routinesRepo: routinesRepo));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'You have reached the maximum limit of 50 activities for this routine.',
        ),
        findsOneWidget,
      );

      // Add activity button is disabled
      final addActivityBtn = tester.widget<BloomButton>(
        find.widgetWithText(BloomButton, 'Add activity'),
      );
      expect(addActivityBtn.onPressed, isNull);
    });

    testWidgets('empty state renders peaceful message', (tester) async {
      routinesRepo.routines = [];

      await tester.pumpWidget(buildRoutinesApp(routinesRepo: routinesRepo));
      await tester.pumpAndSettle();

      expect(find.text('No routines created yet'), findsOneWidget);
      expect(
        find.text(
          'Create a soothing daily or weekly routine that feels good to you.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('when app is locked, screen is blank for privacy',
        (tester) async {
      await tester.pumpWidget(buildRoutinesApp(
        routinesRepo: routinesRepo,
        isLocked: true,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Routines'), findsNothing);
      expect(find.text('Morning Awakening'), findsNothing);
    });
  });
}
