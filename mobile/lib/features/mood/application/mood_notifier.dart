import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/mood_kind.dart';

/// Modern Riverpod Notifier managing session-only mood selection.
///
/// In alignment with project rules, mood records are never persisted to disk
/// or cached unencrypted on the device in v1.
class MoodNotifier extends Notifier<MoodKind?> {
  @override
  MoodKind? build() {
    return null; // Initial unselected session state
  }

  void selectMood(MoodKind? mood) {
    if (state == mood) {
      state = null; // Toggle off on re-tap
    } else {
      state = mood;
    }
  }

  void clearMood() {
    state = null;
  }
}

/// Provider exposing the active session mood state and controller.
final moodNotifierProvider =
    NotifierProvider<MoodNotifier, MoodKind?>(MoodNotifier.new);
