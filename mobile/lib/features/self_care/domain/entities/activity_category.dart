/// Categories for curated wellness activities in the Self-Care Studio.
enum ActivityCategory {
  breathing('breathing'),
  grounding('grounding'),
  relaxation('relaxation'),
  movement('movement'),
  journaling('journaling'),
  studyBreak('study_break'),
  comfort('comfort'),
  confidence('confidence');

  const ActivityCategory(this.apiValue);

  final String apiValue;

  static ActivityCategory fromString(String? value) {
    if (value == null) return ActivityCategory.relaxation;
    final normalized = value.trim().toLowerCase();
    for (final cat in ActivityCategory.values) {
      if (cat.apiValue == normalized || cat.name.toLowerCase() == normalized) {
        return cat;
      }
    }
    return ActivityCategory.relaxation;
  }
}
