import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_exceptions.dart';
import '../../auth/application/auth_notifier.dart';
import '../../auth/domain/entities/auth_state.dart';
import '../data/academic_events_repository.dart';
import '../domain/entities/academic_event.dart';
import '../domain/entities/academic_event_type.dart';

/// State for entered academic events and deadlines.
class AcademicEventsState {
  final List<AcademicEvent> events;
  final bool showPast;
  final bool isLoading;
  final bool isActionLoading;
  final String? cursor;
  final bool hasMore;
  final String? errorMessage;

  const AcademicEventsState({
    this.events = const [],
    this.showPast = false,
    this.isLoading = false,
    this.isActionLoading = false,
    this.cursor,
    this.hasMore = false,
    this.errorMessage,
  });

  /// Filtered list based on showPast toggle.
  /// If showPast is false, shows upcoming events (today or future) sorted ascending by date.
  /// If showPast is true, shows past events sorted descending by date.
  List<AcademicEvent> get visibleEvents {
    if (showPast) {
      final past = events.where((e) => e.isPast).toList();
      past.sort((a, b) => b.eventDate.compareTo(a.eventDate));
      return past;
    } else {
      final upcoming = events.where((e) => !e.isPast).toList();
      upcoming.sort((a, b) => a.eventDate.compareTo(b.eventDate));
      return upcoming;
    }
  }

  AcademicEventsState copyWith({
    List<AcademicEvent>? events,
    bool? showPast,
    bool? isLoading,
    bool? isActionLoading,
    String? cursor,
    bool clearCursor = false,
    bool? hasMore,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return AcademicEventsState(
      events: events ?? this.events,
      showPast: showPast ?? this.showPast,
      isLoading: isLoading ?? this.isLoading,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      cursor: clearCursor ? null : (cursor ?? this.cursor),
      hasMore: hasMore ?? this.hasMore,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Provider for IAcademicEventsRepository.
final academicEventsRepositoryProvider =
    Provider<IAcademicEventsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AcademicEventsRepository(apiClient: apiClient);
});

/// Riverpod Notifier for managing academic events and deadlines.
class AcademicEventsNotifier extends Notifier<AcademicEventsState> {
  late IAcademicEventsRepository _repository;

  @override
  AcademicEventsState build() {
    _repository = ref.watch(academicEventsRepositoryProvider);

    // Privacy boundary: wipe events immediately upon session expiry/logout
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (!next.isAuthenticated) {
        clearAllUserData();
      }
    });

    return const AcademicEventsState();
  }

  /// Loads academic events.
  Future<void> loadEvents({bool refresh = false}) async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final result = await _repository.getEvents(limit: 50);
      state = state.copyWith(
        events: result.items,
        cursor: result.nextCursor,
        hasMore: result.hasMore,
        isLoading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load exams and deadlines.',
      );
    }
  }

  /// Toggles between upcoming and past events view.
  void togglePastView() {
    state = state.copyWith(showPast: !state.showPast);
  }

  /// Creates an academic event with client_id idempotency.
  Future<bool> createEvent({
    required String clientId,
    required String title,
    required DateTime eventDate,
    required AcademicEventType eventType,
  }) async {
    if (title.trim().isEmpty) {
      state =
          state.copyWith(errorMessage: 'Please enter a title for the event.');
      return false;
    }
    if (title.trim().length > 80) {
      state =
          state.copyWith(errorMessage: 'Title must be 80 characters or less.');
      return false;
    }

    state = state.copyWith(isActionLoading: true, clearErrorMessage: true);
    try {
      final created = await _repository.createEvent(
        clientId: clientId,
        title: title,
        eventDate: eventDate,
        eventType: eventType,
      );

      state = state.copyWith(
        events: [...state.events, created],
        isActionLoading: false,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isActionLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: 'Failed to save event. Please try again.',
      );
      return false;
    }
  }

  /// Updates an academic event.
  Future<bool> updateEvent({
    required String id,
    String? title,
    DateTime? eventDate,
    AcademicEventType? eventType,
  }) async {
    if (title != null && title.trim().length > 80) {
      state =
          state.copyWith(errorMessage: 'Title must be 80 characters or less.');
      return false;
    }

    state = state.copyWith(isActionLoading: true, clearErrorMessage: true);
    try {
      final updated = await _repository.updateEvent(
        id: id,
        title: title,
        eventDate: eventDate,
        eventType: eventType,
      );

      final nextEvents = state.events.map((e) {
        return e.id == id ? updated : e;
      }).toList();

      state = state.copyWith(
        events: nextEvents,
        isActionLoading: false,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isActionLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: 'Failed to update event.',
      );
      return false;
    }
  }

  /// Deletes an academic event after user confirmation.
  Future<bool> deleteEvent(String id) async {
    state = state.copyWith(isActionLoading: true, clearErrorMessage: true);
    try {
      await _repository.deleteEvent(id);
      state = state.copyWith(
        events: state.events.where((e) => e.id != id).toList(),
        isActionLoading: false,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isActionLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: 'Failed to delete event.',
      );
      return false;
    }
  }

  void clearAllUserData() {
    state = const AcademicEventsState();
  }
}

/// Provider for AcademicEventsNotifier.
final academicEventsNotifierProvider =
    NotifierProvider<AcademicEventsNotifier, AcademicEventsState>(
  AcademicEventsNotifier.new,
);
