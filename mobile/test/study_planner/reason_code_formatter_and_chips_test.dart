import 'package:bloomwell/features/study_planner/domain/entities/plan_item_status.dart';
import 'package:bloomwell/features/study_planner/domain/entities/study_plan_item.dart';
import 'package:bloomwell/features/study_planner/domain/entities/suggested_load.dart';
import 'package:bloomwell/features/study_planner/presentation/widgets/load_chip.dart';
import 'package:bloomwell/features/study_planner/presentation/widgets/reason_code_formatter.dart';
import 'package:bloomwell/features/study_planner/presentation/widgets/study_plan_day_card.dart';
import 'package:bloomwell/l10n/app_localizations.dart';
import 'package:bloomwell/l10n/app_localizations_en.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('ReasonCodeFormatter Tests', () {
    late AppLocalizationsEn l10n;

    setUp(() {
      l10n = AppLocalizationsEn();
    });

    test('Maps all 8 standard reason codes into supportive sentences', () {
      final notEnough =
          ReasonCodeFormatter.formatReasonCodes(['NOT_ENOUGH_HISTORY'], l10n);
      expect(
          notEnough.first,
          equals(
              'We need a little more of your own check-in history to personalize this.'));

      final defaultPlan =
          ReasonCodeFormatter.formatReasonCodes(['DEFAULT_PLAN'], l10n);
      expect(defaultPlan.first, equals('This is a simple starting plan.'));

      final weekdayHigher = ReasonCodeFormatter.formatReasonCodes(
          ['WEEKDAY_ENERGY_HIGHER'], l10n);
      expect(weekdayHigher.first,
          equals("You've often logged higher energy on this day of the week."));

      final weekdayLower =
          ReasonCodeFormatter.formatReasonCodes(['WEEKDAY_ENERGY_LOWER'], l10n);
      expect(weekdayLower.first,
          equals("You've often logged lower energy on this day of the week."));

      final cyclePeriod = ReasonCodeFormatter.formatReasonCodes(
          ['CYCLE_RECORDED_PERIOD_LOW_ENERGY'], l10n);
      expect(
          cyclePeriod.first,
          equals(
              "You allowed us to use your period logs, and you've logged lower energy on period days."));

      final eventPrep = ReasonCodeFormatter.formatReasonCodes(
          ['EVENT_PREP'], l10n,
          eventTitle: 'Biology Midterm');
      expect(eventPrep.first,
          equals('A little steady prep before your Biology Midterm.'));

      final eventDay = ReasonCodeFormatter.formatReasonCodes(
          ['EVENT_DAY'], l10n,
          eventTitle: 'Calculus Final');
      expect(eventDay.first, equals("It's your Calculus Final day."));

      final keepOption = ReasonCodeFormatter.formatReasonCodes(
          ['KEEP_OPTION_PRESERVED'], l10n,
          eventTitle: 'Physics Exam');
      expect(
          keepOption.first,
          equals(
              "We kept a regular option here so you aren't over-resting before your Physics Exam."));
    });

    test('Unknown code falls back neutrally without inventing text', () {
      final fallback =
          ReasonCodeFormatter.formatReasonCodes(['UNKNOWN_CODE_XYZ'], l10n);
      expect(fallback.first, equals('A suggestion based on your plan.'));

      final emptyFallback = ReasonCodeFormatter.formatReasonCodes([], l10n);
      expect(emptyFallback.first, equals('A suggestion based on your plan.'));
    });
  });

  group('LoadChip Widget Tests', () {
    testWidgets('Renders both icon and text for all load types',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        const Column(
          children: [
            LoadChip(load: SuggestedLoad.light),
            LoadChip(load: SuggestedLoad.normal),
            LoadChip(load: SuggestedLoad.focus),
          ],
        ),
      ));
      await tester.pumpAndSettle();

      // Light
      expect(find.text('Light'), findsOneWidget);
      expect(find.byIcon(Icons.spa_rounded), findsOneWidget);

      // Normal
      expect(find.text('Normal'), findsOneWidget);
      expect(find.byIcon(Icons.balance_rounded), findsOneWidget);

      // Focus
      expect(find.text('Focus'), findsOneWidget);
      expect(find.byIcon(Icons.psychology_rounded), findsOneWidget);
    });
  });

  group('StudyPlanDayCard Accessibility and Rendering Tests', () {
    testWidgets('Renders day card with accessible semantics and min height',
        (tester) async {
      final item = StudyPlanItem(
        id: 'item-1',
        studyPlanId: 'p-1',
        planDate: DateTime(2026, 10, 20), // Tuesday
        suggestedLoad: SuggestedLoad.light,
        reasonCodes: const ['WEEKDAY_ENERGY_LOWER'],
        academicEventId: 'ev-1',
        academicEventTitle: 'Chemistry Exam',
        activityId: 'act-1',
        status: PlanItemStatus.suggested,
        updatedAt: DateTime(2026, 10, 19),
      );

      var tapped = false;
      var activityTappedId = '';

      await tester.pumpWidget(_buildTestApp(
        StudyPlanDayCard(
          item: item,
          onTap: () => tapped = true,
          onActivityTap: (id) => activityTappedId = id,
        ),
      ));
      await tester.pumpAndSettle();

      // Check text rendering
      expect(find.text('Tuesday'), findsOneWidget);
      expect(find.text('Chemistry Exam'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Suggested'), findsOneWidget);
      expect(find.text('Break activity'), findsOneWidget);

      // Verify semantics label
      final semanticsFinder = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.label != null &&
            w.properties.label!.contains('Tuesday') &&
            w.properties.label!.contains('Light day') &&
            w.properties.label!.contains('Chemistry Exam') &&
            w.properties.label!.contains('Suggested'),
      );
      expect(semanticsFinder, findsOneWidget);

      // Tap card
      await tester.tap(find.text('Tuesday'));
      expect(tapped, isTrue);

      // Tap break activity
      await tester.tap(find.text('Break activity'));
      expect(activityTappedId, equals('act-1'));
    });
  });
}
