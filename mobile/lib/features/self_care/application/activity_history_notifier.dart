import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_exceptions.dart';
import '../../auth/application/auth_notifier.dart';
import '../../auth/domain/entities/auth_state.dart';
import '../domain/entities/activity_completion_log.dart';
import 'self_care_notifier.dart';

/// State for the user's completed activity history.
class ActivityHistoryState {
  final List<ActivityCompletionLog> history;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final String? cursor;
  final bool hasMore;

  const ActivityHistoryState({
    this.history = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.cursor,
    this.hasMore = false,
  });

  ActivityHistoryState copyWith({
    List<ActivityCompletionLog>? history,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? cursor,
    bool clearCursor = false,
    bool? hasMore,
  }) {
    return ActivityHistoryState(
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      cursor: clearCursor ? null : (cursor ?? this.cursor),
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

/// Riverpod Notifier for managing completed activity history.
/// All completed logs are kept in-memory and wiped immediately upon session expiry.
class ActivityHistoryNotifier extends Notifier<ActivityHistoryState> {
  @override
  ActivityHistoryState build() {
    // Privacy boundary: wipe activity history immediately on logout/session expiry
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (!next.isAuthenticated) {
        clearAllUserData();
      }
    });

    return const ActivityHistoryState();
  }

  Future<void> loadInitial() async {
    final repo = ref.read(selfCareRepositoryProvider);
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final result = await repo.getActivityHistory(limit: 20);
      state = state.copyWith(
        history: result.items,
        cursor: result.nextCursor,
        hasMore: result.hasMore,
        isLoading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load activity history.',
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;
    final repo = ref.read(selfCareRepositoryProvider);
    state = state.copyWith(isLoadingMore: true);
    try {
      final result = await repo.getActivityHistory(
        cursor: state.cursor,
        limit: 20,
      );
      state = state.copyWith(
        history: [...state.history, ...result.items],
        cursor: result.nextCursor,
        hasMore: result.hasMore,
        isLoadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void clearAllUserData() {
    state = const ActivityHistoryState();
  }
}

/// Provider for ActivityHistoryNotifier.
final activityHistoryNotifierProvider =
    NotifierProvider<ActivityHistoryNotifier, ActivityHistoryState>(
  ActivityHistoryNotifier.new,
);
