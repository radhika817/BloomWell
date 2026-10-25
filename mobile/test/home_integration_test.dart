import 'package:bloomwell/app/app.dart';
import 'package:bloomwell/app/router.dart';
import 'package:bloomwell/core/widgets/bloom_button.dart';
import 'package:bloomwell/features/app_lock/application/app_lock_notifier.dart';
import 'package:bloomwell/features/app_lock/domain/app_lock_config.dart';
import 'package:bloomwell/features/comfort/application/comfort_notifier.dart';
import 'package:bloomwell/features/comfort/data/comfort_repository.dart';
import 'package:bloomwell/features/comfort/domain/entities/comfort_plan_item.dart';
import 'package:bloomwell/features/comfort/presentation/comfort_screen.dart';
import 'package:bloomwell/features/exams/application/academic_events_notifier.dart';
import 'package:bloomwell/features/exams/data/academic_events_repository.dart';
import 'package:bloomwell/features/exams/domain/entities/academic_event.dart';
import 'package:bloomwell/features/exams/domain/entities/academic_event_type.dart';
import 'package:bloomwell/features/exams/presentation/exams_screen.dart';
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
import 'package:bloomwell/features/self_care/presentation/screens/activity_history_screen.dart';
import 'package:bloomwell/features/self_care/presentation/screens/self_care_studio_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockLockNotifier extends AppLockNotifier {
  @override
  AppLockState build() => const AppLockState.initial();
}

class FakeSelfCareRepo implements ISelfCareRepository {
  final List<ActivityEntry> activities = [
    const ActivityEntry(
      id: 'act-1',
      title: 'Box Breathing',
      category: ActivityCategory.breathing,
      durationMinutes: 4,
      summary: 'Soothing four-count breathing cycle.',
      steps: ['Breathe in', 'Hold', 'Breathe out', 'Hold'],
      source: 'Campus Health Guide',
    ),
  ];

  @override
  Future<({List<ActivityEntry> items, String? nextCursor, bool hasMore})>
      getActivities({
    ActivityCategory? category,
    int? maxDuration,
    String? cursor,
    int limit = 20,
  }) async {
    return (items: List.of(activities), nextCursor: null, hasMore: false);
  }

  @override
  Future<ActivityEntry> getActivityDetail(String id) async {
    return activities.firstWhere((a) => a.id == id);
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
      id: 'log-1',
      clientId: clientId,
      activityId: activityId,
      activityTitle: 'Box Breathing',
      activityCategory: ActivityCategory.breathing,
      completedAt: DateTime.now(),
    );
  }

  @override
  Future<({List<ActivityEntry> items, String? nextCursor, bool hasMore})>
      getFavorites({String? cursor, int limit = 50}) async {
    return (items: <ActivityEntry>[], nextCursor: null, hasMore: false);
  }

  @override
  Future<List<ActivitySuggestion>> getSuggestions({
    required String need,
    int? maxDuration,
  }) async {
    return [];
  }

  @override
  Future<
      ({
        List<ActivityCompletionLog> items,
        String? nextCursor,
        bool hasMore
      })> getActivityHistory({String? cursor, int limit = 20}) async {
    return (items: <ActivityCompletionLog>[], nextCursor: null, hasMore: false);
  }
}

class FakeComfortRepo implements IComfortRepository {
  @override
  Future<List<ComfortPlanItem>> getComfortPlan() async => [];

  @override
  Future<ComfortPlanItem> addToComfortPlan({required String activityId}) async {
    return ComfortPlanItem(
      id: 'plan-item-1',
      activityId: activityId,
      position: 0,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> removeFromComfortPlan(String itemId) async {}

  @override
  Future<List<ComfortPlanItem>> reorderComfortPlan(
          List<String> itemIds) async =>
      [];
}

class FakeRoutinesRepo implements IRoutinesRepository {
  @override
  Future<List<Routine>> getRoutines() async => [];

  @override
  Future<Routine> getRoutine(String id) async => Routine(
        id: id,
        title: 'Routine',
        createdAt: DateTime.now(),
        items: [],
      );

  @override
  Future<Routine> createRoutine({
    required String title,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return Routine(
      id: 'r-1',
      title: title,
      startDate: startDate,
      endDate: endDate,
      createdAt: DateTime.now(),
      items: [],
    );
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
    return Routine(id: id, title: title ?? 'R', createdAt: DateTime.now());
  }

  @override
  Future<void> deleteRoutine(String id) async {}

  @override
  Future<RoutineItem> addItem({
    required String routineId,
    required String activityId,
    DateTime? scheduledDate,
  }) async {
    return RoutineItem(
      id: 'item-1',
      routineId: routineId,
      activityId: activityId,
      activityTitle: 'Activity',
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
      activityTitle: 'Activity',
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

class FakeAcademicRepo implements IAcademicEventsRepository {
  @override
  Future<({List<AcademicEvent> items, String? nextCursor, bool hasMore})>
      getEvents({String? cursor, int limit = 20, bool? upcomingOnly}) async {
    return (items: <AcademicEvent>[], nextCursor: null, hasMore: false);
  }

  @override
  Future<AcademicEvent> createEvent({
    required String clientId,
    required String title,
    required DateTime eventDate,
    required AcademicEventType eventType,
  }) async {
    return AcademicEvent(
      id: 'ev-1',
      clientId: clientId,
      title: title,
      eventDate: eventDate,
      eventType: eventType,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<AcademicEvent> updateEvent({
    required String id,
    String? title,
    DateTime? eventDate,
    AcademicEventType? eventType,
  }) async {
    return AcademicEvent(
      id: id,
      clientId: 'c-1',
      title: title ?? '',
      eventDate: eventDate ?? DateTime.now(),
      eventType: eventType ?? AcademicEventType.exam,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteEvent(String id) async {}
}

Widget createIntegrationTestApp() {
  return ProviderScope(
    overrides: [
      selfCareRepositoryProvider.overrideWithValue(FakeSelfCareRepo()),
      comfortRepositoryProvider.overrideWithValue(FakeComfortRepo()),
      routinesRepositoryProvider.overrideWithValue(FakeRoutinesRepo()),
      academicEventsRepositoryProvider.overrideWithValue(FakeAcademicRepo()),
      appLockNotifierProvider.overrideWith(() => MockLockNotifier()),
    ],
    child: const BloomWellApp(),
  );
}

void main() {
  group('Home Screen & Feature Routes Integration Tests', () {
    testWidgets('Home screen displays Self-Care Studio banner and navigates',
        (tester) async {
      appRouter.go('/');
      await tester.pumpWidget(createIntegrationTestApp());
      await tester.pumpAndSettle();

      // Scroll down to make banner visible
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -1100),
      );
      await tester.pumpAndSettle();

      final banner = find.byKey(const Key('home_self_care_studio_banner'));
      expect(banner, findsOneWidget);

      await tester.tap(find.widgetWithText(BloomButton, 'Open Studio'));
      await tester.pumpAndSettle();

      // Verify Self-Care Studio screen is loaded
      expect(find.byType(SelfCareStudioScreen), findsOneWidget);
      expect(find.text('Self-Care Studio'), findsWidgets);
    });

    testWidgets('Home screen "Routines" navigates to RoutinesScreen',
        (tester) async {
      appRouter.go('/');
      await tester.pumpWidget(createIntegrationTestApp());
      await tester.pumpAndSettle();

      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -1100),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(BloomButton, 'Routines'));
      await tester.pumpAndSettle();

      // Verify Routines screen is loaded
      expect(find.byType(RoutinesScreen), findsOneWidget);
      expect(find.text('Routines'), findsWidgets);
    });

    testWidgets(
        'Home screen "I\'m having a hard day" navigates to ComfortScreen',
        (tester) async {
      appRouter.go('/');
      await tester.pumpWidget(createIntegrationTestApp());
      await tester.pumpAndSettle();

      final hardDayButton = find.text('I\'m having a hard day 🤍');
      expect(hardDayButton, findsOneWidget);
      await tester.ensureVisible(hardDayButton);
      await tester.tap(hardDayButton);
      await tester.pumpAndSettle();

      // Verify Comfort Mode screen is displayed
      expect(find.byType(ComfortScreen), findsOneWidget);
      expect(find.text('A gentle moment'), findsWidgets);
    });

    testWidgets('Direct route to /exams opens ExamsScreen', (tester) async {
      appRouter.go('/exams');
      await tester.pumpWidget(createIntegrationTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(ExamsScreen), findsOneWidget);
      expect(find.text('Exams & Deadlines'), findsOneWidget);
    });

    testWidgets(
        'Direct route to /self-care/history opens ActivityHistoryScreen',
        (tester) async {
      appRouter.go('/self-care/history');
      await tester.pumpWidget(createIntegrationTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(ActivityHistoryScreen), findsOneWidget);
      expect(find.text('My Activity History'), findsOneWidget);
    });
  });
}
