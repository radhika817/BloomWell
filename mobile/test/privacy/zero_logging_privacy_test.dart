import 'dart:async';
import 'package:bloomwell/features/exams/application/academic_events_notifier.dart';
import 'package:bloomwell/features/exams/data/academic_events_repository.dart';
import 'package:bloomwell/features/exams/domain/entities/academic_event.dart';
import 'package:bloomwell/features/exams/domain/entities/academic_event_type.dart';
import 'package:bloomwell/features/comfort/application/comfort_notifier.dart';
import 'package:bloomwell/features/comfort/data/comfort_repository.dart';
import 'package:bloomwell/features/comfort/domain/entities/comfort_plan_item.dart';
import 'package:bloomwell/features/routines/application/routines_notifier.dart';
import 'package:bloomwell/features/routines/data/routines_repository.dart';
import 'package:bloomwell/features/routines/domain/entities/routine.dart';
import 'package:bloomwell/features/routines/domain/entities/routine_item.dart';
import 'package:bloomwell/features/self_care/application/self_care_notifier.dart';
import 'package:bloomwell/features/self_care/data/self_care_repository.dart';
import 'package:bloomwell/features/self_care/domain/entities/activity_category.dart';
import 'package:bloomwell/features/self_care/domain/entities/activity_completion_log.dart';
import 'package:bloomwell/features/self_care/domain/entities/activity_entry.dart';
import 'package:bloomwell/features/self_care/domain/entities/activity_suggestion.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const canaryRoutineTitle = 'CANARY_SECRET_ROUTINE_TITLE_9999';
const canaryExamTitle = 'CANARY_CONFIDENTIAL_EXAM_TITLE_8888';
const canaryActivitySummary = 'CANARY_VERY_SENSITIVE_NOTE_7777';
const canaryClientId = 'CANARY_CLIENT_ID_SECRET_6666';

class CanarySelfCareRepo implements ISelfCareRepository {
  @override
  Future<({List<ActivityEntry> items, String? nextCursor, bool hasMore})>
      getActivities({
    ActivityCategory? category,
    int? maxDuration,
    String? cursor,
    int limit = 20,
  }) async {
    return (
      items: [
        const ActivityEntry(
          id: 'canary-act-1',
          title: 'Canary Calm',
          category: ActivityCategory.comfort,
          durationMinutes: 5,
          summary: canaryActivitySummary,
          steps: ['Breathe gently'],
          source: 'Private',
        ),
      ],
      nextCursor: null,
      hasMore: false,
    );
  }

  @override
  Future<ActivityEntry> getActivityDetail(String id) async {
    return const ActivityEntry(
      id: 'canary-act-1',
      title: 'Canary Calm',
      category: ActivityCategory.comfort,
      durationMinutes: 5,
      summary: canaryActivitySummary,
      steps: ['Breathe gently'],
      source: 'Private',
    );
  }

  @override
  Future<bool> setFavorite({
    required String activityId,
    required bool isFavorite,
  }) async =>
      true;

  @override
  Future<ActivityCompletionLog> completeActivity({
    required String clientId,
    required String activityId,
    int? helpfulnessRating,
  }) async {
    return ActivityCompletionLog(
      id: 'log-canary',
      clientId: clientId,
      activityId: activityId,
      activityTitle: 'Canary Calm',
      activityCategory: ActivityCategory.comfort,
      completedAt: DateTime.now(),
      helpfulnessRating: helpfulnessRating,
    );
  }

  @override
  Future<({List<ActivityEntry> items, String? nextCursor, bool hasMore})>
      getFavorites({String? cursor, int limit = 50}) async =>
          (items: <ActivityEntry>[], nextCursor: null, hasMore: false);

  @override
  Future<List<ActivitySuggestion>> getSuggestions({
    required String need,
    int? maxDuration,
  }) async =>
      [];

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

class CanaryComfortRepo implements IComfortRepository {
  List<ComfortPlanItem> items = [];

  @override
  Future<List<ComfortPlanItem>> getComfortPlan() async => items;

  @override
  Future<ComfortPlanItem> addToComfortPlan({required String activityId}) async {
    final item = ComfortPlanItem(
      id: 'item-1',
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
          List<String> itemIds) async =>
      items;
}

class CanaryRoutinesRepo implements IRoutinesRepository {
  List<Routine> routines = [];

  @override
  Future<List<Routine>> getRoutines() async => routines;

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
      id: 'r-canary',
      title: title,
      startDate: startDate,
      endDate: endDate,
      createdAt: DateTime.now(),
      items: [],
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
    final r = Routine(
      id: id,
      title: title ?? canaryRoutineTitle,
      createdAt: DateTime.now(),
    );
    return r;
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
    return RoutineItem(
      id: 'canary-item',
      routineId: routineId,
      activityId: activityId,
      activityTitle: 'Canary Item',
      position: 0,
    );
  }

  @override
  Future<void> deleteItem({
    required String routineId,
    required String itemId,
  }) async {}

  @override
  Future<RoutineItem> updateItem({
    required String routineId,
    required String itemId,
    bool? isCompleted,
    int? position,
    DateTime? scheduledDate,
    bool clearScheduledDate = false,
  }) async {
    return RoutineItem(
      id: itemId,
      routineId: routineId,
      activityId: 'act-1',
      activityTitle: 'Canary Item',
      position: 0,
      completedAt: isCompleted == true ? DateTime.now() : null,
    );
  }

  @override
  Future<List<RoutineItem>> reorderItems({
    required String routineId,
    required List<String> itemIdsInOrder,
  }) async =>
      [];
}

class CanaryAcademicRepo implements IAcademicEventsRepository {
  List<AcademicEvent> events = [];

  @override
  Future<({List<AcademicEvent> items, String? nextCursor, bool hasMore})>
      getEvents({String? cursor, int limit = 20, bool? upcomingOnly}) async {
    return (items: events, nextCursor: null, hasMore: false);
  }

  @override
  Future<AcademicEvent> createEvent({
    required String clientId,
    required String title,
    required DateTime eventDate,
    required AcademicEventType eventType,
  }) async {
    final e = AcademicEvent(
      id: 'ev-canary',
      clientId: clientId,
      title: title,
      eventDate: eventDate,
      eventType: eventType,
      createdAt: DateTime.now(),
    );
    events.add(e);
    return e;
  }

  @override
  Future<AcademicEvent> updateEvent({
    required String id,
    String? title,
    DateTime? eventDate,
    AcademicEventType? eventType,
  }) async {
    final e = AcademicEvent(
      id: id,
      clientId: canaryClientId,
      title: title ?? canaryExamTitle,
      eventDate: eventDate ?? DateTime.now(),
      eventType: eventType ?? AcademicEventType.exam,
      createdAt: DateTime.now(),
    );
    return e;
  }

  @override
  Future<void> deleteEvent(String id) async {
    events.removeWhere((e) => e.id == id);
  }
}

void main() {
  group('Zero-Logging Privacy & Canary Data Guardrails', () {
    late ProviderContainer container;
    late CanarySelfCareRepo selfCareRepo;
    late CanaryComfortRepo comfortRepo;
    late CanaryRoutinesRepo routinesRepo;
    late CanaryAcademicRepo academicRepo;

    setUp(() {
      selfCareRepo = CanarySelfCareRepo();
      comfortRepo = CanaryComfortRepo();
      routinesRepo = CanaryRoutinesRepo();
      academicRepo = CanaryAcademicRepo();

      container = ProviderContainer(
        overrides: [
          selfCareRepositoryProvider.overrideWithValue(selfCareRepo),
          comfortRepositoryProvider.overrideWithValue(comfortRepo),
          routinesRepositoryProvider.overrideWithValue(routinesRepo),
          academicEventsRepositoryProvider.overrideWithValue(academicRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test(
        'Rule 4 & Rule 8: Zero-logging guardrail asserts sensitive canaries never leak to stdout/print',
        () async {
      final printedLines = <String>[];

      await runZoned(
        () async {
          // 1. Trigger Self-Care Activity completion
          final selfCareNotifier =
              container.read(selfCareNotifierProvider.notifier);
          await selfCareNotifier.loadActivities();
          await selfCareNotifier.completeActivity(
            activityId: 'canary-act-1',
            clientId: canaryClientId,
            helpfulnessRating: 5,
          );

          // 2. Trigger Comfort Plan operations
          final comfortNotifier =
              container.read(comfortNotifierProvider.notifier);
          await comfortNotifier.loadInitial();
          await comfortNotifier.addToPlan('canary-act-1');
          await comfortNotifier.removeFromPlan('item-1');

          // 3. Trigger Routines operations with sensitive routine title
          final routinesNotifier =
              container.read(routinesNotifierProvider.notifier);
          await routinesNotifier.loadRoutines();
          await routinesNotifier.createRoutine(
            title: canaryRoutineTitle,
            startDate: DateTime.now(),
          );
          await routinesNotifier.updateRoutine(
            id: 'r-canary',
            title: canaryRoutineTitle,
          );

          // 4. Trigger Academic Events operations with sensitive exam title
          final academicNotifier =
              container.read(academicEventsNotifierProvider.notifier);
          await academicNotifier.loadEvents();
          await academicNotifier.createEvent(
            clientId: canaryClientId,
            title: canaryExamTitle,
            eventDate: DateTime.now().add(const Duration(days: 7)),
            eventType: AcademicEventType.exam,
          );
          await academicNotifier.updateEvent(
            id: 'ev-canary',
            title: canaryExamTitle,
          );
          await academicNotifier.deleteEvent('ev-canary');
        },
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) {
            printedLines.add(line);
          },
        ),
      );

      // Verify ZERO sensitive canary strings exist in printed lines
      for (final line in printedLines) {
        expect(line.contains(canaryRoutineTitle), isFalse,
            reason:
                'Zero-logging violation: canary routine title leaked into print/logs: $line');
        expect(line.contains(canaryExamTitle), isFalse,
            reason:
                'Zero-logging violation: canary exam title leaked into print/logs: $line');
        expect(line.contains(canaryActivitySummary), isFalse,
            reason:
                'Zero-logging violation: canary sensitive activity note leaked into print/logs: $line');
        expect(line.contains(canaryClientId), isFalse,
            reason:
                'Zero-logging violation: canary client ID leaked into print/logs: $line');
      }
    });
  });
}
