/// Planning mode indicating whether personal check-in history was used.
enum StudyPlanMode {
  defaultMode('default'),
  personalized('personalized');

  const StudyPlanMode(this.apiValue);
  final String apiValue;

  static StudyPlanMode fromString(String value) {
    if (value.toLowerCase() == 'personalized') {
      return StudyPlanMode.personalized;
    }
    return StudyPlanMode.defaultMode;
  }
}
