import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Self-Care, Comfort, Routines & Exams Vocabulary Guardrails', () {
    test(
        'app_en.arb strictly forbids cure, treat, heal, diagnose, streak, behind, missed',
        () {
      final arbFile = File('lib/l10n/app_en.arb');
      expect(arbFile.existsSync(), isTrue, reason: 'app_en.arb must exist');

      final content = arbFile.readAsStringSync().toLowerCase();

      final forbiddenTerms = [
        'cure',
        'treat',
        'heal',
        'diagnose',
        'streak',
        'behind',
        'missed',
      ];

      for (final term in forbiddenTerms) {
        final pattern = RegExp(r'\b' + term + r'\b', caseSensitive: false);
        expect(
          pattern.hasMatch(content),
          isFalse,
          reason:
              'Forbidden clinical/judgment/productivity term "$term" found in lib/l10n/app_en.arb!',
        );
      }
    });

    test('Required localization keys exist and are non-empty in app_en.arb',
        () {
      final arbFile = File('lib/l10n/app_en.arb');
      final map =
          jsonDecode(arbFile.readAsStringSync()) as Map<String, dynamic>;

      final requiredKeys = [
        'selfCareStudioTitle',
        'selfCareStudioSubtitle',
        'selfCareCategoryAll',
        'selfCareCategoryBreathing',
        'selfCareCategoryGrounding',
        'selfCareCategoryRelaxation',
        'selfCareCategoryMovement',
        'selfCareCategoryJournaling',
        'selfCareCategoryStudyBreak',
        'selfCareCategoryComfort',
        'selfCareCategoryConfidence',
        'selfCareDurationAny',
        'selfCareDuration2',
        'selfCareDuration5',
        'selfCareDuration10',
        'selfCareEmptyTitle',
        'selfCareEmptySubtitle',
        'selfCareErrorTitle',
        'selfCareRetry',
        'selfCareHistoryButton',
        'selfCareRoutinesButton',
        'selfCareAddFavoriteA11y',
        'selfCareRemoveFavoriteA11y',
        'selfCareDurationMinutes',
        'activityDetailTitle',
        'activityStartButton',
        'activitySourceLabel',
        'activityStepsTitle',
        'activityComfortDoctorNote',
        'activityStepCounter',
        'activityStepNext',
        'activityStepBack',
        'activityStepDone',
        'activityRatingTitle',
        'activityRatingSubtitle',
        'activityRatingSkip',
        'activitySavedConfirmed',
        'activityHistoryTitle',
        'activityHistorySubtitle',
        'activityHistoryEmpty',
        'comfortModeTitle',
        'comfortModeSubtitle',
        'comfortNeedQuestion',
        'comfortNeedQuickBreak',
        'comfortNeedCalmDown',
        'comfortNeedBodyComfort',
        'comfortNeedFocus',
        'comfortReasonFavorite',
        'comfortReasonNewForYou',
        'comfortReasonQuick',
        'comfortReasonOther',
        'comfortShowSomethingElse',
        'comfortPlanTitle',
        'comfortPlanSubtitle',
        'comfortPlanEmpty',
        'comfortAddToPlan',
        'comfortRemoveFromPlan',
        'comfortFindSupport',
        'comfortNonMedicalNotice',
        'routinesTitle',
        'routinesSubtitle',
        'routinesEmptyTitle',
        'routinesEmptySubtitle',
        'routinesNewButton',
        'routinesCreateTitle',
        'routinesEditTitle',
        'routinesTitleField',
        'routinesStartDateField',
        'routinesEndDateField',
        'routinesSaveButton',
        'routinesDeleteButton',
        'routinesDeleteConfirm',
        'routinesAddItem',
        'routinesLimitExceeded',
        'routinesItemLimitExceeded',
        'routinesProgressText',
        'examsTitle',
        'examsSubtitle',
        'examsPlannerNotice',
        'examsPlannerComingSoon',
        'examsTabUpcoming',
        'examsTabPast',
        'examsNewButton',
        'examsCreateTitle',
        'examsEditTitle',
        'examsTitleLabel',
        'examsDateLabel',
        'examsTypeLabel',
        'examsTypeExam',
        'examsTypeAssignment',
        'examsTypePresentation',
        'examsTypeOther',
        'examsSaveButton',
        'examsDeleteButton',
        'examsDeleteConfirm',
        'examsEmptyUpcoming',
        'examsEmptyPast',
        'examsInDays',
        'examsInOneDay',
        'examsToday',
        'examsDaysAgo',
      ];

      for (final key in requiredKeys) {
        expect(
          map.containsKey(key),
          isTrue,
          reason: 'Missing localization key: $key',
        );
        expect(
          (map[key] as String).trim().isNotEmpty,
          isTrue,
          reason: 'Key $key must not be empty',
        );
      }

      expect(
        map['activityComfortDoctorNote'],
        'If symptoms feel severe, unusual or last a long time, talking to a doctor or nurse can help.',
      );
    });
  });
}
