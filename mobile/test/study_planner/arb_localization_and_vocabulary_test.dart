import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloomwell/l10n/app_localizations_en.dart';

void main() {
  group('ARB Localization & Forbidden Vocabulary Verification', () {
    late AppLocalizationsEn l10n;

    setUp(() {
      l10n = AppLocalizationsEn();
    });

    test('All study planner and insights keys exist and format correctly', () {
      expect(l10n.studyPlannerTitle, equals('Study Planner'));
      expect(l10n.studyPlannerNoCycleNote,
          contains('works fully without period data'));
      expect(
          l10n.studyPlannerDefaultBanner(5),
          equals(
              "This week's plan is a simple starting point. Personalized suggestions appear after about 14 days of check-ins (you have 5)."));
      expect(l10n.studyPlannerPersonalizedBanner(16),
          equals('Based on 16 days of your check-ins.'));

      // Reason codes mapping
      expect(
          l10n.studyPlannerReasonNotEnoughHistory,
          equals(
              'We need a little more of your own check-in history to personalize this.'));
      expect(l10n.studyPlannerReasonDefaultPlan,
          equals('This is a simple starting plan.'));
      expect(l10n.studyPlannerReasonWeekdayEnergyHigher,
          equals("You've often logged higher energy on this day of the week."));
      expect(l10n.studyPlannerReasonWeekdayEnergyLower,
          equals("You've often logged lower energy on this day of the week."));
      expect(
          l10n.studyPlannerReasonCyclePeriodLowEnergy,
          equals(
              "You allowed us to use your period logs, and you've logged lower energy on period days."));
      expect(l10n.studyPlannerReasonEventPrep('Math'),
          equals('A little steady prep before your Math.'));
      expect(l10n.studyPlannerReasonEventDay('Physics'),
          equals("It's your Physics day."));
      expect(
          l10n.studyPlannerReasonKeepOptionPreserved('Biology'),
          equals(
              "We kept a regular option here so you aren't over-resting before your Biology."));
      expect(l10n.studyPlannerReasonNeutralFallback,
          equals('A suggestion based on your plan.'));

      // Insights codes
      expect(l10n.insightsDisclaimer,
          equals('This is an observation, not a cause.'));
      expect(
          l10n.insightsStressHigher,
          equals(
              "This week, your stress check-ins were a bit higher than your usual."));
      expect(
          l10n.insightsExamStressHigher,
          equals(
              'Before your exams, your stress check-ins were a bit higher than your usual.'));
      expect(l10n.insightsWeeklySampleSizes(5, 14),
          contains('5 check-in days this week and 14 baseline days'));
      expect(
          l10n.insightsExamSampleSizes(2, 6, 12),
          contains(
              '2 qualifying events with 6 pre-event days and 12 baseline days'));
    });

    test('Zero forbidden vocabulary across all app_en.arb strings', () {
      final arbFile = File('lib/l10n/app_en.arb');
      expect(arbFile.existsSync(), isTrue);

      final content = arbFile.readAsStringSync();
      final Map<String, dynamic> jsonMap =
          jsonDecode(content) as Map<String, dynamic>;

      final forbiddenTerms = [
        'ovulation',
        'fertile',
        'pregnancy',
        'abnormal',
        'irregular',
        'because of your period',
        'caused by',
        'behind',
        'missed',
        'streak',
      ];

      for (final entry in jsonMap.entries) {
        if (entry.key.startsWith('@')) continue;
        final value = entry.value.toString().toLowerCase();

        for (final term in forbiddenTerms) {
          expect(
            value.contains(term),
            isFalse,
            reason:
                'Forbidden term "$term" found in ARB key "${entry.key}": "$value"',
          );
        }
      }
    });
  });
}
