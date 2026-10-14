/// The 5 supported mood categories for check-ins in BloomWell.
///
/// Designed with non-diagnostic and educational principles.
enum MoodKind {
  happy,
  calm,
  okay,
  sad,
  stressed;

  /// Returns true if this mood benefits from showing additional gentle support
  /// shortcuts (Comfort Mode and HelpHub).
  bool get needsSupportOptions =>
      this == MoodKind.sad || this == MoodKind.stressed;
}
