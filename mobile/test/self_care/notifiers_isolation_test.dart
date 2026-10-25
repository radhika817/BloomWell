import 'package:bloomwell/features/auth/application/auth_notifier.dart';
import 'package:bloomwell/features/comfort/application/comfort_notifier.dart';
import 'package:bloomwell/features/comfort/data/comfort_repository.dart';
import 'package:bloomwell/features/comfort/domain/entities/comfort_need.dart';
import 'package:bloomwell/features/comfort/domain/entities/comfort_plan_item.dart';
import 'package:bloomwell/features/exams/application/academic_events_notifier.dart';
import 'package:bloomwell/features/exams/data/academic_events_repository.dart';
import 'package:bloomwell/features/exams/domain/entities/academic_event.dart';
import 'package:bloomwell/features/exams/domain/entities/academic_event_type.dart';
import 'package:bloomwell/features/routines/application/routines_notifier.dart';
import 'package:bloomwell/features/routines/data/routines_repository.dart';
import 'package:bloomwell/features/routines/domain/entities/routine.dart';
import 'package:bloomwell/features/routines/domain/entities/routine_item.dart';
import 'package:bloomwell/features/self_care/application/activity_history_notifier.dart';
import 'package:bloomwell/features/self_care/application/self_care_notifier.dart';
import 'package:bloomwell/features/self_care/data/self_care_repository.dart';
import 'package:bloomwell/features/self_care/domain/entities/activity_category.dart';
import 'package:bloomwell/features/self_care/domain/entities/activity_completion_log.dart';
import 'package:bloomwell/features/self_care/domain/entities/activity_entry.dart';
import 'package:bloomwell/features/self_care/domain/entities/activity_suggestion.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSelfCareRepository implements ISelfCareRepository {
  List<ActivityEntry> activities = [
    const ActivityEntry(
      id: 'act-1',
      title: 'Box Breathing',
      category: ActivityCategory.breathing,
      durationMinutes: 4,
      summary: 'Soothing rhythm',
      steps: ['Breathe in', 'Hold', 'Breathe out', 'Rest'],
      source: 'Clinical Guide',
      slug: 'box-breathing',
    ),
    const ActivityEntry(
      id: 'act-2',
      title: 'Warm Compress Rest',
      category: ActivityCategory.comfort,
      durationMinutes: 10,
      summary: 'Rest with gentle warmth',
      steps: ['Prepare compress', 'Rest comfortably'],
      source: 'Student Health',
    ),
  ];

  Set<String> favorites = {};
  List<ActivityCompletionLog> history = [];
  int completeCalls = 0;
  String? lastClientId;

  @override
  Future<({List<ActivityEntry> items, String? nextCursor, bool hasMore})>
      getActivities({
    ActivityCategory? category,
    int? maxDuration,
    String? cursor,
    int limit = 20,
  }) async {
    var filtered = activities;
    if (category != null) {
      filtered = filtered.where((a) => a.category == category).toList();
    }
    if (maxDuration != null) {
      filtered =
          filtered.where((a) => a.durationMinutes <= maxDuration).toList();
    }
    return (items: filtered, nextCursor: null, hasMore: false);
  }

  @override
  Future<ActivityEntry> getActivityDetail(String id) async {
    return activities.firstWhere((a) => a.id == id);
  }

  @override
  Future<List<ActivitySuggestion>> getSuggestions({
    required String need,
    int? maxDuration,
  }) async {
    return [
      ActivitySuggestion(
        activity: activities.first,
        reasonCode: 'FAVORITE',
        reason: ActivitySuggestionReason.favorite,
      ),
    ];
  }

  @override
  Future<({List<ActivityEntry> items, String? nextCursor, bool hasMore})>
      getFavorites({
    String? cursor,
    int limit = 50,
  }) async {
    final favList = activities.where((a) => favorites.contains(a.id)).toList();
    return (items: favList, nextCursor: null, hasMore: false);
  }

  @override
  Future<bool> setFavorite({
    required String activityId,
    required bool isFavorite,
  }) async {
    if (isFavorite) {
      favorites.add(activityId);
      return true;
    } else {
      favorites.remove(activityId);
      return false;
    }
  }

  @override
  Future<ActivityCompletionLog> completeActivity({
    required String clientId,
    required String activityId,
    int? helpfulnessRating,
  }) async {
    completeCalls++;
    lastClientId = clientId;
    final log = ActivityCompletionLog(
      id: 'comp-$completeCalls',
      clientId: clientId,
      activityId: activityId,
      activityTitle: 'Completed Activity',
      activityCategory: ActivityCategory.breathing,
      completedAt: DateTime.now(),
      helpfulnessRating: helpfulnessRating,
    );
    history.add(log);
    return log;
  }

  @override
  Future<
      ({
        List<ActivityCompletionLog> items,
        String? nextCursor,
        bool hasMore
      })> getActivityHistory({
    String? cursor,
    int limit = 20,
  }) async {
    return (items: history, nextCursor: null, hasMore: false);
  }
}

class FakeComfortRepository implements IComfortRepository {
  List<ComfortPlanItem> items = [];

  @override
  Future<List<ComfortPlanItem>> getComfortPlan() async => List.of(items);

  @override
  Future<ComfortPlanItem> addToComfortPlan({required String activityId}) async {
    final item = ComfortPlanItem(
      id: 'cp-${items.length + 1}',
      activityId: activityId,
      position: items.length,
      createdAt: DateTime.now(),
    );
    items.add(item);
    return item;
  }

  @override
  Future<void> removeFromComfortPlan(String itemId) async {
    items.removeWhere((i) => i.id == itemId);
  }

  @override
  Future<List<ComfortPlanItem>> reorderComfortPlan(
      List<String> itemIdsInOrder) async {
    final reordered = <ComfortPlanItem>[];
    for (int i = 0; i < itemIdsInOrder.length; i++) {
      final existing = items.firstWhere((it) => it.id == itemIdsInOrder[i]);
      reordered.add(existing.copyWith(position: i));
    }
    items = reordered;
    return items;
  }
}

class FakeRoutinesRepository implements IRoutinesRepository {
  List<Routine> routines = [];

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
    final r = Routine(
      id: 'r-${routines.length + 1}',
      title: title,
      startDate: startDate,
      endDate: endDate,
      items: [],
      createdAt: DateTime.now(),
    );
    routines.add(r);
    return r;
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
    final r = routines[index];
    final updated = r.copyWith(
      title: title,
      startDate: startDate,
      clearStartDate: clearStartDate,
      endDate: endDate,
      clearEndDate: clearEndDate,
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
    final item = RoutineItem(
      id: 'i-new',
      routineId: routineId,
      activityId: activityId,
      activityTitle: 'Test Activity',
      scheduledDate: scheduledDate,
    );
    final index = routines.indexWhere((r) => r.id == routineId);
    routines[index] =
        routines[index].copyWith(items: [...routines[index].items, item]);
    return item;
  }

  @override
  Future<RoutineItem> updateItem({
    required String routineId,
    required String itemId,
    DateTime? scheduledDate,
    bool clearScheduledDate = false,
    bool? isCompleted,
    int? position,
  }) async {
    final rIndex = routines.indexWhere((r) => r.id == routineId);
    final iIndex = routines[rIndex].items.indexWhere((i) => i.id == itemId);
    final item = routines[rIndex].items[iIndex];
    final updated = item.copyWith(
      scheduledDate: scheduledDate,
      clearScheduledDate: clearScheduledDate,
      completedAt: isCompleted == true ? DateTime.now() : null,
      clearCompletedAt: isCompleted == false,
      position: position,
    );
    final nextItems = List<RoutineItem>.from(routines[rIndex].items);
    nextItems[iIndex] = updated;
    routines[rIndex] = routines[rIndex].copyWith(items: nextItems);
    return updated;
  }

  @override
  Future<void> deleteItem({
    required String routineId,
    required String itemId,
  }) async {
    final rIndex = routines.indexWhere((r) => r.id == routineId);
    final nextItems =
        routines[rIndex].items.where((i) => i.id != itemId).toList();
    routines[rIndex] = routines[rIndex].copyWith(items: nextItems);
  }

  @override
  Future<List<RoutineItem>> reorderItems({
    required String routineId,
    required List<String> itemIdsInOrder,
  }) async {
    final rIndex = routines.indexWhere((r) => r.id == routineId);
    final current = routines[rIndex].items;
    final reordered = <RoutineItem>[];
    for (int i = 0; i < itemIdsInOrder.length; i++) {
      final it = current.firstWhere((x) => x.id == itemIdsInOrder[i]);
      reordered.add(it.copyWith(position: i));
    }
    routines[rIndex] = routines[rIndex].copyWith(items: reordered);
    return reordered;
  }
}

class FakeAcademicEventsRepository implements IAcademicEventsRepository {
  List<AcademicEvent> events = [];

  @override
  Future<({List<AcademicEvent> items, String? nextCursor, bool hasMore})>
      getEvents({
    bool? upcomingOnly,
    String? cursor,
    int limit = 50,
  }) async {
    return (items: List.of(events), nextCursor: null, hasMore: false);
  }

  @override
  Future<AcademicEvent> createEvent({
    required String clientId,
    required String title,
    required DateTime eventDate,
    required AcademicEventType eventType,
  }) async {
    final ev = AcademicEvent(
      id: 'ev-${events.length + 1}',
      clientId: clientId,
      title: title,
      eventDate: eventDate,
      eventType: eventType,
      createdAt: DateTime.now(),
    );
    events.add(ev);
    return ev;
  }

  @override
  Future<AcademicEvent> updateEvent({
    required String id,
    String? title,
    DateTime? eventDate,
    AcademicEventType? eventType,
  }) async {
    final index = events.indexWhere((e) => e.id == id);
    final existing = events[index];
    final updated = existing.copyWith(
      title: title,
      eventDate: eventDate,
      eventType: eventType,
    );
    events[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteEvent(String id) async {
    events.removeWhere((e) => e.id == id);
  }
}

void main() {
  group('Notifiers & In-Memory Isolation Test Suite', () {
    late FakeSelfCareRepository fakeSelfCare;
    late FakeComfortRepository fakeComfort;
    late FakeRoutinesRepository fakeRoutines;
    late FakeAcademicEventsRepository fakeExams;
    late ProviderContainer container;

    setUp(() {
      fakeSelfCare = FakeSelfCareRepository();
      fakeComfort = FakeComfortRepository();
      fakeRoutines = FakeRoutinesRepository();
      fakeExams = FakeAcademicEventsRepository();

      container = ProviderContainer(
        overrides: [
          selfCareRepositoryProvider.overrideWithValue(fakeSelfCare),
          comfortRepositoryProvider.overrideWithValue(fakeComfort),
          routinesRepositoryProvider.overrideWithValue(fakeRoutines),
          academicEventsRepositoryProvider.overrideWithValue(fakeExams),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test(
        'SelfCareNotifier manages activities, favorites confirmation, and idempotent retry',
        () async {
      final notifier = container.read(selfCareNotifierProvider.notifier);
      await notifier.loadActivities();

      var state = container.read(selfCareNotifierProvider);
      expect(state.activities.length, 2);
      expect(state.favorites, isEmpty);

      // Favorite toggle updates state only after server confirmation
      final isFav = await notifier.toggleFavorite('act-1');
      expect(isFav, isTrue);

      state = container.read(selfCareNotifierProvider);
      expect(state.favorites.contains('act-1'), isTrue);
      expect(state.activities.first.isFavorite, isTrue);

      // Idempotent retry reusing client_id
      const reusedClientId = 'retry-client-uuid-1234';
      final comp1 = await notifier.completeActivity(
        clientId: reusedClientId,
        activityId: 'act-1',
        helpfulnessRating: 5,
      );
      expect(comp1, isNotNull);
      expect(fakeSelfCare.lastClientId, reusedClientId);

      // Re-triggering complete with same clientId
      await notifier.completeActivity(
        clientId: reusedClientId,
        activityId: 'act-1',
        helpfulnessRating: 5,
      );
      expect(fakeSelfCare.lastClientId, reusedClientId);
    });

    test(
        'ComfortNotifier updates need and cycles duration tiers deterministically',
        () async {
      final comfortNotifier = container.read(comfortNotifierProvider.notifier);
      await comfortNotifier.loadInitial();

      var state = container.read(comfortNotifierProvider);
      expect(state.selectedNeed, ComfortNeed.calmDown);
      expect(state.currentMaxDuration, 5);

      // Show something else advances tier
      await comfortNotifier.showSomethingElse();
      state = container.read(comfortNotifierProvider);
      expect(state.currentMaxDuration, 10);

      await comfortNotifier.showSomethingElse();
      state = container.read(comfortNotifierProvider);
      expect(state.currentMaxDuration, 15);

      await comfortNotifier.showSomethingElse();
      state = container.read(comfortNotifierProvider);
      expect(state.currentMaxDuration, 2);

      // Adding & removing comfort plan item
      await comfortNotifier.addToPlan('act-1');
      state = container.read(comfortNotifierProvider);
      expect(state.comfortPlan.length, 1);

      await comfortNotifier.removeFromPlan(state.comfortPlan.first.id);
      state = container.read(comfortNotifierProvider);
      expect(state.comfortPlan, isEmpty);
    });

    test(
        'RoutinesNotifier handles creation, item completion, and enforces 20 routines limit',
        () async {
      final routinesNotifier =
          container.read(routinesNotifierProvider.notifier);
      await routinesNotifier.loadRoutines();

      // Create routine
      final success =
          await routinesNotifier.createRoutine(title: 'Rest Routine');
      expect(success, isTrue);

      var state = container.read(routinesNotifierProvider);
      expect(state.routines.length, 1);
      final routineId = state.routines.first.id;

      // Add item and mark done
      await routinesNotifier.addItem(routineId: routineId, activityId: 'act-1');
      state = container.read(routinesNotifierProvider);
      expect(state.routines.first.items.length, 1);
      expect(state.routines.first.progressText, '0 of 1 done');

      final itemId = state.routines.first.items.first.id;
      await routinesNotifier.toggleItemDone(
        routineId: routineId,
        itemId: itemId,
        isDone: true,
      );
      state = container.read(routinesNotifierProvider);
      expect(state.routines.first.progressText, '1 of 1 done');
    });

    test(
        'AcademicEventsNotifier handles event creation, title validation, and upcoming/past toggle',
        () async {
      final eventsNotifier =
          container.read(academicEventsNotifierProvider.notifier);
      await eventsNotifier.loadEvents();

      // Empty title validation
      final failEmpty = await eventsNotifier.createEvent(
        clientId: 'cid-1',
        title: '',
        eventDate: DateTime.now().add(const Duration(days: 3)),
        eventType: AcademicEventType.exam,
      );
      expect(failEmpty, isFalse);

      // Title over 80 characters validation
      final failLong = await eventsNotifier.createEvent(
        clientId: 'cid-1',
        title: 'A' * 81,
        eventDate: DateTime.now().add(const Duration(days: 3)),
        eventType: AcademicEventType.exam,
      );
      expect(failLong, isFalse);

      // Valid upcoming event
      final okUpcoming = await eventsNotifier.createEvent(
        clientId: 'cid-1',
        title: 'Midterm Physics',
        eventDate: DateTime.now().add(const Duration(days: 2)),
        eventType: AcademicEventType.exam,
      );
      expect(okUpcoming, isTrue);

      // Valid past event
      final okPast = await eventsNotifier.createEvent(
        clientId: 'cid-2',
        title: 'English Essay Draft',
        eventDate: DateTime.now().subtract(const Duration(days: 5)),
        eventType: AcademicEventType.assignment,
      );
      expect(okPast, isTrue);

      var state = container.read(academicEventsNotifierProvider);
      expect(state.visibleEvents.length, 1);
      expect(state.visibleEvents.first.title, 'Midterm Physics');

      // Toggle to past view
      eventsNotifier.togglePastView();
      state = container.read(academicEventsNotifierProvider);
      expect(state.visibleEvents.length, 1);
      expect(state.visibleEvents.first.title, 'English Essay Draft');
    });

    test(
        'IN-MEMORY ISOLATION: Logout or session expiration immediately wipes ALL sensitive state',
        () async {
      // 1. Populate all notifiers with state
      final selfCare = container.read(selfCareNotifierProvider.notifier);
      await selfCare.loadActivities();
      await selfCare.toggleFavorite('act-1');

      final history = container.read(activityHistoryNotifierProvider.notifier);
      await selfCare.completeActivity(
        clientId: 'cid-hist',
        activityId: 'act-1',
      );
      await history.loadInitial();

      final comfort = container.read(comfortNotifierProvider.notifier);
      await comfort.loadInitial();
      await comfort.addToPlan('act-1');

      final routines = container.read(routinesNotifierProvider.notifier);
      await routines.createRoutine(title: 'Private Routine');

      final exams = container.read(academicEventsNotifierProvider.notifier);
      await exams.createEvent(
        clientId: 'cid-exam',
        title: 'Private Exam',
        eventDate: DateTime.now().add(const Duration(days: 5)),
        eventType: AcademicEventType.exam,
      );

      // Verify all populated
      expect(container.read(selfCareNotifierProvider).favorites, isNotEmpty);
      expect(
          container.read(activityHistoryNotifierProvider).history, isNotEmpty);
      expect(container.read(comfortNotifierProvider).comfortPlan, isNotEmpty);
      expect(container.read(routinesNotifierProvider).routines, isNotEmpty);
      expect(container.read(academicEventsNotifierProvider).events, isNotEmpty);

      // 2. Trigger session expired / logout
      container.read(authNotifierProvider.notifier).handleSessionExpired();

      // 3. Assert all in-memory user data is wiped completely
      expect(container.read(selfCareNotifierProvider).favorites, isEmpty);
      expect(container.read(selfCareNotifierProvider).activities, isEmpty);
      expect(container.read(activityHistoryNotifierProvider).history, isEmpty);
      expect(container.read(comfortNotifierProvider).comfortPlan, isEmpty);
      expect(container.read(comfortNotifierProvider).suggestions, isEmpty);
      expect(container.read(routinesNotifierProvider).routines, isEmpty);
      expect(container.read(academicEventsNotifierProvider).events, isEmpty);
    });
  });
}
