import 'package:bloomwell/app/theme/app_theme.dart';
import 'package:bloomwell/features/app_lock/application/app_lock_notifier.dart';
import 'package:bloomwell/features/app_lock/domain/app_lock_config.dart';
import 'package:bloomwell/features/exams/application/academic_events_notifier.dart';
import 'package:bloomwell/features/exams/data/academic_events_repository.dart';
import 'package:bloomwell/features/exams/domain/entities/academic_event.dart';
import 'package:bloomwell/features/exams/domain/entities/academic_event_type.dart';
import 'package:bloomwell/features/exams/presentation/exams_screen.dart';
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

class FakeAcademicEventsRepo implements IAcademicEventsRepository {
  List<AcademicEvent> events = [];
  int createCalls = 0;
  String? lastClientId;

  @override
  Future<({List<AcademicEvent> items, String? nextCursor, bool hasMore})>
      getEvents({String? cursor, int limit = 20, bool? upcomingOnly}) async {
    return (items: List.of(events), nextCursor: null, hasMore: false);
  }

  @override
  Future<AcademicEvent> createEvent({
    required String clientId,
    required String title,
    required DateTime eventDate,
    required AcademicEventType eventType,
  }) async {
    createCalls++;
    lastClientId = clientId;
    final created = AcademicEvent(
      id: 'event-${events.length + 1}',
      clientId: clientId,
      title: title,
      eventDate: eventDate,
      eventType: eventType,
      createdAt: DateTime.now(),
    );
    events.add(created);
    return created;
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
      title: title ?? existing.title,
      eventDate: eventDate ?? existing.eventDate,
      eventType: eventType ?? existing.eventType,
    );
    events[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteEvent(String id) async {
    events.removeWhere((e) => e.id == id);
  }
}

Widget buildExamsApp({
  required FakeAcademicEventsRepo repo,
  bool isLocked = false,
}) {
  return ProviderScope(
    overrides: [
      academicEventsRepositoryProvider.overrideWithValue(repo),
      appLockNotifierProvider.overrideWith(() => MockLockNotifier(isLocked)),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const ExamsScreen(),
    ),
  );
}

void main() {
  group('ExamsScreen Tests', () {
    late FakeAcademicEventsRepo repo;
    final now = DateTime.now();

    setUp(() {
      repo = FakeAcademicEventsRepo();
      repo.events = [
        AcademicEvent(
          id: 'ev-1',
          clientId: 'cid-1',
          title: 'Cell Biology Midterm',
          eventDate: DateTime(now.year, now.month, now.day + 5),
          eventType: AcademicEventType.exam,
          createdAt: DateTime.now(),
        ),
        AcademicEvent(
          id: 'ev-2',
          clientId: 'cid-2',
          title: 'Organic Chemistry Lab Report',
          eventDate: DateTime(now.year, now.month, now.day - 3),
          eventType: AcademicEventType.assignment,
          createdAt: DateTime.now(),
        ),
      ];
    });

    testWidgets('renders screen header, planner notice, and upcoming events',
        (tester) async {
      await tester.pumpWidget(buildExamsApp(repo: repo));
      await tester.pumpAndSettle();

      expect(find.text('Exams & Deadlines'), findsOneWidget);
      expect(
        find.text(
          'Keep track of academic events so study suggestions can feel gentler.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Adding exams and deadlines lets BloomWell suggest gentler study plans later. This is optional.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsWidgets);
      expect(find.text('Study planner coming soon'), findsNothing);

      // Verify Upcoming event is displayed with neutral pacing
      expect(find.text('Cell Biology Midterm'), findsOneWidget);
      expect(find.text('Exam'), findsOneWidget);
      expect(find.text('in 5 days'), findsOneWidget);

      // Verify STRICT guardrails: strictly no exclamation marks or urgency panic
      expect(find.textContaining('!'), findsNothing);
      expect(find.textContaining(RegExp(r'streak', caseSensitive: false)),
          findsNothing);
      expect(find.textContaining('%'), findsNothing);

      // Verify past event is not in upcoming tab
      expect(find.text('Organic Chemistry Lab Report'), findsNothing);
    });

    testWidgets('switching to Past tab shows past events and hides upcoming',
        (tester) async {
      await tester.pumpWidget(buildExamsApp(repo: repo));
      await tester.pumpAndSettle();

      expect(find.text('Cell Biology Midterm'), findsOneWidget);
      expect(find.text('Organic Chemistry Lab Report'), findsNothing);

      // Tap 'Past' tab
      await tester.tap(find.text('Past'));
      await tester.pumpAndSettle();

      expect(find.text('Cell Biology Midterm'), findsNothing);
      expect(find.text('Organic Chemistry Lab Report'), findsOneWidget);
      expect(find.text('Assignment'), findsOneWidget);
      expect(find.text('3 days ago'), findsOneWidget);
    });

    testWidgets('deleting an event removes it after confirmation',
        (tester) async {
      await tester.pumpWidget(buildExamsApp(repo: repo));
      await tester.pumpAndSettle();

      expect(find.text('Cell Biology Midterm'), findsOneWidget);

      // Open menu
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      // Tap delete in menu
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Verify confirmation dialog
      expect(
        find.text('Are you sure you want to delete this event?'),
        findsOneWidget,
      );

      // Confirm delete
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(repo.events.length, equals(1));
      expect(find.text('Cell Biology Midterm'), findsNothing);
    });

    testWidgets('empty state renders peaceful message', (tester) async {
      repo.events = [];

      await tester.pumpWidget(buildExamsApp(repo: repo));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'No upcoming exams or deadlines entered. Enjoy your free rhythm.',
        ),
        findsOneWidget,
      );

      // Switch to past tab
      await tester.tap(find.text('Past'));
      await tester.pumpAndSettle();

      expect(find.text('No past exams recorded.'), findsOneWidget);
    });

    testWidgets('when app is locked, screen is blank for privacy',
        (tester) async {
      await tester.pumpWidget(buildExamsApp(
        repo: repo,
        isLocked: true,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Exams & Deadlines'), findsNothing);
      expect(find.text('Cell Biology Midterm'), findsNothing);
    });
  });
}
