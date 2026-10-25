/// The 4 gentle support options available in Comfort Mode.
enum ComfortNeed {
  quickBreak('quick_break'),
  calmDown('calm'),
  bodyComfort('body_comfort'),
  focus('focus');

  const ComfortNeed(this.apiValue);

  final String apiValue;

  static ComfortNeed fromString(String? val) {
    if (val == null) return ComfortNeed.calmDown;
    final normalized = val.trim().toLowerCase();
    for (final need in ComfortNeed.values) {
      if (need.apiValue == normalized ||
          need.name.toLowerCase() == normalized) {
        return need;
      }
    }
    return ComfortNeed.calmDown;
  }
}
