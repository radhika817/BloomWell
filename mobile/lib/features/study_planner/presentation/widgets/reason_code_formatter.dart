import '../../../../l10n/app_localizations.dart';

/// Pure formatter converting server reason codes into localized, kind sentences.
/// Observations only: never claims causation, predictions, or judgments.
class ReasonCodeFormatter {
  ReasonCodeFormatter._();

  /// Maps a list of server reason codes into localized sentences.
  /// Any unknown code gracefully falls back to a neutral sentence without inventing text.
  static List<String> formatReasonCodes(
    List<String> codes,
    AppLocalizations l10n, {
    String? eventTitle,
  }) {
    if (codes.isEmpty) {
      return [l10n.studyPlannerReasonNeutralFallback];
    }

    final safeEvent = (eventTitle != null && eventTitle.trim().isNotEmpty)
        ? eventTitle.trim()
        : 'event';

    final results = <String>[];
    for (final code in codes) {
      switch (code.trim().toUpperCase()) {
        case 'NOT_ENOUGH_HISTORY':
          results.add(l10n.studyPlannerReasonNotEnoughHistory);
          break;
        case 'DEFAULT_PLAN':
          results.add(l10n.studyPlannerReasonDefaultPlan);
          break;
        case 'WEEKDAY_ENERGY_HIGHER':
          results.add(l10n.studyPlannerReasonWeekdayEnergyHigher);
          break;
        case 'WEEKDAY_ENERGY_LOWER':
          results.add(l10n.studyPlannerReasonWeekdayEnergyLower);
          break;
        case 'CYCLE_RECORDED_PERIOD_LOW_ENERGY':
          results.add(l10n.studyPlannerReasonCyclePeriodLowEnergy);
          break;
        case 'EVENT_PREP':
          results.add(l10n.studyPlannerReasonEventPrep(safeEvent));
          break;
        case 'EVENT_DAY':
          results.add(l10n.studyPlannerReasonEventDay(safeEvent));
          break;
        case 'KEEP_OPTION_PRESERVED':
          results.add(l10n.studyPlannerReasonKeepOptionPreserved(safeEvent));
          break;
        default:
          results.add(l10n.studyPlannerReasonNeutralFallback);
          break;
      }
    }
    return results;
  }
}
