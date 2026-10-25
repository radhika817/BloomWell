import 'package:bloomwell/app/theme/app_theme.dart';
import 'package:bloomwell/features/app_lock/application/app_lock_notifier.dart';
import 'package:bloomwell/features/app_lock/domain/app_lock_config.dart';
import 'package:bloomwell/features/self_care/application/self_care_notifier.dart';
import 'package:bloomwell/features/self_care/data/self_care_repository.dart';
import 'package:bloomwell/features/self_care/domain/entities/activity_category.dart';
import 'package:bloomwell/features/self_care/domain/entities/activity_completion_log.dart';
import 'package:bloomwell/features/self_care/domain/entities/activity_entry.dart';
import 'package:bloomwell/features/self_care/domain/entities/activity_suggestion.dart';
import 'package:bloomwell/features/self_care/presentation/screens/activity_history_screen.dart';
import 'package:bloomwell/features/self_care/presentation/screens/self_care_studio_screen.dart';
import 'package:bloomwell/features/self_care/presentation/widgets/activity_card.dart';
import 'package:bloomwell/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class StudioFakeRepo implements ISelfCareRepository {
  List<ActivityEntry> activities = [
    const ActivityEntry(
      id: 'act-1',
      title: 'Box Breathing',
      category: ActivityCategory.breathing,
      durationMinutes: 4,
      summary: 'Soothing four-count breathing cycle.',
      steps: [
        'Breathe in for 4',
        'Hold for 4',
        'Breathe out for 4',
        'Hold for 4'
      ],
      source: 'Campus Health Guide',
      slug: 'box-breathing',
    ),
    const ActivityEntry(
      id: 'act-2',
      title: 'Warm Herbal Tea Break',
      category: ActivityCategory.comfort,
      durationMinutes: 10,
      summary: 'Pause and enjoy a quiet warm cup.',
      steps: ['Steep tea', 'Sip mindfully'],
      source: 'Student Wellness',
    ),
  ];

  Set<String> favorites = {'act-1'};
  List<ActivityCompletionLog> history = [
    ActivityCompletionLog(
      id: 'log-1',
      clientId: 'cid-1',
      activityId: 'act-1',
      activityTitle: 'Box Breathing',
      activityCategory: ActivityCategory.breathing,
      completedAt: DateTime.utc(2026, 10, 24, 15, 30),
      helpfulnessRating: 5,
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
    var filtered = activities;
    if (category != null) {
      filtered = filtered.where((a) => a.category == category).toList();
    }
    if (maxDuration != null) {
      filtered =
          filtered.where((a) => a.durationMinutes <= maxDuration).toList();
    }
    return (items: List.of(filtered), nextCursor: null, hasMore: false);
  }

  @override
  Future<ActivityEntry> getActivityDetail(String id) async {
    return activities.firstWhere((a) => a.id == id);
  }

  @override
  Future<List<ActivitySuggestion>> getSuggestions({
    required String need,
    int? maxDuration,
  }) async =>
      [];

  @override
  Future<({List<ActivityEntry> items, String? nextCursor, bool hasMore})>
      getFavorites({
    String? cursor,
    int limit = 50,
  }) async {
    final favList = activities.where((a) => favorites.contains(a.id)).toList();
    return (items: List.of(favList), nextCursor: null, hasMore: false);
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
    final log = ActivityCompletionLog(
      id: 'log-${history.length + 1}',
      clientId: clientId,
      activityId: activityId,
      activityTitle: 'Completed',
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
      })> getActivityHistory({String? cursor, int limit = 20}) async {
    return (items: List.of(history), nextCursor: null, hasMore: false);
  }
}

class MockLockNotifier extends AppLockNotifier {
  final bool _locked;
  MockLockNotifier(this._locked) : super();

  @override
  AppLockState build() =>
      const AppLockState.initial().copyWith(isLocked: _locked);
}

Widget buildTestWrapper({
  required Widget child,
  required StudioFakeRepo fakeRepo,
  bool isLocked = false,
}) {
  return ProviderScope(
    overrides: [
      selfCareRepositoryProvider.overrideWithValue(fakeRepo),
      appLockNotifierProvider.overrideWith(() => MockLockNotifier(isLocked)),
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
  group('SelfCareStudioScreen Widget Tests', () {
    late StudioFakeRepo fakeRepo;

    setUp(() {
      fakeRepo = StudioFakeRepo();
    });

    testWidgets('renders studio header, chips, action buttons and activities',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper(
        child: const SelfCareStudioScreen(),
        fakeRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Self-Care Studio'), findsOneWidget);
      expect(
        find.text('Curated gentle practices for body, mind, and study breaks.'),
        findsOneWidget,
      );
      expect(find.text('Routines'), findsOneWidget);
      expect(find.text('My activity history'), findsOneWidget);

      // Verify activity cards loaded
      expect(find.text('Box Breathing'), findsOneWidget);
      expect(find.text('Warm Herbal Tea Break'), findsOneWidget);
      expect(find.text('Comfort'), findsWidgets);
    });

    testWidgets('toggling favorite calls repo and updates heart icon',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper(
        child: const SelfCareStudioScreen(),
        fakeRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      final addFavFinder = find.byIcon(Icons.favorite_border_rounded);
      expect(addFavFinder, findsOneWidget);

      await tester.tap(addFavFinder);
      await tester.pumpAndSettle();

      expect(fakeRepo.favorites.contains('act-2'), isTrue);
    });

    testWidgets('filtering by Breathing category shows only breathing activity',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper(
        child: const SelfCareStudioScreen(),
        fakeRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Box Breathing'), findsOneWidget);
      expect(find.text('Warm Herbal Tea Break'), findsOneWidget);

      // Tap 'Breathing' category chip
      await tester.tap(find.text('Breathing'));
      await tester.pumpAndSettle();

      expect(find.text('Box Breathing'), findsOneWidget);
      expect(find.text('Warm Herbal Tea Break'), findsNothing);
    });

    testWidgets('empty filter result shows gentle empty state', (tester) async {
      await tester.pumpWidget(buildTestWrapper(
        child: const SelfCareStudioScreen(),
        fakeRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      // Tap 'Grounding' category chip where fakeRepo has no items
      await tester.tap(find.text('Grounding'));
      await tester.pumpAndSettle();

      expect(find.text('No activities match this filter'), findsOneWidget);
      expect(
        find.text('Try choosing a different category or longer duration.'),
        findsOneWidget,
      );
    });

    testWidgets('when app is locked, screen is blank for privacy',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper(
        child: const SelfCareStudioScreen(),
        fakeRepo: fakeRepo,
        isLocked: true,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Self-Care Studio'), findsNothing);
      expect(find.text('Box Breathing'), findsNothing);
    });
  });

  group('ActivityCard Widget Tests', () {
    testWidgets('renders activity details and taps trigger callbacks',
        (tester) async {
      bool tapped = false;
      bool favToggled = false;

      const testActivity = ActivityEntry(
        id: 'act-test',
        title: 'Mindful Walking',
        category: ActivityCategory.movement,
        durationMinutes: 5,
        summary: 'Gentle steps with natural breath.',
        steps: ['Walk slowly'],
        source: 'Campus Guide',
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ActivityCard(
              activity: testActivity,
              isFavorite: false,
              onTap: () => tapped = true,
              onFavoriteToggle: () => favToggled = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mindful Walking'), findsOneWidget);
      expect(find.text('5 min'), findsOneWidget);
      expect(find.text('Gentle steps with natural breath.'), findsOneWidget);

      await tester.tap(find.text('Mindful Walking'));
      expect(tapped, isTrue);

      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      expect(favToggled, isTrue);
    });
  });

  group('ActivityHistoryScreen Widget Tests', () {
    late StudioFakeRepo fakeRepo;

    setUp(() {
      fakeRepo = StudioFakeRepo();
    });

    testWidgets('renders history list with date and rating', (tester) async {
      await tester.pumpWidget(buildTestWrapper(
        child: const ActivityHistoryScreen(),
        fakeRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('My Activity History'), findsOneWidget);
      expect(
        find.text('A quiet record of your gentle moments.'),
        findsOneWidget,
      );
      expect(find.text('Box Breathing'), findsOneWidget);
      expect(find.text('2026-10-24'), findsOneWidget);
      expect(find.text('★ 5'), findsOneWidget);
    });

    testWidgets('empty history displays gentle calm notice', (tester) async {
      fakeRepo.history = [];

      await tester.pumpWidget(buildTestWrapper(
        child: const ActivityHistoryScreen(),
        fakeRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      expect(
        find.text('No completed activities yet. Take your time.'),
        findsOneWidget,
      );
    });
  });
}
