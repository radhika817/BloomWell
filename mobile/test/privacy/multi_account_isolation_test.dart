import 'package:bloomwell/features/auth/application/auth_notifier.dart';
import 'package:bloomwell/features/auth/domain/entities/auth_state.dart';
import 'package:bloomwell/features/auth/domain/entities/user_entity.dart';
import 'package:bloomwell/features/comfort/application/comfort_notifier.dart';
import 'package:bloomwell/features/comfort/data/comfort_repository.dart';
import 'package:bloomwell/features/comfort/domain/entities/comfort_plan_item.dart';
import 'package:bloomwell/features/exams/application/academic_events_notifier.dart';
import 'package:bloomwell/features/exams/data/academic_events_repository.dart';
import 'package:bloomwell/features/exams/domain/entities/academic_event.dart';
import 'package:bloomwell/features/exams/domain/entities/academic_event_type.dart';
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

class FakeAuthNotifier extends AuthNotifier {
  final AuthState _initial;
  FakeAuthNotifier([this._initial = const AuthState.unauthenticated()]);

  @override
  AuthState build() => _initial;

  void authenticateUser(String id, String displayName) {
    state = AuthState.authenticated(
      user: UserEntity(
        id: id,
        displayName: displayName,
        role: 'student',
        language: 'en',
        timezone: 'Asia/Kolkata',
        createdAt: DateTime.now(),
      ),
      accessToken: 'token-$id',
    );
  }

  @override
  Future<void> logout() async {
    state = const AuthState.unauthenticated();
  }
}

class IsolatedSelfCareRepo implements ISelfCareRepository {
  String currentUserId = 'user-alpha';
  final Map<String, Set<String>> userFavorites = {
    'user-alpha': {'act-alpha-secret'},
    'user-beta': {'act-beta-secret'},
  };

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
          id: 'act-alpha-secret',
          title: 'Alpha Quiet Meditation',
          category: ActivityCategory.relaxation,
          durationMinutes: 5,
          summary: 'Private to Alpha',
          steps: ['Step 1'],
          source: 'Alpha',
        ),
        const ActivityEntry(
          id: 'act-beta-secret',
          title: 'Beta Soothing Breath',
          category: ActivityCategory.breathing,
          durationMinutes: 3,
          summary: 'Private to Beta',
          steps: ['Step 1'],
          source: 'Beta',
        ),
      ],
      nextCursor: null,
      hasMore: false,
    );
  }

  @override
  Future<ActivityEntry> getActivityDetail(String id) async => ActivityEntry(
        id: id,
        title: 'Activity $id',
        category: ActivityCategory.comfort,
        durationMinutes: 5,
        summary: 'Summary',
        steps: const [],
        source: 'Src',
      );

  @override
  Future<bool> setFavorite({
    required String activityId,
    required bool isFavorite,
  }) async {
    final favs = userFavorites.putIfAbsent(currentUserId, () => <String>{});
    if (isFavorite) {
      favs.add(activityId);
    } else {
      favs.remove(activityId);
    }
    return isFavorite;
  }

  @override
  Future<({List<ActivityEntry> items, String? nextCursor, bool hasMore})>
      getFavorites({String? cursor, int limit = 50}) async {
    final favIds = userFavorites[currentUserId] ?? <String>{};
    return (
      items: favIds
          .map((id) => ActivityEntry(
                id: id,
                title: 'Fav $id',
                category: ActivityCategory.comfort,
                durationMinutes: 5,
                summary: 'Fav',
                steps: const [],
                source: 'Src',
              ))
          .toList(),
      nextCursor: null,
      hasMore: false,
    );
  }

  @override
  Future<ActivityCompletionLog> completeActivity({
    required String clientId,
    required String activityId,
    int? helpfulnessRating,
  }) async =>
      ActivityCompletionLog(
        id: 'log-1',
        clientId: clientId,
        activityId: activityId,
        activityTitle: 'Activity',
        activityCategory: ActivityCategory.comfort,
        completedAt: DateTime.now(),
      );

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

class IsolatedComfortRepo implements IComfortRepository {
  String currentUserId = 'user-alpha';
  final Map<String, List<ComfortPlanItem>> userPlans = {
    'user-alpha': [
      ComfortPlanItem(
        id: 'plan-alpha',
        activityId: 'act-alpha-secret',
        position: 0,
        createdAt: DateTime.now(),
      ),
    ],
    'user-beta': [
      ComfortPlanItem(
        id: 'plan-beta',
        activityId: 'act-beta-secret',
        position: 0,
        createdAt: DateTime.now(),
      ),
    ],
  };

  @override
  Future<List<ComfortPlanItem>> getComfortPlan() async =>
      List.of(userPlans[currentUserId] ?? []);

  @override
  Future<ComfortPlanItem> addToComfortPlan({required String activityId}) async {
    final item = ComfortPlanItem(
      id: 'plan-$activityId',
      activityId: activityId,
      position: 0,
      createdAt: DateTime.now(),
    );
    userPlans.putIfAbsent(currentUserId, () => []).add(item);
    return item;
  }

  @override
  Future<void> removeFromComfortPlan(String itemId) async {
    userPlans[currentUserId]?.removeWhere((i) => i.id == itemId);
  }

  @override
  Future<List<ComfortPlanItem>> reorderComfortPlan(
          List<String> itemIds) async =>
      userPlans[currentUserId] ?? [];
}

class IsolatedRoutinesRepo implements IRoutinesRepository {
  String currentUserId = 'user-alpha';
  final Map<String, List<Routine>> userRoutines = {
    'user-alpha': [
      Routine(
        id: 'rt-alpha',
        title: 'Alpha Morning Ritual',
        createdAt: DateTime.now(),
        items: const [
          RoutineItem(
            id: 'item-alpha-1',
            routineId: 'rt-alpha',
            activityId: 'act-alpha',
            activityTitle: 'Alpha Routine Item',
            position: 0,
          ),
        ],
      ),
    ],
    'user-beta': [
      Routine(
        id: 'rt-beta',
        title: 'Beta Evening Ritual',
        createdAt: DateTime.now(),
        items: const [
          RoutineItem(
            id: 'item-beta-1',
            routineId: 'rt-beta',
            activityId: 'act-beta',
            activityTitle: 'Beta Routine Item',
            position: 0,
          ),
        ],
      ),
    ],
  };

  @override
  Future<List<Routine>> getRoutines() async =>
      List.of(userRoutines[currentUserId] ?? []);

  @override
  Future<Routine> getRoutine(String id) async =>
      userRoutines[currentUserId]!.firstWhere((r) => r.id == id);

  @override
  Future<Routine> createRoutine({
    required String title,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final r = Routine(
      id: 'rt-$title',
      title: title,
      createdAt: DateTime.now(),
      items: const [],
    );
    userRoutines.putIfAbsent(currentUserId, () => []).add(r);
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
    final r = Routine(id: id, title: title ?? '', createdAt: DateTime.now());
    return r;
  }

  @override
  Future<void> deleteRoutine(String id) async {
    userRoutines[currentUserId]?.removeWhere((r) => r.id == id);
  }

  @override
  Future<RoutineItem> addItem({
    required String routineId,
    required String activityId,
    DateTime? scheduledDate,
  }) async =>
      RoutineItem(
        id: 'item-$activityId',
        routineId: routineId,
        activityId: activityId,
        activityTitle: 'Item',
        position: 0,
      );

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
  }) async =>
      RoutineItem(
        id: itemId,
        routineId: routineId,
        activityId: 'act',
        activityTitle: 'Item',
        position: 0,
        completedAt: isCompleted == true ? DateTime.now() : null,
      );

  @override
  Future<List<RoutineItem>> reorderItems({
    required String routineId,
    required List<String> itemIdsInOrder,
  }) async =>
      [];
}

class IsolatedAcademicRepo implements IAcademicEventsRepository {
  String currentUserId = 'user-alpha';
  final Map<String, List<AcademicEvent>> userEvents = {
    'user-alpha': [
      AcademicEvent(
        id: 'ev-alpha',
        clientId: 'cid-alpha',
        title: 'Alpha Private Exam',
        eventDate: DateTime.now().add(const Duration(days: 3)),
        eventType: AcademicEventType.exam,
        createdAt: DateTime.now(),
      ),
    ],
    'user-beta': [
      AcademicEvent(
        id: 'ev-beta',
        clientId: 'cid-beta',
        title: 'Beta Private Exam',
        eventDate: DateTime.now().add(const Duration(days: 10)),
        eventType: AcademicEventType.assignment,
        createdAt: DateTime.now(),
      ),
    ],
  };

  @override
  Future<({List<AcademicEvent> items, String? nextCursor, bool hasMore})>
      getEvents({String? cursor, int limit = 20, bool? upcomingOnly}) async => (
            items: List<AcademicEvent>.from(userEvents[currentUserId] ?? []),
            nextCursor: null,
            hasMore: false
          );

  @override
  Future<AcademicEvent> createEvent({
    required String clientId,
    required String title,
    required DateTime eventDate,
    required AcademicEventType eventType,
  }) async {
    final e = AcademicEvent(
      id: 'ev-$title',
      clientId: clientId,
      title: title,
      eventDate: eventDate,
      eventType: eventType,
      createdAt: DateTime.now(),
    );
    userEvents.putIfAbsent(currentUserId, () => []).add(e);
    return e;
  }

  @override
  Future<AcademicEvent> updateEvent({
    required String id,
    String? title,
    DateTime? eventDate,
    AcademicEventType? eventType,
  }) async =>
      AcademicEvent(
        id: id,
        clientId: 'cid',
        title: title ?? '',
        eventDate: eventDate ?? DateTime.now(),
        eventType: eventType ?? AcademicEventType.exam,
        createdAt: DateTime.now(),
      );

  @override
  Future<void> deleteEvent(String id) async {
    userEvents[currentUserId]?.removeWhere((e) => e.id == id);
  }
}

void main() {
  group('Rule 5, 8 & 13: Multi-Account Isolation & In-Memory Purge Tests', () {
    late IsolatedSelfCareRepo selfCareRepo;
    late IsolatedComfortRepo comfortRepo;
    late IsolatedRoutinesRepo routinesRepo;
    late IsolatedAcademicRepo academicRepo;
    late ProviderContainer container;

    setUp(() {
      selfCareRepo = IsolatedSelfCareRepo();
      comfortRepo = IsolatedComfortRepo();
      routinesRepo = IsolatedRoutinesRepo();
      academicRepo = IsolatedAcademicRepo();

      container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(() => FakeAuthNotifier()),
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
        'Account A populates private state -> logout completely purges in-memory state -> Account B sees zero data from Account A',
        () async {
      // 1. Account A logs in
      final authNotifier =
          container.read(authNotifierProvider.notifier) as FakeAuthNotifier;
      authNotifier.authenticateUser('user-alpha', 'Alpha Student');
      selfCareRepo.currentUserId = 'user-alpha';
      comfortRepo.currentUserId = 'user-alpha';
      routinesRepo.currentUserId = 'user-alpha';
      academicRepo.currentUserId = 'user-alpha';

      // 2. Load Account A's state in all notifiers
      final selfCare = container.read(selfCareNotifierProvider.notifier);
      final comfort = container.read(comfortNotifierProvider.notifier);
      final routines = container.read(routinesNotifierProvider.notifier);
      final exams = container.read(academicEventsNotifierProvider.notifier);

      await selfCare.loadActivities();
      await comfort.loadInitial();
      await routines.loadRoutines();
      await exams.loadEvents();

      // Verify Account A has their data loaded in memory
      expect(container.read(selfCareNotifierProvider).favorites,
          contains('act-alpha-secret'));
      expect(
          container
              .read(comfortNotifierProvider)
              .comfortPlan
              .any((i) => i.activityId == 'act-alpha-secret'),
          isTrue);
      expect(
          container
              .read(routinesNotifierProvider)
              .routines
              .any((r) => r.title == 'Alpha Morning Ritual'),
          isTrue);
      expect(
          container
              .read(academicEventsNotifierProvider)
              .events
              .any((e) => e.title == 'Alpha Private Exam'),
          isTrue);

      // 3. User A logs out (Auth state transition to unauthenticated)
      await authNotifier.logout();

      // 4. Assert ALL in-memory user data is purged immediately upon logout
      expect(container.read(selfCareNotifierProvider).favorites, isEmpty,
          reason: 'Self-care favorites must be purged on logout');
      expect(container.read(comfortNotifierProvider).comfortPlan, isEmpty,
          reason: 'Comfort plan items must be purged on logout');
      expect(container.read(routinesNotifierProvider).routines, isEmpty,
          reason: 'Routines must be purged on logout');
      expect(container.read(academicEventsNotifierProvider).events, isEmpty,
          reason: 'Academic events must be purged on logout');

      // 5. User B logs in (Account Beta)
      authNotifier.authenticateUser('user-beta', 'Beta Student');
      selfCareRepo.currentUserId = 'user-beta';
      comfortRepo.currentUserId = 'user-beta';
      routinesRepo.currentUserId = 'user-beta';
      academicRepo.currentUserId = 'user-beta';

      // 6. Account B loads their data
      await selfCare.loadActivities();
      await comfort.loadInitial();
      await routines.loadRoutines();
      await exams.loadEvents();

      // 7. Verify Account B sees only their data and ZERO data from Account A
      final betaFavs = container.read(selfCareNotifierProvider).favorites;
      expect(betaFavs.contains('act-alpha-secret'), isFalse,
          reason: 'Account B must never see Account A favorites');
      expect(betaFavs.contains('act-beta-secret'), isTrue);

      final betaComfort = container.read(comfortNotifierProvider).comfortPlan;
      expect(
          betaComfort.any((i) => i.activityId == 'act-alpha-secret'), isFalse,
          reason: 'Account B must never see Account A comfort plan items');
      expect(betaComfort.any((i) => i.activityId == 'act-beta-secret'), isTrue);

      final betaRoutines = container.read(routinesNotifierProvider).routines;
      expect(
          betaRoutines.any((r) => r.title == 'Alpha Morning Ritual'), isFalse,
          reason: 'Account B must never see Account A routines');
      expect(betaRoutines.any((r) => r.title == 'Beta Evening Ritual'), isTrue);

      final betaExams = container.read(academicEventsNotifierProvider).events;
      expect(betaExams.any((e) => e.title == 'Alpha Private Exam'), isFalse,
          reason: 'Account B must never see Account A exams');
      expect(betaExams.any((e) => e.title == 'Beta Private Exam'), isTrue);
    });
  });
}
