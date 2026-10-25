import 'activity_entry.dart';

/// Reason why an activity is suggested by the API.
enum ActivitySuggestionReason {
  favorite('FAVORITE'),
  newForYou('NEW_FOR_YOU'),
  quick('QUICK'),
  other('OTHER');

  const ActivitySuggestionReason(this.apiCode);

  final String apiCode;

  static ActivitySuggestionReason fromCode(String? code) {
    if (code == null) return ActivitySuggestionReason.other;
    final upper = code.trim().toUpperCase();
    for (final reason in ActivitySuggestionReason.values) {
      if (reason.apiCode == upper) {
        return reason;
      }
    }
    return ActivitySuggestionReason.other;
  }
}

/// Represents an activity suggested for a user's comfort or study need.
class ActivitySuggestion {
  final ActivityEntry activity;
  final String reasonCode;
  final ActivitySuggestionReason reason;

  const ActivitySuggestion({
    required this.activity,
    required this.reasonCode,
    required this.reason,
  });

  factory ActivitySuggestion.fromJson(Map<String, dynamic> json) {
    final activityJson = (json['activity'] as Map<String, dynamic>?) ?? json;
    final code =
        json['reason_code'] as String? ?? json['reason'] as String? ?? 'OTHER';
    return ActivitySuggestion(
      activity: ActivityEntry.fromJson(activityJson),
      reasonCode: code,
      reason: ActivitySuggestionReason.fromCode(code),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activity': activity.toJson(),
      'reason_code': reasonCode,
    };
  }
}
