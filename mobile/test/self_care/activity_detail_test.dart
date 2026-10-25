import 'package:bloomwell/app/theme/app_theme.dart';
import 'package:bloomwell/features/app_lock/application/app_lock_notifier.dart';
import 'package:bloomwell/features/app_lock/domain/app_lock_config.dart';
import 'package:bloomwell/features/self_care/application/self_care_notifier.dart';
import 'package:bloomwell/features/self_care/data/self_care_repository.dart';
import 'package:bloomwell/features/self_care/domain/entities/activity_category.dart';
import 'package:bloomwell/features/self_care/domain/entities/activity_completion_log.dart';
import 'package:bloomwell/features/self_care/domain/entities/activity_entry.dart';
import 'package:bloomwell/features/self_care/domain/entities/activity_suggestion.dart';
import 'package:bloomwell/features/self_care/presentation/screens/activity_detail_screen.dart';
import 'package:bloomwell/features/self_care/presentation/widgets/step_by_step_guide_dialog.dart';
import 'package:bloomwell/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class DetailFakeRepo implements ISelfCareRepository {
  final Map<String, ActivityEntry> activities = {
    'act-comfort': const ActivityEntry(
      id: 'act-comfort',
      title: 'Warm Heating Pad Rest',
      category: ActivityCategory.comfort,
      durationMinutes: 15,
      summary: 'Rest comfortably with gentle warmth on your lower abdomen.',
      steps: [
        'Place a warm heating pad or warm water bottle comfortably.',
        'Settle into a relaxed position with a soft pillow under knees.',
        'Take slow, soothing breaths and rest without urgency.',
      ],
      source: 'Student Health & Wellness',
    ),
    'act-breathing': const ActivityEntry(
      id: 'act-breathing',
      title: 'Box Breathing',
      category: ActivityCategory.breathing,
      durationMinutes: 4,
      summary: 'Four count calm rhythm.',
      steps: ['Breathe in', 'Hold', 'Breathe out', 'Rest'],
      source: 'Calm somatic study',
      slug: 'box-breathing',
    ),
  };

  Set<String> favorites = {};
  List<ActivityCompletionLog> history = [];
  int completeCalls = 0;
  String? lastClientId;
  int? lastRating;
  bool shouldFailOnce = false;

  @override
  Future<ActivityEntry> getActivityDetail(String id) async {
    final act = activities[id];
    if (act == null) throw Exception('Activity not found');
    return act;
  }

  @override
  Future<({List<ActivityEntry> items, String? nextCursor, bool hasMore})>
      getActivities({
    ActivityCategory? category,
    int? maxDuration,
    String? cursor,
    int limit = 20,
  }) async {
    return (
      items: activities.values.toList(),
      nextCursor: null,
      hasMore: false
    );
  }

  @override
  Future<({List<ActivityEntry> items, String? nextCursor, bool hasMore})>
      getFavorites({String? cursor, int limit = 50}) async {
    return (items: <ActivityEntry>[], nextCursor: null, hasMore: false);
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
  }) async {
    completeCalls++;
    lastClientId = clientId;
    lastRating = helpfulnessRating;

    if (shouldFailOnce) {
      shouldFailOnce = false;
      throw Exception('Temporary network issue');
    }

    final log = ActivityCompletionLog(
      id: 'log-$completeCalls',
      clientId: clientId,
      activityId: activityId,
      activityTitle: activities[activityId]?.title ?? 'Activity',
      activityCategory:
          activities[activityId]?.category ?? ActivityCategory.comfort,
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
      })> getActivityHistory({String? cursor, int limit = 20}) async {
    return (items: history, nextCursor: null, hasMore: false);
  }
}

class MockLockNotifier extends AppLockNotifier {
  @override
  AppLockState build() => const AppLockState.initial();
}

Widget buildDetailApp({
  required Widget child,
  required DetailFakeRepo fakeRepo,
}) {
  return ProviderScope(
    overrides: [
      selfCareRepositoryProvider.overrideWithValue(fakeRepo),
      appLockNotifierProvider.overrideWith(() => MockLockNotifier()),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  group('ActivityDetailScreen Tests', () {
    late DetailFakeRepo fakeRepo;

    setUp(() {
      fakeRepo = DetailFakeRepo();
    });

    testWidgets(
        'renders detail for comfort activity with mandatory doctor note and source',
        (tester) async {
      await tester.pumpWidget(buildDetailApp(
        child: const ActivityDetailScreen(activityId: 'act-comfort'),
        fakeRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Warm Heating Pad Rest'), findsOneWidget);
      expect(find.text('15 min'), findsOneWidget);
      expect(
        find.text(
          'If symptoms feel severe, unusual or last a long time, talking to a doctor or nurse can help.',
        ),
        findsOneWidget,
      );
      expect(find.text('Source: Student Health & Wellness'), findsOneWidget);
      expect(find.text('Start gentle guide'), findsOneWidget);
    });

    testWidgets(
        'breathing activity does not show doctor note and renders breathing action',
        (tester) async {
      await tester.pumpWidget(buildDetailApp(
        child: const ActivityDetailScreen(activityId: 'act-breathing'),
        fakeRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Box Breathing'), findsOneWidget);
      expect(
        find.text(
          'If symptoms feel severe, unusual or last a long time, talking to a doctor or nurse can help.',
        ),
        findsNothing,
      );
      expect(find.text('Start Quick Session'), findsOneWidget);
      expect(find.text('Start gentle guide'), findsOneWidget);
    });
  });

  group('StepByStepGuideDialog Tests', () {
    late DetailFakeRepo fakeRepo;

    setUp(() {
      fakeRepo = DetailFakeRepo();
    });

    testWidgets(
        'steps progress with Next, Back, Done and records rating with server confirmation',
        (tester) async {
      final activity = fakeRepo.activities['act-breathing']!;

      await tester.pumpWidget(buildDetailApp(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => StepByStepGuideDialog.show(context, activity),
            child: const Text('Open Dialog'),
          ),
        ),
        fakeRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Step 1: Breathe in
      expect(find.text('Step 1 of 4'), findsOneWidget);
      expect(find.text('Breathe in'), findsOneWidget);
      expect(find.text('Back'), findsNothing);

      // Tap Next -> Step 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Step 2 of 4'), findsOneWidget);
      expect(find.text('Hold'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);

      // Tap Next -> Step 3
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Step 3 of 4'), findsOneWidget);

      // Tap Next -> Step 4 (last step)
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Step 4 of 4'), findsOneWidget);
      expect(find.text('Rest'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      // Tap Done -> Transitions to rating phase
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('Did this help?'), findsOneWidget);
      expect(
        find.text(
          'Optional feedback to help suggest gentler activities for you.',
        ),
        findsOneWidget,
      );
      expect(find.text('Skip'), findsOneWidget);

      // Tap star 5 and Done
      final starIcons = find.byIcon(Icons.star_outline_rounded);
      expect(starIcons, findsNWidgets(5));
      await tester.tap(starIcons.last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Verify completion was recorded on repo
      expect(fakeRepo.completeCalls, equals(1));
      expect(fakeRepo.lastRating, equals(5));
      expect(fakeRepo.lastClientId, isNotNull);
      expect(
        find.text('Activity completed and logged gently.'),
        findsOneWidget,
      );
    });

    testWidgets('retry on failure reuses same client_id for idempotency',
        (tester) async {
      final activity = fakeRepo.activities['act-breathing']!;
      fakeRepo.shouldFailOnce = true;

      await tester.pumpWidget(buildDetailApp(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => StepByStepGuideDialog.show(context, activity),
            child: const Text('Open Dialog'),
          ),
        ),
        fakeRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Fast forward to last step
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Tap Skip -> fails once
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(fakeRepo.completeCalls, equals(1));
      final firstClientId = fakeRepo.lastClientId;
      expect(firstClientId, isNotNull);
      expect(find.text('Temporary network issue'), findsOneWidget);

      // Retry by tapping Skip again
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(fakeRepo.completeCalls, equals(2));
      expect(fakeRepo.lastClientId, equals(firstClientId));
      expect(
        find.text('Activity completed and logged gently.'),
        findsOneWidget,
      );
    });
  });
}
