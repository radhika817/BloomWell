import 'package:bloomwell/features/comfort/domain/entities/comfort_need.dart';
import 'package:bloomwell/features/comfort/domain/entities/comfort_plan_item.dart';
import 'package:bloomwell/features/exams/domain/entities/academic_event.dart';
import 'package:bloomwell/features/exams/domain/entities/academic_event_type.dart';
import 'package:bloomwell/features/routines/domain/entities/routine.dart';
import 'package:bloomwell/features/routines/domain/entities/routine_item.dart';
import 'package:bloomwell/features/self_care/domain/entities/activity_category.dart';
import 'package:bloomwell/features/self_care/domain/entities/activity_completion_log.dart';
import 'package:bloomwell/features/self_care/domain/entities/activity_entry.dart';
import 'package:bloomwell/features/self_care/domain/entities/activity_suggestion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Self-Care & Comfort Domain Models Tests', () {
    test('ActivityCategory parsing and serialization', () {
      expect(
          ActivityCategory.fromString('breathing'), ActivityCategory.breathing);
      expect(ActivityCategory.fromString('study_break'),
          ActivityCategory.studyBreak);
      expect(ActivityCategory.fromString('comfort'), ActivityCategory.comfort);
      expect(ActivityCategory.fromString('unknown_val'),
          ActivityCategory.relaxation);
      expect(ActivityCategory.fromString(null), ActivityCategory.relaxation);
      expect(ActivityCategory.movement.apiValue, 'movement');
    });

    test('ActivityEntry serialization, comfort flag, and breathing detection',
        () {
      const activity = ActivityEntry(
        id: 'act-1',
        title: 'Box Breathing 4-4-4',
        category: ActivityCategory.breathing,
        durationMinutes: 4,
        summary: 'Gentle box breathing rhythm',
        steps: ['Inhale 4s', 'Hold 4s', 'Exhale 4s', 'Hold 4s'],
        source: 'Clinical Wellness Review, 2024',
        slug: 'box-breathing',
        isFavorite: true,
      );

      expect(activity.isComfortCategory, false);
      expect(activity.isBreathingActivity, true);

      final json = activity.toJson();
      expect(json['id'], 'act-1');
      expect(json['category'], 'breathing');
      expect(json['duration_minutes'], 4);
      expect(json['is_favorite'], true);

      final fromJson = ActivityEntry.fromJson(json);
      expect(fromJson.id, 'act-1');
      expect(fromJson.steps.length, 4);
      expect(fromJson.isFavorite, true);

      final comfortActivity = activity.copyWith(
        id: 'act-2',
        category: ActivityCategory.comfort,
        slug: 'warm-compress',
      );
      expect(comfortActivity.isComfortCategory, true);
      expect(comfortActivity.isBreathingActivity, false);
    });

    test('ActivitySuggestion and reason code mapping', () {
      final json = {
        'activity': {
          'id': 'act-fav',
          'title': 'Resting Grounding',
          'category': 'grounding',
          'duration_minutes': 5,
          'summary': 'Grounding feet on floor',
          'steps': ['Sit quietly', 'Feel your feet'],
          'source': 'Self-Care Library',
        },
        'reason_code': 'FAVORITE',
      };

      final suggestion = ActivitySuggestion.fromJson(json);
      expect(suggestion.activity.id, 'act-fav');
      expect(suggestion.reason, ActivitySuggestionReason.favorite);
      expect(suggestion.reasonCode, 'FAVORITE');

      final quickJson = {
        'activity': json['activity'],
        'reason_code': 'QUICK',
      };
      expect(ActivitySuggestion.fromJson(quickJson).reason,
          ActivitySuggestionReason.quick);
    });

    test('ActivityCompletionLog serialization and rating', () {
      final log = ActivityCompletionLog(
        id: 'log-1',
        clientId: 'client-uuid-1',
        activityId: 'act-1',
        activityTitle: 'Gentle Walk',
        activityCategory: ActivityCategory.movement,
        completedAt: DateTime.utc(2026, 10, 20, 14, 30),
        helpfulnessRating: 5,
      );

      final json = log.toJson();
      expect(json['client_id'], 'client-uuid-1');
      expect(json['helpfulness_rating'], 5);

      final fromJson = ActivityCompletionLog.fromJson(json);
      expect(fromJson.clientId, 'client-uuid-1');
      expect(fromJson.helpfulnessRating, 5);
      expect(fromJson.activityCategory, ActivityCategory.movement);
    });

    test('ComfortNeed parsing and values', () {
      expect(ComfortNeed.fromString('quick_break'), ComfortNeed.quickBreak);
      expect(ComfortNeed.fromString('calm'), ComfortNeed.calmDown);
      expect(ComfortNeed.fromString('body_comfort'), ComfortNeed.bodyComfort);
      expect(ComfortNeed.fromString('focus'), ComfortNeed.focus);
      expect(ComfortNeed.fromString('invalid'), ComfortNeed.calmDown);
    });

    test('ComfortPlanItem serialization', () {
      final item = ComfortPlanItem(
        id: 'cp-1',
        activityId: 'act-10',
        position: 1,
        createdAt: DateTime.utc(2026, 10, 19),
      );

      final json = item.toJson();
      expect(json['id'], 'cp-1');
      expect(json['position'], 1);

      final fromJson = ComfortPlanItem.fromJson(json);
      expect(fromJson.activityId, 'act-10');
      expect(fromJson.position, 1);
    });

    test('Routine and RoutineItem models, progressText: 3 of 5 done', () {
      final items = [
        const RoutineItem(
          id: 'i-1',
          routineId: 'r-1',
          activityId: 'act-1',
          activityTitle: 'Morning Stretch',
          completedAt: null,
        ),
        RoutineItem(
          id: 'i-2',
          routineId: 'r-1',
          activityId: 'act-2',
          activityTitle: 'Deep Breath',
          completedAt: DateTime.utc(2026, 10, 22),
        ),
        RoutineItem(
          id: 'i-3',
          routineId: 'r-1',
          activityId: 'act-3',
          activityTitle: 'Night Wind Down',
          completedAt: DateTime.utc(2026, 10, 22),
        ),
      ];

      final routine = Routine(
        id: 'r-1',
        title: 'Daily Evening Peace',
        items: items,
        createdAt: DateTime.utc(2026, 10, 20),
      );

      expect(routine.completedItemsCount, 2);
      expect(routine.totalItemsCount, 3);
      expect(routine.progressText, '2 of 3 done');

      final json = routine.toJson();
      expect(json['title'], 'Daily Evening Peace');
      expect((json['items'] as List).length, 3);

      final fromJson = Routine.fromJson(json);
      expect(fromJson.items.first.isDone, false);
      expect(fromJson.items[1].isDone, true);
    });

    test('AcademicEventType and AcademicEvent date comparison', () {
      expect(AcademicEventType.fromString('exam'), AcademicEventType.exam);
      expect(AcademicEventType.fromString('assignment'),
          AcademicEventType.assignment);
      expect(AcademicEventType.fromString('presentation'),
          AcademicEventType.presentation);
      expect(AcademicEventType.fromString('other'), AcademicEventType.other);

      final pastDate = DateTime.now().subtract(const Duration(days: 3));
      final pastEvent = AcademicEvent(
        id: 'ev-1',
        clientId: 'cid-1',
        title: 'Midterm Physics',
        eventDate: pastDate,
        eventType: AcademicEventType.exam,
        createdAt: DateTime.now(),
      );
      expect(pastEvent.isPast, true);

      final futureDate = DateTime.now().add(const Duration(days: 4));
      final futureEvent = pastEvent.copyWith(
        id: 'ev-2',
        title: 'Chemistry Lab Report',
        eventDate: futureDate,
        eventType: AcademicEventType.assignment,
      );
      expect(futureEvent.isPast, false);
      expect(futureEvent.daysDifferenceFromToday, greaterThanOrEqualTo(3));

      final json = futureEvent.toJson();
      expect(json['title'], 'Chemistry Lab Report');
      expect(json['event_type'], 'assignment');

      final fromJson = AcademicEvent.fromJson(json);
      expect(fromJson.title, 'Chemistry Lab Report');
      expect(fromJson.eventType, AcademicEventType.assignment);
    });
  });
}
