import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CycleCare Vocabulary & Non-Diagnostic Guardrails', () {
    test('app_en.arb strictly forbids diagnostic, pregnancy, or judgment terms',
        () {
      final arbFile = File('lib/l10n/app_en.arb');
      expect(arbFile.existsSync(), isTrue, reason: 'app_en.arb must exist');

      final content = arbFile.readAsStringSync().toLowerCase();

      final forbiddenTerms = [
        'ovulation',
        'fertile',
        'fertility',
        'pregnancy',
        'pregnant',
        'abnormal',
        'irregular',
      ];

      for (final term in forbiddenTerms) {
        expect(
          content.contains(term),
          isFalse,
          reason:
              'Forbidden clinical/judgment term "$term" found in lib/l10n/app_en.arb!',
        );
      }
    });

    test('CycleCare keys exist and are well-formed in app_en.arb', () {
      final arbFile = File('lib/l10n/app_en.arb');
      final map =
          jsonDecode(arbFile.readAsStringSync()) as Map<String, dynamic>;

      final requiredKeys = [
        'cycleOptInTitle',
        'cycleOptInSubtitle',
        'cycleOptInNoticeHeader',
        'cycleOptInNoticeStorage',
        'cycleOptInNoticeEstimates',
        'cycleOptInNoticeNonMedical',
        'cycleOptInNoticeControl',
        'cycleOptInEnableButton',
        'cycleOptInNotNowButton',
        'cycleCalendarHeader',
        'cycleCalendarPrevMonth',
        'cycleCalendarNextMonth',
        'cycleLegendLogged',
        'cycleLegendEstimate',
        'cycleLegendSymptoms',
        'cycleDaySheetTitle',
        'cycleDayNoLogs',
        'cycleDayPeriodLogged',
        'cycleDayEstimateWindow',
        'cycleActionLogPeriod',
        'cycleActionLogSymptom',
        'cycleActionEditPeriod',
        'cycleActionDeletePeriod',
        'cycleDeletePeriodConfirm',
        'cycleQuickStartedToday',
        'cycleQuickEndedToday',
        'cycleQuickPeriodEnded',
        'cycleSwitchToListView',
        'cycleSwitchToGridView',
        'cycleLogPeriodTitle',
        'cycleEditPeriodTitle',
        'cycleStartDateLabel',
        'cycleEndDateLabel',
        'cycleSaveButton',
        'cycleSavingButton',
        'cycleCancelButton',
        'cyclePeriodSaved',
        'cyclePeriodDeleted',
        'cycleErrorFutureDate',
        'cycleErrorInvalidRange',
        'cycleErrorOverlap',
        'cycleLogSymptomTitle',
        'cycleEditSymptomTitle',
        'cycleSymptomDateLabel',
        'cycleSymptomTypeLabel',
        'cycleSymptomCramps',
        'cycleSymptomBloating',
        'cycleSymptomFatigue',
        'cycleSymptomHeadache',
        'cycleSymptomBackPain',
        'cycleSymptomBreastTenderness',
        'cycleSymptomNausea',
        'cycleSymptomMoodChanges',
        'cycleSymptomAcne',
        'cycleSymptomCravings',
        'cycleSymptomSleepTrouble',
        'cycleSymptomOther',
        'cycleCustomLabelLabel',
        'cycleCustomLabelPlaceholder',
        'cycleSeverityLabel',
        'cycleSeverity1',
        'cycleSeverity2',
        'cycleSeverity3',
        'cycleSeverity4',
        'cycleSeverity5',
        'cycleSeverityDisclaimer',
        'cycleNotesLabel',
        'cycleNotesPlaceholder',
        'cycleNotesCounter',
        'cycleSymptomSaved',
        'cycleSymptomDeleted',
        'cycleDeleteSymptomConfirm',
        'cycleEstimateTitle',
        'cycleEstimateBadge',
        'cycleEstimateDisclaimer',
        'cycleEstimateNotEnoughData',
        'cycleEstimateTooVariable',
        'cycleEstimateRange',
        'cycleEstimateDetails',
        'cycleHistoryTitle',
        'cycleHistoryEmpty',
        'cycleHistoryCycleLength',
        'cycleHistoryOngoing',
        'cycleHistoryDelete',
        'cycleHistoryEdit',
        'cycleSettingsTitle',
        'cycleTurnOffTracking',
        'cycleTurnOffDialogTitle',
        'cycleTurnOffDialogBody',
        'cycleKeepDataOption',
        'cycleDeleteDataOption',
        'cycleDeleteConfirmTitle',
        'cycleDeleteConfirmBody',
        'cycleConfirmDeleteButton',
        'cycleTrackingDisabledFeedback',
        'cycleTrackingDeletedFeedback',
        'homeCycleCardTitle',
        'homeCycleCardSubtitle',
        'homeCycleCardAction',
        'cycleDisabledNotice',
      ];

      for (final key in requiredKeys) {
        expect(
          map.containsKey(key),
          isTrue,
          reason: 'Missing localization key: $key',
        );
        expect(
          map[key],
          isA<String>(),
          reason: 'Key $key must map to a String',
        );
        expect(
          (map[key] as String).isNotEmpty,
          isTrue,
          reason: 'Key $key must not be empty',
        );
      }
    });
  });
}
