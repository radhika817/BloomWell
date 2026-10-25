/// Types of academic events and deadlines entered by students.
enum AcademicEventType {
  exam('exam'),
  assignment('assignment'),
  presentation('presentation'),
  other('other');

  const AcademicEventType(this.apiValue);

  final String apiValue;

  static AcademicEventType fromString(String? val) {
    if (val == null) return AcademicEventType.exam;
    final normalized = val.trim().toLowerCase();
    for (final type in AcademicEventType.values) {
      if (type.apiValue == normalized ||
          type.name.toLowerCase() == normalized) {
        return type;
      }
    }
    return AcademicEventType.other;
  }
}
