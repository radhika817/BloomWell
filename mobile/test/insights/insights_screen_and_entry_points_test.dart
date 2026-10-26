import 'package:bloomwell/core/widgets/app_card.dart';
import 'package:bloomwell/features/exams/application/academic_events_notifier.dart';
import 'package:bloomwell/features/exams/data/academic_events_repository.dart';
import 'package:bloomwell/features/exams/domain/entities/academic_event.dart';
import 'package:bloomwell/features/exams/presentation/exams_screen.dart';
import 'package:bloomwell/features/home/presentation/home_screen.dart';
import 'package:bloomwell/features/insights/application/insights_notifier.dart';
import 'package:bloomwell/features/insights/data/insights_repository.dart';
import 'package:bloomwell/features/insights/domain/entities/exam_context_insights.dart';
import 'package:bloomwell/features/insights/domain/entities/insight_status.dart';
import 'package:bloomwell/features/insights/domain/entities/weekly_insights.dart';
import 'package:bloomwell/features/insights/presentation/insights_screen.dart';
import 'package:bloomwell/features/mood/presentation/mood_screen.dart';
import 'package:bloomwell/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeInsightsRepo implements IInsightsRepository {
  WeeklyInsights? weekly;
  ExamContextInsights? exam;

  @override
  Future<WeeklyInsights> getWeeklyInsights({String? weekStart}) async =>
      weekly ??
      const WeeklyInsights(
        status: InsightStatus.notEnoughData,
        weekStart: '2026-10-19',
        daysNeeded: WeeklyDaysNeeded(week: 2, baseline: 1),
      );

  @override
  Future<ExamContextInsights> getExamContextInsights() async =>
      exam ?? const ExamContextInsights(status: InsightStatus.notEnoughData);
}

class _FakeExamsRepo implements IAcademicEventsRepository {
  @override
  Future<({List<AcademicEvent> items, String? nextCursor, bool hasMore})>
      getEvents({bool? upcomingOnly, String? cursor, int limit = 50}) async {
    return (items: <AcademicEvent>[], nextCursor: null, hasMore: false);
  }

  @override
  Future<AcademicEvent> createEvent({
    required String clientId,
    required String title,
    required DateTime eventDate,
    required dynamic eventType,
  }) =>
      throw UnimplementedError();

  @override
  Future<AcademicEvent> updateEvent({
    required String id,
    String? title,
    DateTime? eventDate,
    dynamic eventType,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> deleteEvent(String id) async {}
}

Widget _buildTestApp(Widget child, _FakeInsightsRepo fakeRepo) {
  return ProviderScope(
    overrides: [
      insightsRepositoryProvider.overrideWithValue(fakeRepo),
      academicEventsRepositoryProvider.overrideWithValue(_FakeExamsRepo()),
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InsightsScreen & Entry Points Tests', () {
    late _FakeInsightsRepo fakeRepo;

    setUp(() {
      fakeRepo = _FakeInsightsRepo();
    });

    testWidgets(
        'InsightsScreen renders observations and non-diagnostic disclaimer without scores or percentages',
        (tester) async {
      fakeRepo.weekly = const WeeklyInsights(
        status: InsightStatus.sufficientData,
        weekStart: '2026-10-19',
        metrics: {
          'stress': WeeklyMetricComparison(
            weekAverage: 2.0,
            baselineAverage: 3.1,
            diff: -1.1,
            code: 'LOWER_THAN_USUAL',
          ),
          'mood': WeeklyMetricComparison(
            weekAverage: 4.0,
            baselineAverage: 3.2,
            diff: 0.8,
            code: 'HIGHER_THAN_USUAL',
          ),
        },
        sampleSizes: WeeklySampleSizes(
          weekDistinctDays: 5,
          baselineDistinctDays: 14,
        ),
      );

      fakeRepo.exam = const ExamContextInsights(
        status: InsightStatus.sufficientData,
        qualifyingEventsCount: 2,
        stress: ExamMetricComparison(
          preEventAverage: 4.5,
          baselineAverage: 2.8,
          diff: 1.7,
          code: 'STRESS_HIGHER_BEFORE_EVENTS',
        ),
        sampleSizes: ExamSampleSizes(
          preEventDistinctDays: 6,
          baselineDistinctDays: 12,
          qualifyingEvents: 2,
        ),
      );

      await tester.pumpWidget(_buildTestApp(const InsightsScreen(), fakeRepo));
      await tester.pumpAndSettle();

      // Check header and disclaimer
      expect(find.text('Personal Observations'), findsOneWidget);
      expect(find.text('This is an observation, not a cause.'), findsOneWidget);

      // Check weekly observations
      expect(
        find.text(
            'This week, your stress check-ins were a bit lower than your usual.'),
        findsOneWidget,
      );
      expect(
        find.text(
            'This week, your mood check-ins were a bit higher than your usual.'),
        findsOneWidget,
      );

      // Check exam observation
      expect(
        find.text(
            'Before your exams, your stress check-ins were a bit higher than your usual.'),
        findsOneWidget,
      );

      // Verify ZERO scores, percentages, or percent signs are rendered
      expect(find.textContaining('%'), findsNothing);
      expect(find.textContaining('score'), findsNothing);
      expect(find.textContaining('average'), findsNothing);
    });

    testWidgets('InsightsScreen renders not enough data guidance properly',
        (tester) async {
      fakeRepo.weekly = const WeeklyInsights(
        status: InsightStatus.notEnoughData,
        weekStart: '2026-10-19',
        daysNeeded: WeeklyDaysNeeded(week: 2, baseline: 3),
      );
      fakeRepo.exam = const ExamContextInsights(
        status: InsightStatus.notEnoughData,
      );

      await tester.pumpWidget(_buildTestApp(const InsightsScreen(), fakeRepo));
      await tester.pumpAndSettle();

      expect(
        find.text(
            'We need check-ins on at least 2 more days this week and 3 more baseline days to share weekly observations.'),
        findsOneWidget,
      );
      expect(
        find.text(
            'We need at least 2 events with 3 check-in days each in their preparation window to share exam observations.'),
        findsOneWidget,
      );
    });

    testWidgets(
        'HomeScreen study planner card has no coming soon and no sensitive info',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(const HomeScreen(), fakeRepo));
      await tester.pumpAndSettle();

      // "Plan my study week" card is visible
      expect(find.text('Plan my study week 📚'), findsOneWidget);
      expect(find.text('Gentle suggestions to pace your study and rest.'),
          findsOneWidget);

      final plannerCardFinder = find.ancestor(
        of: find.text('Plan my study week 📚'),
        matching: find.byType(AppCard),
      );
      expect(plannerCardFinder, findsOneWidget);

      // Ensure NO sensitive fields or coming soon appear on the Study Planner card
      expect(
        find.descendant(
          of: plannerCardFinder,
          matching: find.textContaining('period'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: plannerCardFinder,
          matching: find.textContaining('cycle'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: plannerCardFinder,
          matching: find.textContaining('exam:'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: plannerCardFinder,
          matching: find.text('Coming soon'),
        ),
        findsNothing,
      );
    });

    testWidgets(
        'ExamsScreen study planner banner links to planner without coming soon',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(const ExamsScreen(), fakeRepo));
      await tester.pumpAndSettle();

      expect(
        find.text(
            'Adding exams and deadlines lets BloomWell suggest gentler study plans later. This is optional.'),
        findsOneWidget,
      );
      expect(find.text('Study planner coming soon'), findsNothing);
    });

    testWidgets('MoodScreen links to Personal Observations', (tester) async {
      await tester.pumpWidget(_buildTestApp(const MoodScreen(), fakeRepo));
      await tester.pumpAndSettle();

      expect(find.text('Personal Observations'), findsOneWidget);
    });
  });
}
